import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/customer_model.dart';
import '../../data/repositories/customer_repository.dart';
import 'customer_details_state.dart';

/// Manages customer details retrieval and phone number update operations.
class CustomerDetailsCubit extends Cubit<CustomerDetailsState> {
  final CustomerRepository _customerRepository;

  CustomerDetailsCubit({required CustomerRepository customerRepository})
      : _customerRepository = customerRepository,
        super(CustomerDetailsInitial());

  /// Loads full details for the given customer ID.
  Future<void> loadDetails(int customerId) async {
    emit(CustomerDetailsLoading());

    final result = await _customerRepository.getCustomerDetails(customerId);

    result.fold(
      (failure) => emit(CustomerDetailsFailure(failure.message)),
      (customer) => emit(
        CustomerDetailsSuccess(
          customer,
          isOffline: _isOffline,
        ),
      ),
    );
  }

  /// Updates phone number or queues offline if connection is unavailable.
  Future<void> updatePhone({
    required int customerId,
    required String newPhone,
    required CustomerModel currentCustomer,
  }) async {
    emit(CustomerPhoneUpdating(currentCustomer));

    final result = await _customerRepository.updateCustomerPhone(
      customerId: customerId,
      newPhone: newPhone,
    );

    result.fold(
      (failure) => emit(
        CustomerPhoneUpdateFailure(
          customer: currentCustomer,
          message: failure.message,
        ),
      ),
      (syncedOnline) {
        final updated = currentCustomer.copyWith(
          phone: newPhone.trim(),
          isPendingSync: !syncedOnline,
        );
        emit(
          CustomerPhoneUpdateSuccess(
            customer: updated,
            message: syncedOnline
                ? 'Phone number updated successfully'
                : 'Saved offline. Changes will sync when online.',
          ),
        );
      },
    );
  }

  bool get _isOffline {
    try {
      return _customerRepository.isLastFetchOffline;
    } catch (_) {
      return false;
    }
  }
}
