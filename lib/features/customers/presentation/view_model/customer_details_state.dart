import '../../data/models/customer_model.dart';

abstract class CustomerDetailsState {}

class CustomerDetailsInitial extends CustomerDetailsState {}

class CustomerDetailsLoading extends CustomerDetailsState {}

class CustomerDetailsSuccess extends CustomerDetailsState {
  final CustomerModel customer;
  final bool isOffline;

  CustomerDetailsSuccess(this.customer, {this.isOffline = false});
}

class CustomerDetailsFailure extends CustomerDetailsState {
  final String message;

  CustomerDetailsFailure(this.message);
}

class CustomerPhoneUpdating extends CustomerDetailsState {
  final CustomerModel customer;

  CustomerPhoneUpdating(this.customer);
}

class CustomerPhoneUpdateSuccess extends CustomerDetailsState {
  final CustomerModel customer;
  final String message;

  CustomerPhoneUpdateSuccess({
    required this.customer,
    this.message = 'Phone number updated successfully',
  });
}

class CustomerPhoneUpdateFailure extends CustomerDetailsState {
  final CustomerModel customer;
  final String message;

  CustomerPhoneUpdateFailure({
    required this.customer,
    required this.message,
  });
}
