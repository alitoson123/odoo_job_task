import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import 'auth_state.dart';

/// Manages authentication state and actions via Cubit.
class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;

  AuthCubit({required AuthRepository authRepository})
    : _authRepository = authRepository,
      super(const AuthInitial());

  /// Checks local storage for saved credentials on startup.
  Future<void> checkAuth() async {
    emit(const AuthLoading());
    try {
      final saved = await _authRepository.getSavedCredentials();
      if (saved.apiKey != null && saved.apiKey!.isNotEmpty) {
        final username = saved.username ?? 'User';
        emit(
          AuthSuccess(
            user: UserModel(
              id: saved.userId ?? 0,
              name: username,
              login: username,
            ),
            apiKey: saved.apiKey!,
          ),
        );
      } else {
        emit(const AuthLoggedOut());
      }
    } catch (_) {
      emit(const AuthLoggedOut());
    }
  }

  /// Authenticates with username and API key.
  Future<void> login({required String username, required String apiKey}) async {
    emit(const AuthLoading());
    final result = await _authRepository.login(
      username: username,
      apiKey: apiKey,
    );
    result.fold(
      (failure) => emit(AuthFailure(message: failure.message)),
      (user) => emit(AuthSuccess(user: user, apiKey: apiKey)),
    );
  }

  /// Logs out the user and clears stored credentials.
  Future<void> logout() async {
    emit(const AuthLoading());
    await _authRepository.logout();
    emit(const AuthLoggedOut());
  }

  /// Invoked when backend returns 401 or 403.
  Future<void> sessionExpired() async {
    await _authRepository.logout();
    emit(const AuthLoggedOut(message: 'Session expired. Please log in again.'));
  }
}
