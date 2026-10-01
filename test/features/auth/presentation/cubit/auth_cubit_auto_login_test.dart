import 'package:flutter_test/flutter_test.dart';
import 'package:job_task/features/auth/data/models/user_model.dart';
import 'package:job_task/features/auth/data/repositories/auth_repository.dart';
import 'package:job_task/features/auth/presentation/view_model/auth_cubit.dart';
import 'package:job_task/features/auth/presentation/view_model/auth_state.dart';

class MockAuthRepo extends Fake implements AuthRepository {
  ({String? username, String? apiKey}) credentials = (
    username: null,
    apiKey: null,
  );
  bool logoutCalled = false;

  @override
  Future<({String? username, String? apiKey})> getSavedCredentials() async =>
      credentials;

  @override
  Future<void> logout() async {
    logoutCalled = true;
    credentials = (username: null, apiKey: null);
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
        mockRepo.credentials = (username: 'rep_1', apiKey: 'valid_key_123');

        final expectedStates = [
          const AuthLoading(),
          const AuthSuccess(
            user: UserModel(id: 0, name: 'rep_1', login: 'rep_1'),
            apiKey: 'valid_key_123',
          ),
        ];

        expectLater(authCubit.stream, emitsInOrder(expectedStates));
        authCubit.checkAuth();
      },
    );

    test(
      'session expired clears storage and emits Unauthenticated with message',
      () async {
        final expectedStates = [
          const AuthLoggedOut(message: 'Session expired. Please log in again.'),
        ];

        expectLater(authCubit.stream, emitsInOrder(expectedStates));
        authCubit.sessionExpired();
        await pumpEventQueue();
        expect(mockRepo.logoutCalled, isTrue);
      },
    );
  });
}
