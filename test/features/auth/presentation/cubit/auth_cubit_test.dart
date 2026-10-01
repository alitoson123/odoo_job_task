import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_task/core/errors/failure.dart';
import 'package:job_task/features/auth/data/models/user_model.dart';
import 'package:job_task/features/auth/data/repositories/auth_repository.dart';
import 'package:job_task/features/auth/presentation/view_model/auth_cubit.dart';
import 'package:job_task/features/auth/presentation/view_model/auth_state.dart';

class FakeAuthRepository extends Fake implements AuthRepository {
  Either<Failure, UserModel>? resultToReturn;
  ({String? username, String? apiKey}) savedCredentials = (
    username: null,
    apiKey: null,
  );
  bool logoutCalled = false;

  @override
  Future<Either<Failure, UserModel>> login({
    required String username,
    required String apiKey,
  }) async {
    return resultToReturn!;
  }

  @override
  Future<({String? username, String? apiKey})> getSavedCredentials() async {
    return savedCredentials;
  }

  @override
  Future<void> logout() async {
    logoutCalled = true;
    savedCredentials = (username: null, apiKey: null);
  }
}

void main() {
  late FakeAuthRepository fakeRepository;
  late AuthCubit authCubit;

  setUp(() {
    fakeRepository = FakeAuthRepository();
    authCubit = AuthCubit(authRepository: fakeRepository);
  });

  tearDown(() {
    authCubit.close();
  });

  group('AuthCubit', () {
    test('initial state is AuthInitial', () {
      expect(authCubit.state, equals(const AuthInitial()));
    });

    test(
      'emits [AuthLoading, AuthAuthenticated] on successful login',
      () async {
        const user = UserModel(id: 2, name: 'Admin', login: 'admin');
        fakeRepository.resultToReturn = const Right(user);

        final expectedStates = [
          const AuthLoading(),
          const AuthSuccess(user: user, apiKey: 'test_key'),
        ];

        expectLater(authCubit.stream, emitsInOrder(expectedStates));

        authCubit.login(username: 'admin', apiKey: 'test_key');
      },
    );

    test('emits [AuthLoading, AuthFailure] on failure', () async {
      fakeRepository.resultToReturn = const Left(
        ServerFailure('Invalid username or API key'),
      );

      final expectedStates = [
        const AuthLoading(),
        const AuthFailure(message: 'Invalid username or API key'),
      ];

      expectLater(authCubit.stream, emitsInOrder(expectedStates));

      authCubit.login(username: 'wrong', apiKey: 'wrong');
    });

    test('emits [AuthLoading, AuthAuthenticated] on auto-login', () async {
      fakeRepository.savedCredentials = (
        username: 'admin',
        apiKey: 'saved_key',
      );

      final expectedStates = [
        const AuthLoading(),
        const AuthSuccess(
          user: UserModel(id: 0, name: 'admin', login: 'admin'),
          apiKey: 'saved_key',
        ),
      ];

      expectLater(authCubit.stream, emitsInOrder(expectedStates));

      authCubit.checkAuth();
    });

    test(
      'emits [AuthLoading, AuthUnauthenticated] on auto-login empty',
      () async {
        fakeRepository.savedCredentials = (username: null, apiKey: null);

        final expectedStates = [const AuthLoading(), const AuthLoggedOut()];

        expectLater(authCubit.stream, emitsInOrder(expectedStates));

        authCubit.checkAuth();
      },
    );

    test('emits [AuthLoading, AuthUnauthenticated] on logout', () async {
      final expectedStates = [const AuthLoading(), const AuthLoggedOut()];

      expectLater(authCubit.stream, emitsInOrder(expectedStates));

      authCubit.logout();
    });
  });
}
