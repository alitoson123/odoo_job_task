import 'package:flutter_test/flutter_test.dart';
import 'package:job_task/features/auth/data/models/user_model.dart';

void main() {
  group('UserModel', () {
    test('fromJson correctly parses valid JSON map', () {
      final json = {
        'id': 2,
        'name': 'Mitchell Admin',
        'login': 'admin',
      };

      final user = UserModel.fromJson(json);

      expect(user.id, equals(2));
      expect(user.name, equals('Mitchell Admin'));
      expect(user.login, equals('admin'));
    });

    test('fromJson handles Odoo boolean false gracefully', () {
      final json = {
        'id': 5,
        'name': false,
        'login': 'sales_rep',
      };

      final user = UserModel.fromJson(json);

      expect(user.id, equals(5));
      expect(user.name, equals(''));
      expect(user.login, equals('sales_rep'));
    });

    test('toJson produces expected structure', () {
      const user = UserModel(id: 3, name: 'Marc Demo', login: 'demo');
      final json = user.toJson();

      expect(json, equals({'id': 3, 'name': 'Marc Demo', 'login': 'demo'}));
    });
  });
}
