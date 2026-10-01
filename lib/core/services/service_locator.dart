import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import '../../features/auth/data/repositories/auth_repository.dart';
import '../../features/auth/presentation/view_model/auth_cubit.dart';
import '../../features/auth/presentation/view_model/auth_state.dart';
import 'odoo_client.dart';
import '../storage/secure_storage.dart';

final sl = GetIt.instance;

/// Initializes service locator and registers core singletons and dependencies.
Future<void> initDependencies() async {
  // Storage
  sl.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(),
  );
  sl.registerLazySingleton<SecureStorage>(
    () => SecureStorage(sl<FlutterSecureStorage>()),
  );

  // Network
  sl.registerLazySingleton<OdooClient>(
    () => OdooClient(
      secureStorage: sl<SecureStorage>(),
      onSessionExpired: () {
        if (sl.isRegistered<AuthCubit>()) {
          final cubit = sl<AuthCubit>();
          if (cubit.state is AuthSuccess) {
            cubit.sessionExpired();
          }
        }
      },
    ),
  );

  // Auth Feature
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepository(
      odooClient: sl<OdooClient>(),
      secureStorage: sl<SecureStorage>(),
    ),
  );

  sl.registerLazySingleton<AuthCubit>(
    () => AuthCubit(
      authRepository: sl<AuthRepository>(),
    ),
  );
}
