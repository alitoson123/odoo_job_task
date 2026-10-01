import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_task/features/auth/presentation/widgets/login_form.dart';

void main() {
  group('LoginForm Widget', () {
    testWidgets('shows validation errors when fields are empty', (tester) async {
      bool submitted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoginForm(
              isLoading: false,
              onSubmit: (_, _) => submitted = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('login_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Please enter your username'), findsOneWidget);
      expect(find.text('Please enter your password or API key'), findsOneWidget);
      expect(submitted, isFalse);
    });

    testWidgets('calls onSubmit when valid inputs are submitted', (tester) async {
      String? submittedUser;
      String? submittedKey;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoginForm(
              isLoading: false,
              onSubmit: (u, k) {
                submittedUser = u;
                submittedKey = k;
              },
            ),
          ),
        ),
      );

      await tester.enterText(find.byKey(const Key('username_field')), 'admin');
      await tester.enterText(find.byKey(const Key('api_key_field')), 'secret123');
      await tester.tap(find.byKey(const Key('login_submit_button')));
      await tester.pumpAndSettle();

      expect(submittedUser, equals('admin'));
      expect(submittedKey, equals('secret123'));
    });

    testWidgets('toggles obscureText when visibility icon is tapped', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoginForm(
              isLoading: false,
              onSubmit: (_, _) {},
            ),
          ),
        ),
      );

      final apiKeyTextFieldFinder = find.byKey(const Key('api_key_field'));
      EditableText editableText = tester.widget<EditableText>(
        find.descendant(
          of: apiKeyTextFieldFinder,
          matching: find.byType(EditableText),
        ),
      );
      expect(editableText.obscureText, isTrue);

      await tester.tap(find.byKey(const Key('toggle_visibility_button')));
      await tester.pumpAndSettle();

      editableText = tester.widget<EditableText>(
        find.descendant(
          of: apiKeyTextFieldFinder,
          matching: find.byType(EditableText),
        ),
      );
      expect(editableText.obscureText, isFalse);
    });
  });
}
