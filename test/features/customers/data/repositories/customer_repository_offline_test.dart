import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:job_task/core/services/network_info.dart';
import 'package:job_task/core/services/odoo_client.dart';
import 'package:job_task/features/customers/data/datasources/customer_local_data_source.dart';
import 'package:job_task/features/customers/data/models/customer_model.dart';
import 'package:job_task/features/customers/data/repositories/customer_repository.dart';

class FakeNetworkInfoOffline extends Fake implements NetworkInfo {
  bool connected = false;

  @override
  Future<bool> get isConnected async => connected;

  @override
  Stream<bool> get onConnectivityChanged => Stream.value(connected);
}

class FakeOdooClientOffline extends Fake implements OdooClient {
  @override
  Future<dynamic> callRpc({
    required String model,
    required String method,
    required Map<String, dynamic> body,
    String? apiKey,
  }) async {
    throw DioException(
      requestOptions: RequestOptions(),
      type: DioExceptionType.connectionError,
    );
  }
}

void main() {
  late Directory tempDir;
  late Box customersBox;
  late Box pendingOpsBox;
  late CustomerLocalDataSource localDataSource;
  late FakeNetworkInfoOffline fakeNetworkInfo;
  late FakeOdooClientOffline fakeOdooClient;
  late CustomerRepository repository;

  setUpAll(() {
    tempDir = Directory.systemTemp.createTempSync('repo_offline_test');
    Hive.init(tempDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  setUp(() async {
    final stamp = DateTime.now().microsecondsSinceEpoch;
    customersBox = await Hive.openBox('c_$stamp');
    pendingOpsBox = await Hive.openBox('p_$stamp');
    localDataSource = CustomerLocalDataSource(
      customersBox: customersBox,
      pendingOpsBox: pendingOpsBox,
    );
    fakeNetworkInfo = FakeNetworkInfoOffline();
    fakeOdooClient = FakeOdooClientOffline();
    repository = CustomerRepository(
      odooClient: fakeOdooClient,
      localDataSource: localDataSource,
      networkInfo: fakeNetworkInfo,
    );
  });

  tearDown(() async {
    await customersBox.deleteFromDisk();
    await pendingOpsBox.deleteFromDisk();
  });

  group('CustomerRepository Offline', () {
    test('getCustomers returns cached customers when offline', () async {
      await localDataSource.cacheCustomers([
        const CustomerModel(id: 1, name: 'Offline Customer', phone: '123'),
      ]);

      final result = await repository.getCustomers();

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Expected cached customers'),
        (customers) {
          expect(customers.length, equals(1));
          expect(customers.first.name, equals('Offline Customer'));
          expect(repository.isLastFetchOffline, isTrue);
        },
      );
    });

    test('getCustomerDetails returns cached details when offline', () async {
      await localDataSource.cacheCustomerDetails(
        const CustomerModel(id: 1, name: 'Offline Detail', email: 'off@test.com'),
      );

      final result = await repository.getCustomerDetails(1);

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Expected cached details'),
        (customer) {
          expect(customer.email, equals('off@test.com'));
          expect(repository.isLastFetchOffline, isTrue);
        },
      );
    });

    test('updateCustomerPhone saves locally and queues when offline', () async {
      final result = await repository.updateCustomerPhone(
        customerId: 7,
        newPhone: '555-OFFLINE',
      );

      expect(result.isRight(), isTrue);
      expect(result.getOrElse(() => true), isFalse); // false indicates queued offline

      final cached = localDataSource.getCachedCustomer(7);
      expect(cached?.phone, equals('555-OFFLINE'));
      expect(cached?.isPendingSync, isTrue);

      final ops = localDataSource.getPendingOperations();
      expect(ops.length, equals(1));
      expect(ops.first.partnerId, equals(7));
      expect(ops.first.value, equals('555-OFFLINE'));
    });
  });
}
