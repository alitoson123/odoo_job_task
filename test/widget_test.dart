import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_task/core/services/service_locator.dart';
import 'package:job_task/features/auth/presentation/view_model/auth_cubit.dart';
import 'package:job_task/main.dart';

void main() {
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await sl.reset();
    await initDependencies();
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets('App smoke test initializes and displays Login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const OdooSalesApp());
    await tester.pumpAndSettle();

    expect(find.text('Odoo Sales Portal'), findsOneWidget);
    expect(find.byKey(const Key('username_field')), findsOneWidget);
    expect(find.byKey(const Key('api_key_field')), findsOneWidget);
  });

  testWidgets(
    'App auto-navigates to Customers view when credentials exist in storage',
    (WidgetTester tester) async {
      FlutterSecureStorage.setMockInitialValues({
        'auth_username': 'sales_rep',
        'auth_api_key': 'secret_key_123',
        'auth_user_id': '10',
      });
      await sl<AuthCubit>().checkAuth();

      await tester.pumpWidget(const OdooSalesApp());
      await tester.pumpAndSettle();

      expect(find.text('Customers'), findsOneWidget);
    },
  );
}
