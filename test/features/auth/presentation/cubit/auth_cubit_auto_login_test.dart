import 'package:flutter_test/flutter_test.dart';
import 'package:job_task/features/auth/data/repositories/auth_repository.dart';
import 'package:job_task/features/auth/presentation/view_model/auth_cubit.dart';
import 'package:job_task/features/auth/presentation/view_model/auth_state.dart';

class MockAuthRepo extends Fake implements AuthRepository {
  ({String? username, String? apiKey, int? userId}) credentials = (
    username: null,
    apiKey: null,
    userId: null,
  );
  bool logoutCalled = false;

  @override
  Future<({String? username, String? apiKey, int? userId})> getSavedCredentials() async =>
      credentials;

  @override
  Future<void> logout() async {
    logoutCalled = true;
    credentials = (username: null, apiKey: null, userId: null);
  }
}

void main() {
  late MockAuthRepo mockRepo;
  late AuthCubit authCubit;

  setUp(() {
    mockRepo = MockAuthRepo();
    authCubit = AuthCubit(authRepository: mockRepo);
  });

  tearDown(() {
    authCubit.close();
  });

  group('AuthCubit - Auto Login & Session Eviction', () {
    test(
      'auto-login navigates to Authenticated when storage contains key',
      () async {
        mockRepo.credentials = (
          username: 'rep_1',
          apiKey: 'valid_key_123',
          userId: 1,
        );

        expectLater(
          authCubit.stream,
          emitsInOrder([
            isA<AuthLoading>(),
            isA<AuthSuccess>(),
          ]),
        );

        authCubit.checkAuth();
      },
    );

    test(
      'session expired clears storage and emits Unauthenticated with message',
      () async {
        expectLater(
          authCubit.stream,
          emitsInOrder([
            isA<AuthLoggedOut>(),
          ]),
        );

        authCubit.sessionExpired();
        await pumpEventQueue();
        expect(mockRepo.logoutCalled, isTrue);
      },
    );
  });
}
