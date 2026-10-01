import '../../data/models/sale_order_model.dart';

abstract class OrdersState {}

class OrdersInitial extends OrdersState {}

class OrdersLoading extends OrdersState {}

class OrdersSuccess extends OrdersState {
  final List<SaleOrderModel> orders;
  final bool isOffline;

  OrdersSuccess({
    required this.orders,
    this.isOffline = false,
  });
}

class OrdersEmpty extends OrdersState {
  final bool isOffline;

  OrdersEmpty({this.isOffline = false});
}

class OrdersFailure extends OrdersState {
  final String message;

  OrdersFailure({required this.message});
}
