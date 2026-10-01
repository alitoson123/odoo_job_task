import 'package:flutter_test/flutter_test.dart';
import 'package:job_task/features/customers/data/models/customer_model.dart';

void main() {
  group('CustomerModel', () {
    test('fromJson parses full Odoo response properly', () {
      final json = {
        'id': 10,
        'name': 'Agrolait',
        'phone': '+32 81 81 37 00',
        'email': 'info@agrolait.com',
        'street': '69 rue de Namur',
        'street2': false,
        'city': 'Wavre',
        'zip': '1300',
        'country_id': [21, 'Belgium'],
      };

      final customer = CustomerModel.fromJson(json);

      expect(customer.id, equals(10));
      expect(customer.name, equals('Agrolait'));
      expect(customer.phone, equals('+32 81 81 37 00'));
      expect(customer.email, equals('info@agrolait.com'));
      expect(customer.street, equals('69 rue de Namur'));
      expect(customer.street2, isNull);
      expect(customer.city, equals('Wavre'));
      expect(customer.zip, equals('1300'));
      expect(customer.countryName, equals('Belgium'));
      expect(
        customer.displayAddress,
        equals('69 rue de Namur, Wavre, 1300, Belgium'),
      );
    });

    test('fromJson handles false values as null', () {
      final json = {
        'id': 12,
        'name': 'ASUSTeK',
        'phone': false,
        'email': false,
        'street': false,
        'street2': false,
        'city': false,
        'zip': false,
        'country_id': false,
      };

      final customer = CustomerModel.fromJson(json);

      expect(customer.id, equals(12));
      expect(customer.phone, isNull);
      expect(customer.email, isNull);
      expect(customer.displayAddress, equals('No address provided'));
    });

    test('copyWith updates phone number', () {
      const customer = CustomerModel(id: 1, name: 'Test', phone: '123');
      final updated = customer.copyWith(phone: '456');

      expect(updated.id, equals(1));
      expect(updated.phone, equals('456'));
      expect(updated.name, equals('Test'));
    });
  });
}
