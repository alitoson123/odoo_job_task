import 'package:flutter_test/flutter_test.dart';
import 'package:job_task/features/orders/data/models/sale_order_details_model.dart';

void main() {
  group('SaleOrderLineModel', () {
    test('fromJson parses line properly', () {
      final json = {
        'id': 101,
        'product_id': [55, 'Acoustic Bloc Screens'],
        'name': 'Acoustic Bloc Screens - Blue',
        'product_uom_qty': 4.0,
        'price_unit': 295.0,
        'price_subtotal': 1180.0,
      };

      final line = SaleOrderDetailsModel.fromJson(json);

      expect(line.id, equals(101));
      expect(line.productId, equals(55));
      expect(line.productName, equals('Acoustic Bloc Screens'));
      expect(line.name, equals('Acoustic Bloc Screens - Blue'));
      expect(line.productUomQty, equals(4.0));
      expect(line.priceUnit, equals(295.0));
      expect(line.priceSubtotal, equals(1180.0));
    });

    test('fromJson handles false values gracefully', () {
      final json = {
        'id': 102,
        'product_id': false,
        'name': false,
        'product_uom_qty': false,
        'price_unit': false,
        'price_subtotal': false,
      };

      final line = SaleOrderDetailsModel.fromJson(json);

      expect(line.id, equals(102));
      expect(line.productId, equals(0));
      expect(line.productName, equals('Product'));
      expect(line.name, equals('Product Item'));
      expect(line.productUomQty, equals(0.0));
      expect(line.priceUnit, equals(0.0));
      expect(line.priceSubtotal, equals(0.0));
    });
  });
}
