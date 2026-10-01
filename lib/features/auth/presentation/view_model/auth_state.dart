import '../../data/models/user_model.dart';

abstract class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthSuccess extends AuthState {
  final UserModel user;
  final String apiKey;

  const AuthSuccess({required this.user, required this.apiKey});
}

class AuthLoggedOut extends AuthState {
  final String? message;

  const AuthLoggedOut({this.message});
}

class AuthFailure extends AuthState {
  final String message;

  const AuthFailure({required this.message});
}
