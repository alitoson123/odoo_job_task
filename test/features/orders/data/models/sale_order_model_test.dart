import 'package:flutter_test/flutter_test.dart';
import 'package:job_task/features/orders/data/models/sale_order_model.dart';

void main() {
  group('SaleOrderModel', () {
    test('fromJson parses full Odoo response properly', () {
      final json = {
        'id': 20,
        'name': 'S00002',
        'partner_id': [14, 'Deco Addict'],
        'date_order': '2026-03-01 10:20:00',
        'state': 'draft',
        'order_line': [101, 102],
        'amount_untaxed': 450.0,
        'amount_tax': 45.0,
        'amount_total': 495.0,
      };

      final order = SaleOrderModel.fromJson(json);

      expect(order.id, equals(20));
      expect(order.name, equals('S00002'));
      expect(order.partnerId, equals(14));
      expect(order.partnerName, equals('Deco Addict'));
      expect(order.dateOrder, equals('2026-03-01 10:20:00'));
      expect(order.state, equals('draft'));
      expect(order.orderLineIds, equals([101, 102]));
      expect(order.amountUntaxed, equals(450.0));
      expect(order.amountTax, equals(45.0));
      expect(order.amountTotal, equals(495.0));
      expect(order.isConfirmable, isTrue);
      expect(order.statusLabel, equals('Quotation'));
    });

    test('isConfirmable is true for draft and sent states', () {
      const draftOrder = SaleOrderModel(
        id: 1,
        name: 'S1',
        partnerId: 1,
        partnerName: 'Partner',
        state: 'draft',
      );
      const sentOrder = SaleOrderModel(
        id: 2,
        name: 'S2',
        partnerId: 1,
        partnerName: 'Partner',
        state: 'sent',
      );
      const saleOrder = SaleOrderModel(
        id: 3,
        name: 'S3',
        partnerId: 1,
        partnerName: 'Partner',
        state: 'sale',
      );

      expect(draftOrder.isConfirmable, isTrue);
      expect(sentOrder.isConfirmable, isTrue);
      expect(saleOrder.isConfirmable, isFalse);
    });

    test('statusLabel maps states to human-readable strings', () {
      const draft = SaleOrderModel(
        id: 1,
        name: 'S1',
        partnerId: 1,
        partnerName: 'P',
        state: 'draft',
      );
      const sent = SaleOrderModel(
        id: 2,
        name: 'S2',
        partnerId: 1,
        partnerName: 'P',
        state: 'sent',
      );
      const sale = SaleOrderModel(
        id: 3,
        name: 'S3',
        partnerId: 1,
        partnerName: 'P',
        state: 'sale',
      );
      const done = SaleOrderModel(
        id: 4,
        name: 'S4',
        partnerId: 1,
        partnerName: 'P',
        state: 'done',
      );
      const cancel = SaleOrderModel(
        id: 5,
        name: 'S5',
        partnerId: 1,
        partnerName: 'P',
        state: 'cancel',
      );

      expect(draft.statusLabel, equals('Quotation'));
      expect(sent.statusLabel, equals('Quotation Sent'));
      expect(sale.statusLabel, equals('Confirmed'));
      expect(done.statusLabel, equals('Locked'));
      expect(cancel.statusLabel, equals('Cancelled'));
    });

    test('handles false values gracefully', () {
      final json = {
        'id': 5,
        'name': false,
        'partner_id': false,
        'date_order': false,
        'state': false,
        'order_line': false,
        'amount_untaxed': false,
        'amount_tax': false,
        'amount_total': false,
      };

      final order = SaleOrderModel.fromJson(json);

      expect(order.id, equals(5));
      expect(order.name, equals('Unnamed Order'));
      expect(order.partnerId, equals(0));
      expect(order.partnerName, equals('Unknown Partner'));
      expect(order.dateOrder, isNull);
      expect(order.state, equals('draft'));
      expect(order.orderLineIds, isEmpty);
      expect(order.amountTotal, equals(0.0));
    });
  });
}
