import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:job_task/features/customers/data/datasources/customer_local_data_source.dart';
import 'package:job_task/features/customers/data/models/customer_model.dart';

void main() {
  late Directory tempDir;
  late Box customersBox;
  late Box pendingOpsBox;
  late CustomerLocalDataSource dataSource;

  setUpAll(() {
    tempDir = Directory.systemTemp.createTempSync('customer_local_test');
    Hive.init(tempDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  setUp(() async {
    final stamp = DateTime.now().microsecondsSinceEpoch;
    customersBox = await Hive.openBox('customers_$stamp');
    pendingOpsBox = await Hive.openBox('pending_$stamp');
    dataSource = CustomerLocalDataSource(
      customersBox: customersBox,
      pendingOpsBox: pendingOpsBox,
    );
  });

  tearDown(() async {
    await customersBox.deleteFromDisk();
    await pendingOpsBox.deleteFromDisk();
  });

  group('CustomerLocalDataSource', () {
    test('cacheCustomers saves and getCachedCustomers retrieves customers', () async {
      const customers = [
        CustomerModel(id: 1, name: 'Alice', phone: '111', city: 'Cairo'),
        CustomerModel(id: 2, name: 'Bob', phone: '222', city: 'Alex'),
      ];

      await dataSource.cacheCustomers(customers);

      final cached = dataSource.getCachedCustomers();
      expect(cached.length, equals(2));
      expect(cached[0].name, equals('Alice'));
      expect(cached[1].name, equals('Bob'));
    });

    test('getCachedCustomers filters by search query case-insensitively', () async {
      const customers = [
        CustomerModel(id: 1, name: 'Delta Corp'),
        CustomerModel(id: 2, name: 'Alpha Tech'),
      ];

      await dataSource.cacheCustomers(customers);

      final result = dataSource.getCachedCustomers(searchQuery: 'alpha');
      expect(result.length, equals(1));
      expect(result.first.name, equals('Alpha Tech'));
    });

    test('updateCustomerPhoneLocally and addPendingOperation manage queue', () async {
      const customer = CustomerModel(id: 10, name: 'Charlie', phone: '123');
      await dataSource.cacheCustomerDetails(customer);

      await dataSource.updateCustomerPhoneLocally(customerId: 10, newPhone: '999');
      await dataSource.addPendingOperation(
        partnerId: 10,
        field: 'phone',
        value: '999',
      );

      final updated = dataSource.getCachedCustomer(10);
      expect(updated?.phone, equals('999'));
      expect(updated?.isPendingSync, isTrue);

      final ops = dataSource.getPendingOperations();
      expect(ops.length, equals(1));
      expect(ops.first.partnerId, equals(10));
      expect(ops.first.value, equals('999'));

      await dataSource.removePendingOperation(ops.first.key);
      expect(dataSource.getPendingOperations().isEmpty, isTrue);
    });
  });
}
