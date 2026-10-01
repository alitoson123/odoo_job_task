import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:job_task/features/auth/presentation/widgets/error_banner.dart';
import '../../../../core/router/app_router.dart';
import '../view_model/auth_cubit.dart';
import '../view_model/auth_state.dart';
import '../widgets/login_form.dart';
import '../widgets/login_header.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<AuthCubit, AuthState>(
          listener: _onAuthStateChanged,
          builder: (context, state) {
            final isLoading = state is AuthLoading;
            final errorMessage = state is AuthFailure ? state.message : null;

            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const LoginHeader(),
                      const SizedBox(height: 24),
                      if (errorMessage != null) ...[
                        ErrorBanner(message: errorMessage),
                        const SizedBox(height: 16),
                      ],
                      LoginForm(
                        isLoading: isLoading,
                        onSubmit: (username, apiKey) {
                          context.read<AuthCubit>().login(
                            username: username,
                            apiKey: apiKey,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _onAuthStateChanged(BuildContext context, AuthState state) {
    if (state is AuthFailure) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (state is AuthLoggedOut && state.message != null) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message!),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (state is AuthSuccess) {
      context.go(AppRouter.home);
    }
  }
}
