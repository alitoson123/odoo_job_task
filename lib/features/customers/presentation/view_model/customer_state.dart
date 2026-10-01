import '../../data/models/customer_model.dart';

abstract class CustomerState {}

class CustomerInitial extends CustomerState {}

class CustomerLoading extends CustomerState {}

class CustomerSuccess extends CustomerState {
  final List<CustomerModel> customers;
  final bool isOffline;

  CustomerSuccess({
    required this.customers,
    this.isOffline = false,
  });
}

class CustomerEmpty extends CustomerState {
  final bool isOffline;

  CustomerEmpty({this.isOffline = false});
}

class CustomerFailure extends CustomerState {
  final String message;

  CustomerFailure({required this.message});
}
