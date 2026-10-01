import '../../data/models/sale_order_details_model.dart';
import '../../data/models/sale_order_model.dart';

abstract class OrderDetailsState {}

class OrderDetailsInitial extends OrderDetailsState {}

class OrderDetailsLoading extends OrderDetailsState {}

class OrderDetailsSuccess extends OrderDetailsState {
  final SaleOrderModel order;
  final List<SaleOrderDetailsModel> lines;
  final bool isOffline;

  OrderDetailsSuccess({
    required this.order,
    required this.lines,
    this.isOffline = false,
  });
}

class OrderDetailsFailure extends OrderDetailsState {
  final String message;

  OrderDetailsFailure(this.message);
}

class OrderConfirming extends OrderDetailsState {
  final SaleOrderModel order;
  final List<SaleOrderDetailsModel> lines;

  OrderConfirming({required this.order, required this.lines});
}

class OrderConfirmSuccess extends OrderDetailsState {
  final SaleOrderModel order;
  final List<SaleOrderDetailsModel> lines;
  final String message;

  OrderConfirmSuccess({
    required this.order,
    required this.lines,
    this.message = 'Order confirmed successfully',
  });
}

class OrderConfirmFailure extends OrderDetailsState {
  final SaleOrderModel order;
  final List<SaleOrderDetailsModel> lines;
  final String message;

  OrderConfirmFailure({
    required this.order,
    required this.lines,
    required this.message,
  });
}
