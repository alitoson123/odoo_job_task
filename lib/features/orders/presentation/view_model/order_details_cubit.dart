import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/sale_order_details_model.dart';
import '../../data/models/sale_order_model.dart';
import '../../data/repositories/order_repository.dart';
import 'order_details_state.dart';

/// Manages fetching order details and confirming quotations.
class OrderDetailsCubit extends Cubit<OrderDetailsState> {
  final OrderRepository _orderRepository;

  OrderDetailsCubit({required OrderRepository orderRepository})
      : _orderRepository = orderRepository,
        super(OrderDetailsInitial());

  /// Loads order header and lines for given order ID.
  Future<void> loadDetails(int orderId) async {
    emit(OrderDetailsLoading());

    final result = await _orderRepository.getOrderDetails(orderId);

    result.fold(
      (failure) => emit(OrderDetailsFailure(failure.message)),
      (data) => emit(
        OrderDetailsSuccess(
          order: data.order,
          lines: data.lines,
          isOffline: _isOffline,
        ),
      ),
    );
  }

  /// Confirms a quotation / sales order (`sale.order/action_confirm`).
  Future<void> confirmOrder({
    required int orderId,
    required SaleOrderModel currentOrder,
    required List<SaleOrderDetailsModel> currentLines,
  }) async {
    emit(OrderConfirming(order: currentOrder, lines: currentLines));

    final result = await _orderRepository.confirmOrder(orderId);

    result.fold(
      (failure) => emit(
        OrderConfirmFailure(
          order: currentOrder,
          lines: currentLines,
          message: failure.message,
        ),
      ),
      (success) {
        final confirmed = currentOrder.copyWith(state: 'sale');
        emit(OrderConfirmSuccess(order: confirmed, lines: currentLines));
      },
    );
  }

  bool get _isOffline {
    try {
      return _orderRepository.isLastFetchOffline;
    } catch (_) {
      return false;
    }
  }
}
