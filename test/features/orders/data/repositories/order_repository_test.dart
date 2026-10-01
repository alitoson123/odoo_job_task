import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_task/core/services/odoo_client.dart';
import 'package:job_task/features/orders/data/repositories/order_repository.dart';

class FakeOdooClientForOrder extends Fake implements OdooClient {
  dynamic responseToReturn;
  Exception? exceptionToThrow;
  Map<String, dynamic>? lastBodyPassed;
  String? lastModelPassed;
  String? lastMethodPassed;

  @override
  Future<dynamic> callRpc({
    required String model,
    required String method,
    required Map<String, dynamic> body,
    String? apiKey,
  }) async {
    lastModelPassed = model;
    lastMethodPassed = method;
    lastBodyPassed = body;
    if (exceptionToThrow != null) {
      throw exceptionToThrow!;
    }
    return responseToReturn;
  }
}

void main() {
  late FakeOdooClientForOrder fakeClient;
  late OrderRepository repository;

  setUp(() {
    fakeClient = FakeOdooClientForOrder();
    repository = OrderRepository(odooClient: fakeClient);
  });

  group('OrderRepository', () {
    test('getOrders returns list of SaleOrderModel on success', () async {
      fakeClient.responseToReturn = [
        {
          'id': 1,
          'name': 'S00001',
          'partner_id': [10, 'Agrolait'],
          'date_order': '2026-03-01 10:00:00',
          'state': 'draft',
        },
      ];

      final result = await repository.getOrders();

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Expected Right'),
        (orders) {
          expect(orders.length, equals(1));
          expect(orders.first.name, equals('S00001'));
          expect(orders.first.partnerName, equals('Agrolait'));
        },
      );
      expect(fakeClient.lastModelPassed, equals('sale.order'));
      expect(fakeClient.lastMethodPassed, equals('search_read'));
    });

    test('getOrderDetails parses order header and lines', () async {
      fakeClient.responseToReturn = [
        {
          'id': 1,
          'name': 'S00001',
          'partner_id': [10, 'Agrolait'],
          'date_order': '2026-03-01 10:00:00',
          'state': 'draft',
          'order_line': [],
          'amount_untaxed': 100.0,
          'amount_tax': 10.0,
          'amount_total': 110.0,
        },
      ];

      final result = await repository.getOrderDetails(1);

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Expected Right'),
        (data) {
          expect(data.order.id, equals(1));
          expect(data.order.amountTotal, equals(110.0));
          expect(data.lines, isEmpty);
        },
      );
    });

    test('confirmOrder calls action_confirm and returns Right(true)', () async {
      fakeClient.responseToReturn = true;

      final result = await repository.confirmOrder(1);

      expect(result.isRight(), isTrue);
      expect(fakeClient.lastModelPassed, equals('sale.order'));
      expect(fakeClient.lastMethodPassed, equals('action_confirm'));
      expect(fakeClient.lastBodyPassed, equals({'ids': [1]}));
    });

    test('returns Left(ServerFailure) on DioException', () async {
      fakeClient.exceptionToThrow = DioException(
        requestOptions: RequestOptions(path: '/json/2/sale.order/search_read'),
        type: DioExceptionType.connectionTimeout,
      );

      final result = await repository.getOrders();

      expect(result.isLeft(), isTrue);
    });

    test('checkIsInternalUser calls res.users/has_group with exact params', () async {
      fakeClient.responseToReturn = true;

      final result = await repository.checkIsInternalUser(2);

      expect(result.isRight(), isTrue);
      expect(result.getOrElse(() => false), isTrue);
      expect(fakeClient.lastModelPassed, equals('res.users'));
      expect(fakeClient.lastMethodPassed, equals('has_group'));
      expect(
        fakeClient.lastBodyPassed,
        equals({'ids': [2], 'group_ext_id': 'base.group_user'}),
      );
    });

    test('checkIsInternalUser returns Left(Failure) on error or non-bool', () async {
      fakeClient.exceptionToThrow = DioException(
        requestOptions: RequestOptions(path: '/json/2/res.users/has_group'),
        type: DioExceptionType.badResponse,
      );

      final result = await repository.checkIsInternalUser(2);

      expect(result.isLeft(), isTrue);
    });
  });
}
