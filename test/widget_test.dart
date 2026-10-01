import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_task/core/services/service_locator.dart';
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
}
