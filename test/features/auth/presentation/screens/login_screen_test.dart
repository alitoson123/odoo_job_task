import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_task/core/errors/failure.dart';
import 'package:job_task/features/auth/data/models/user_model.dart';
import 'package:job_task/features/auth/data/repositories/auth_repository.dart';
import 'package:job_task/features/auth/presentation/view_model/auth_cubit.dart';
import 'package:job_task/features/auth/presentation/view/login_view.dart';

class MockAuthRepoForScreen extends Fake implements AuthRepository {
  @override
  Future<Either<Failure, UserModel>> login({
    required String username,
    required String apiKey,
  }) async {
    return const Right(UserModel(id: 1, name: 'Admin', login: 'admin'));
  }

  @override
  Future<({String? username, String? apiKey, int? userId})> getSavedCredentials() async {
    return (username: null, apiKey: null, userId: null);
  }

  @override
  Future<void> logout() async {}
}

void main() {
  testWidgets('LoginScreen renders header and form properly', (tester) async {
    final mockRepo = MockAuthRepoForScreen();
    final cubit = AuthCubit(authRepository: mockRepo);

    await tester.pumpWidget(
      BlocProvider<AuthCubit>.value(
        value: cubit,
        child: const MaterialApp(home: LoginView()),
      ),
    );

    expect(find.text('Odoo Sales Portal'), findsOneWidget);
    expect(find.byKey(const Key('username_field')), findsOneWidget);
    expect(find.byKey(const Key('api_key_field')), findsOneWidget);
    expect(find.byKey(const Key('login_submit_button')), findsOneWidget);

    cubit.close();
  });
}
