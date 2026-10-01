import 'package:go_router/go_router.dart';
import '../services/service_locator.dart';
import '../../features/auth/presentation/view_model/auth_cubit.dart';
import '../../features/auth/presentation/view_model/auth_state.dart';
import '../../features/auth/presentation/view/login_view.dart';
import '../../features/customers/data/models/customer_model.dart';
import '../../features/customers/presentation/view/customer_details_view.dart';
import '../../features/customers/presentation/view/customer_list_view.dart';
import '../../features/orders/data/models/sale_order_model.dart';
import '../../features/orders/presentation/view/order_details_view.dart';
import '../../features/orders/presentation/view/orders_view.dart';

abstract class AppRouter {
  static const String login = '/';
  static const String home = '/home';
  static const String customerDetails = '/customer-details';
  static const String orders = '/orders';
  static const String orderDetails = '/order-details';

  static final router = GoRouter(
    initialLocation: login,
    redirect: (context, state) {
      if (!sl.isRegistered<AuthCubit>()) return null;
      final authState = sl<AuthCubit>().state;
      final isLoggingIn = state.matchedLocation == login;

      if (authState is AuthSuccess && isLoggingIn) {
        return home;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: login,
        builder: (context, state) => const LoginView(),
      ),
      GoRoute(
        path: home,
        builder: (context, state) => const CustomerListView(),
      ),
      GoRoute(
        path: customerDetails,
        builder: (context, state) {
          final customer = state.extra as CustomerModel? ??
              const CustomerModel(id: 0, name: 'Customer');
          return CustomerDetailsView(initialCustomer: customer);
        },
      ),
      GoRoute(
        path: orders,
        builder: (context, state) => const OrdersView(),
      ),
      GoRoute(
        path: orderDetails,
        builder: (context, state) {
          final order = state.extra as SaleOrderModel? ??
              const SaleOrderModel(
                id: 0,
                name: 'Order',
                partnerId: 0,
                partnerName: 'Partner',
                state: 'draft',
              );
          return OrderDetailsView(initialOrder: order);
        },
      ),
    ],
  );
}
