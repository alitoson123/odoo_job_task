import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import '../storage/hive_storage.dart';
import '../storage/secure_storage.dart';
import 'network_info.dart';
import 'odoo_client.dart';
import '../../features/auth/data/repositories/auth_repository.dart';
import '../../features/auth/presentation/view_model/auth_cubit.dart';
import '../../features/auth/presentation/view_model/auth_state.dart';
import '../../features/customers/data/datasources/customer_local_data_source.dart';
import '../../features/customers/data/repositories/customer_repository.dart';
import '../../features/customers/data/services/customer_sync_service.dart';
import '../../features/customers/presentation/view_model/customer_cubit.dart';
import '../../features/customers/presentation/view_model/customer_details_cubit.dart';
import '../../features/orders/data/datasources/order_local_data_source.dart';
import '../../features/orders/data/repositories/order_repository.dart';
import '../../features/orders/presentation/view_model/order_details_cubit.dart';
import '../../features/orders/presentation/view_model/orders_cubit.dart';

final sl = GetIt.instance;

/// Initializes service locator and registers core singletons and dependencies.
Future<void> initDependencies() async {
  // Local Database & Cache
  await HiveStorage.init();

  // Storage
  sl.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(),
  );
  sl.registerLazySingleton<SecureStorage>(
    () => SecureStorage(sl<FlutterSecureStorage>()),
  );

  // Connectivity & Network
  sl.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(),
  );

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
    () => AuthCubit(authRepository: sl<AuthRepository>()),
  );

  // Customers Feature
  sl.registerLazySingleton<CustomerLocalDataSource>(
    () => CustomerLocalDataSource(),
  );

  sl.registerLazySingleton<CustomerSyncService>(
    () => CustomerSyncService(
      localDataSource: sl<CustomerLocalDataSource>(),
      odooClient: sl<OdooClient>(),
      networkInfo: sl<NetworkInfo>(),
    ),
  );

  sl.registerLazySingleton<CustomerRepository>(
    () => CustomerRepository(
      odooClient: sl<OdooClient>(),
      localDataSource: sl<CustomerLocalDataSource>(),
      networkInfo: sl<NetworkInfo>(),
    ),
  );

  sl.registerFactory<CustomerCubit>(
    () => CustomerCubit(
      customerRepository: sl<CustomerRepository>(),
      syncService: sl<CustomerSyncService>(),
    ),
  );

  sl.registerFactory<CustomerDetailsCubit>(
    () => CustomerDetailsCubit(
      customerRepository: sl<CustomerRepository>(),
    ),
  );

  // Orders Feature
  sl.registerLazySingleton<OrderLocalDataSource>(
    () => OrderLocalDataSource(),
  );

  sl.registerLazySingleton<OrderRepository>(
    () => OrderRepository(
      odooClient: sl<OdooClient>(),
      localDataSource: sl<OrderLocalDataSource>(),
      networkInfo: sl<NetworkInfo>(),
    ),
  );

  sl.registerFactory<OrdersCubit>(
    () => OrdersCubit(orderRepository: sl<OrderRepository>()),
  );

  sl.registerFactory<OrderDetailsCubit>(
    () => OrderDetailsCubit(orderRepository: sl<OrderRepository>()),
  );

  // Start background connectivity auto-sync listener
  sl<CustomerSyncService>().initAutoSync();
}
