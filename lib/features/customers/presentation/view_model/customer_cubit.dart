import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/customer_repository.dart';
import '../../data/services/customer_sync_service.dart';
import 'customer_state.dart';

/// Manages fetching, searching, and auto-refreshing customers upon offline sync.
class CustomerCubit extends Cubit<CustomerState> {
  final CustomerRepository _customerRepository;
  final CustomerSyncService? _syncService;
  StreamSubscription<int>? _syncSubscription;
  Timer? _debounceTimer;
  String _currentQuery = '';

  CustomerCubit({
    required CustomerRepository customerRepository,
    CustomerSyncService? syncService,
  })  : _customerRepository = customerRepository,
        _syncService = syncService,
        super(CustomerInitial()) {
    _syncSubscription = _syncService?.onSyncCompleted.listen((_) {
      refresh();
    });
  }

  /// Fetches customers matching the optional query.
  Future<void> fetchCustomers({String? query}) async {
    _currentQuery = query ?? '';
    emit(CustomerLoading());

    final result = await _customerRepository.getCustomers(
      searchQuery: _currentQuery,
    );

    result.fold(
      (failure) => emit(CustomerFailure(message: failure.message)),
      (customers) {
        final isOffline = _isOffline;
        if (customers.isEmpty) {
          emit(CustomerEmpty(isOffline: isOffline));
        } else {
          emit(CustomerSuccess(customers: customers, isOffline: isOffline));
        }
      },
    );
  }

  /// Refreshes the list using the last known search query.
  Future<void> refresh() async {
    await fetchCustomers(query: _currentQuery);
  }

  /// Triggers a debounced search (400ms delay).
  void onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      fetchCustomers(query: query);
    });
  }

  bool get _isOffline {
    try {
      return _customerRepository.isLastFetchOffline;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    _syncSubscription?.cancel();
    return super.close();
  }
}
