import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/view/login_view.dart';
import '../../features/home/presentation/view/home_view.dart';

abstract class AppRouter {
  static const String login = '/';
  static const String home = '/home';

  static final router = GoRouter(
    initialLocation: login,
    routes: [
      GoRoute(
        path: login,
        builder: (context, state) => const LoginView(),
      ),
      GoRoute(
        path: home,
        builder: (context, state) => const HomeView(),
      ),
    ],
  );
}
