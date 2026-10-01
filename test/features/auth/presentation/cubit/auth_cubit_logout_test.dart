import 'package:flutter_test/flutter_test.dart';
import 'package:job_task/features/auth/data/repositories/auth_repository.dart';
import 'package:job_task/features/auth/presentation/view_model/auth_cubit.dart';
import 'package:job_task/features/auth/presentation/view_model/auth_state.dart';

class MockAuthRepoForLogout extends Fake implements AuthRepository {
  bool logoutCalled = false;

  @override
  Future<void> logout() async {
    logoutCalled = true;
  }
}

void main() {
  late MockAuthRepoForLogout mockRepo;
  late AuthCubit authCubit;

  setUp(() {
    mockRepo = MockAuthRepoForLogout();
    authCubit = AuthCubit(authRepository: mockRepo);
  });

  tearDown(() {
    authCubit.close();
  });

  group('AuthCubit - Logout', () {
    test(
      'explicit logout invokes repository logout and emits Unauthenticated',
      () async {
        final expectedStates = [const AuthLoading(), const AuthLoggedOut()];

        expectLater(authCubit.stream, emitsInOrder(expectedStates));

        authCubit.logout();
        await pumpEventQueue();
        expect(mockRepo.logoutCalled, isTrue);
      },
    );
  });
}
