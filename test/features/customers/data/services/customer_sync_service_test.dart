import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:job_task/core/services/network_info.dart';
import 'package:job_task/core/services/odoo_client.dart';
import 'package:job_task/features/customers/data/datasources/customer_local_data_source.dart';
import 'package:job_task/features/customers/data/services/customer_sync_service.dart';

class FakeNetworkInfo extends Fake implements NetworkInfo {
  bool connected = true;

  @override
  Future<bool> get isConnected async => connected;

  @override
  Stream<bool> get onConnectivityChanged => Stream.value(connected);
}

class FakeOdooClientForSync extends Fake implements OdooClient {
  final List<Map<String, dynamic>> writtenBodies = [];
  bool shouldThrowNetworkError = false;

  @override
  Future<dynamic> callRpc({
    required String model,
    required String method,
    required Map<String, dynamic> body,
    String? apiKey,
  }) async {
    if (shouldThrowNetworkError) {
      throw DioException(
        requestOptions: RequestOptions(),
        type: DioExceptionType.connectionError,
      );
    }
    writtenBodies.add(body);
    return true;
  }
}

void main() {
  late Directory tempDir;
  late Box customersBox;
  late Box pendingOpsBox;
  late CustomerLocalDataSource localDataSource;
  late FakeNetworkInfo fakeNetworkInfo;
  late FakeOdooClientForSync fakeOdooClient;
  late CustomerSyncService syncService;

  setUpAll(() {
    tempDir = Directory.systemTemp.createTempSync('sync_test');
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
    fakeNetworkInfo = FakeNetworkInfo();
    fakeOdooClient = FakeOdooClientForSync();
    syncService = CustomerSyncService(
      localDataSource: localDataSource,
      odooClient: fakeOdooClient,
      networkInfo: fakeNetworkInfo,
    );
  });

  tearDown(() async {
    syncService.dispose();
    await customersBox.deleteFromDisk();
    await pendingOpsBox.deleteFromDisk();
  });

  group('CustomerSyncService', () {
    test('syncPendingOperations executes operations in order and clears queue', () async {
      await localDataSource.addPendingOperation(partnerId: 10, field: 'phone', value: '111');
      await localDataSource.addPendingOperation(partnerId: 20, field: 'phone', value: '222');

      final synced = await syncService.syncPendingOperations();

      expect(synced, equals(2));
      expect(localDataSource.getPendingOperations().isEmpty, isTrue);
      expect(fakeOdooClient.writtenBodies.length, equals(2));
      expect(fakeOdooClient.writtenBodies[0]['ids'], equals([10]));
      expect(fakeOdooClient.writtenBodies[1]['ids'], equals([20]));
    });

    test('syncPendingOperations keeps operations in queue on network error', () async {
      await localDataSource.addPendingOperation(partnerId: 30, field: 'phone', value: '333');
      fakeOdooClient.shouldThrowNetworkError = true;

      final synced = await syncService.syncPendingOperations();

      expect(synced, equals(0));
      expect(localDataSource.getPendingOperations().length, equals(1));
    });

    test('syncPendingOperations does nothing when device is offline', () async {
      await localDataSource.addPendingOperation(partnerId: 40, field: 'phone', value: '444');
      fakeNetworkInfo.connected = false;

      final synced = await syncService.syncPendingOperations();

      expect(synced, equals(0));
      expect(localDataSource.getPendingOperations().length, equals(1));
      expect(fakeOdooClient.writtenBodies.isEmpty, isTrue);
    });
  });
}
