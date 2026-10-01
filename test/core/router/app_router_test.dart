import 'package:flutter_test/flutter_test.dart';
import 'package:job_task/core/router/app_router.dart';

void main() {
  group('AppRouter', () {
    test('defines correct static paths', () {
      expect(AppRouter.login, equals('/'));
      expect(AppRouter.home, equals('/home'));
    });

    test('router has defined routes', () {
      expect(AppRouter.router.configuration.routes.length, equals(2));
    });
  });
}
