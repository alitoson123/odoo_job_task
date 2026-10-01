import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:job_task/features/orders/data/datasources/order_local_data_source.dart';
import 'package:job_task/features/orders/data/models/sale_order_details_model.dart';
import 'package:job_task/features/orders/data/models/sale_order_model.dart';

void main() {
  late Directory tempDir;
  late Box ordersBox;
  late OrderLocalDataSource dataSource;

  setUpAll(() {
    tempDir = Directory.systemTemp.createTempSync('order_local_test');
    Hive.init(tempDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  setUp(() async {
    final stamp = DateTime.now().microsecondsSinceEpoch;
    ordersBox = await Hive.openBox('orders_$stamp');
    dataSource = OrderLocalDataSource(ordersBox);
  });

  tearDown(() async {
    await ordersBox.deleteFromDisk();
  });

  group('OrderLocalDataSource', () {
    test('cacheOrders saves and getCachedOrders returns orders sorted by date', () async {
      const o1 = SaleOrderModel(
        id: 1,
        name: 'S00001',
        partnerId: 1,
        partnerName: 'Alice',
        dateOrder: '2026-01-01',
        state: 'draft',
      );
      const o2 = SaleOrderModel(
        id: 2,
        name: 'S00002',
        partnerId: 2,
        partnerName: 'Bob',
        dateOrder: '2026-02-01',
        state: 'sale',
      );

      await dataSource.cacheOrders([o1, o2]);

      final cached = dataSource.getCachedOrders();
      expect(cached.length, equals(2));
      expect(cached[0].id, equals(2)); // newer date first
      expect(cached[1].id, equals(1));
    });

    test('cacheOrderDetails and getCachedOrderDetails round-trip header and lines', () async {
      const order = SaleOrderModel(
        id: 10,
        name: 'S00010',
        partnerId: 3,
        partnerName: 'Charlie',
        state: 'draft',
      );
      const lines = [
        SaleOrderDetailsModel(
          id: 1,
          productId: 101,
          productName: 'Desk',
          name: 'Office Desk',
          productUomQty: 2.0,
          priceUnit: 150.0,
          priceSubtotal: 300.0,
        ),
      ];

      await dataSource.cacheOrderDetails(order, lines);

      final result = dataSource.getCachedOrderDetails(10);
      expect(result, isNotNull);
      expect(result?.order.name, equals('S00010'));
      expect(result?.lines.length, equals(1));
      expect(result?.lines.first.productName, equals('Desk'));
    });

    test('cacheIsInternalUser and getCachedIsInternalUser round-trip correctly', () async {
      expect(dataSource.getCachedIsInternalUser(5), isNull);
      await dataSource.cacheIsInternalUser(5, true);
      expect(dataSource.getCachedIsInternalUser(5), isTrue);
    });
  });
}
