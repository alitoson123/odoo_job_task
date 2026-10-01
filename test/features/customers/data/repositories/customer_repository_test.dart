import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_task/core/services/odoo_client.dart';
import 'package:job_task/features/customers/data/repositories/customer_repository.dart';

class FakeOdooClientForCustomer extends Fake implements OdooClient {
  dynamic responseToReturn;
  Exception? exceptionToThrow;
  Map<String, dynamic>? lastBodyPassed;

  @override
  Future<dynamic> callRpc({
    required String model,
    required String method,
    required Map<String, dynamic> body,
    String? apiKey,
  }) async {
    lastBodyPassed = body;
    if (exceptionToThrow != null) {
      throw exceptionToThrow!;
    }
    return responseToReturn;
  }
}

void main() {
  late FakeOdooClientForCustomer fakeClient;
  late CustomerRepository repository;

  setUp(() {
    fakeClient = FakeOdooClientForCustomer();
    repository = CustomerRepository(odooClient: fakeClient);
  });

  group('CustomerRepository', () {
    test('getCustomers returns list of customers on success', () async {
      fakeClient.responseToReturn = [
        {'id': 1, 'name': 'Acme Inc', 'phone': '12345', 'city': 'Austin'},
      ];

      final result = await repository.getCustomers();

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Expected Right'),
        (customers) {
          expect(customers.length, equals(1));
          expect(customers.first.name, equals('Acme Inc'));
        },
      );
    });

    test('getCustomers appends ilike domain when searching', () async {
      fakeClient.responseToReturn = [];

      await repository.getCustomers(searchQuery: 'Acme');

      final domain = fakeClient.lastBodyPassed?['domain'] as List;
      expect(domain.length, equals(2));
      expect(domain[1], equals(['name', 'ilike', 'Acme']));
    });

    test('getCustomerDetails parses single partner record', () async {
      fakeClient.responseToReturn = [
        {
          'id': 5,
          'name': 'Deco Addict',
          'phone': '555-1234',
          'email': 'deco@test.com',
          'street': '77 Warm St',
          'city': 'Dallas',
          'country_id': [1, 'USA'],
        }
      ];

      final result = await repository.getCustomerDetails(5);

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Expected Right'),
        (customer) {
          expect(customer.id, equals(5));
          expect(customer.email, equals('deco@test.com'));
          expect(customer.countryName, equals('USA'));
        },
      );
    });

    test('updateCustomerPhone returns Right(true) on success', () async {
      fakeClient.responseToReturn = true;

      final result = await repository.updateCustomerPhone(
        customerId: 5,
        newPhone: '+1 555 9999',
      );

      expect(result.isRight(), isTrue);
      expect(
        fakeClient.lastBodyPassed?['vals'],
        equals({'phone': '+1 555 9999'}),
      );
    });

    test('returns Left(ServerFailure) on DioException', () async {
      fakeClient.exceptionToThrow = DioException(
        requestOptions: RequestOptions(path: '/json/2/res.partner/search_read'),
        type: DioExceptionType.connectionTimeout,
      );

      final result = await repository.getCustomers();

      expect(result.isLeft(), isTrue);
    });
  });
}
