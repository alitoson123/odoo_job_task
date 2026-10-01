import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/order_repository.dart';
import 'orders_state.dart';

/// Manages fetching and refreshing the sales orders list.
class OrdersCubit extends Cubit<OrdersState> {
  final OrderRepository _orderRepository;

  OrdersCubit({required OrderRepository orderRepository})
      : _orderRepository = orderRepository,
        super(OrdersInitial());

  /// Fetches orders from Odoo backend or offline cache.
  Future<void> fetchOrders() async {
    emit(OrdersLoading());

    final result = await _orderRepository.getOrders();

    result.fold(
      (failure) => emit(OrdersFailure(message: failure.message)),
      (orders) {
        final isOffline = _isOffline;
        if (orders.isEmpty) {
          emit(OrdersEmpty(isOffline: isOffline));
        } else {
          emit(OrdersSuccess(orders: orders, isOffline: isOffline));
        }
      },
    );
  }

  /// Refreshes the orders list.
  Future<void> refresh() async {
    await fetchOrders();
  }

  bool get _isOffline {
    try {
      return _orderRepository.isLastFetchOffline;
    } catch (_) {
      return false;
    }
  }
}
