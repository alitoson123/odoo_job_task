import 'package:hive/hive.dart';
import '../../../../core/storage/hive_storage.dart';
import '../models/customer_model.dart';
import '../models/pending_op_model.dart';

/// Data source handling local caching and offline operation queue in Hive.
class CustomerLocalDataSource {
  final Box _customersBox;
  final Box _pendingOpsBox;

  CustomerLocalDataSource({Box? customersBox, Box? pendingOpsBox})
    : _customersBox = customersBox ?? HiveStorage.customersBox,
      _pendingOpsBox = pendingOpsBox ?? HiveStorage.pendingOpsBox;

  /// Caches a list of customers, preserving detailed fields if already cached.
  Future<void> cacheCustomers(List<CustomerModel> customers) async {
    for (final customer in customers) {
      final existingRaw = _customersBox.get(customer.id);
      if (existingRaw != null && existingRaw is Map) {
        final existing = CustomerModel.fromJson(
          Map<String, dynamic>.from(existingRaw),
        );
        final merged = existing.copyWith(
          name: customer.name,
          phone: customer.phone ?? existing.phone,
          city: customer.city ?? existing.city,
        );
        await _customersBox.put(customer.id, merged.toJson());
      } else {
        await _customersBox.put(customer.id, customer.toJson());
      }
    }
  }

  /// Retrieves cached customers, applying pending sync flags and search filter.
  List<CustomerModel> getCachedCustomers({String? searchQuery}) {
    final pendingIds = getPendingPartnerIds();
    final list = <CustomerModel>[];

    for (final key in _customersBox.keys) {
      final data = _customersBox.get(key);
      if (data is Map) {
        final customer = CustomerModel.fromJson(
          Map<String, dynamic>.from(data),
        );
        final withPending = customer.copyWith(
          isPendingSync: pendingIds.contains(customer.id),
        );
        list.add(withPending);
      }
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      list.retainWhere((c) => c.name.toLowerCase().contains(q));
    }

    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  /// Caches full details for a single customer.
  Future<void> cacheCustomerDetails(CustomerModel customer) async {
    await _customersBox.put(customer.id, customer.toJson());
  }

  /// Retrieves a single cached customer by ID.
  CustomerModel? getCachedCustomer(int id) {
    final data = _customersBox.get(id);
    if (data is Map) {
      final customer = CustomerModel.fromJson(Map<String, dynamic>.from(data));
      return customer.copyWith(
        isPendingSync: getPendingPartnerIds().contains(id),
      );
    }
    return null;
  }

  /// Updates customer phone locally and marks as pending sync.
  Future<void> updateCustomerPhoneLocally({
    required int customerId,
    required String newPhone,
  }) async {
    final current = getCachedCustomer(customerId);
    final updated =
        (current ??
                CustomerModel(id: customerId, name: 'Customer #$customerId'))
            .copyWith(phone: newPhone.trim(), isPendingSync: true);
    await _customersBox.put(customerId, updated.toJson());
  }

  /// Appends an offline write operation to the pending queue box.
  Future<void> addPendingOperation({
    required int partnerId,
    required String field,
    required String value,
  }) async {
    final op = {
      'partnerId': partnerId,
      'field': field,
      'value': value,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    await _pendingOpsBox.add(op);
  }

  /// Retrieves all pending operations in FIFO order (by timestamp).
  List<PendingOp> getPendingOperations() {
    final ops = <PendingOp>[];
    for (final key in _pendingOpsBox.keys) {
      final val = _pendingOpsBox.get(key);
      if (val is Map) {
        ops.add(PendingOp.fromMap(key, Map<dynamic, dynamic>.from(val)));
      }
    }
    ops.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return ops;
  }

  /// Returns IDs of partners that have pending offline changes.
  Set<int> getPendingPartnerIds() {
    return getPendingOperations().map((op) => op.partnerId).toSet();
  }

  /// Removes an operation from the queue upon successful sync.
  Future<void> removePendingOperation(dynamic key) async {
    await _pendingOpsBox.delete(key);
  }

  /// Returns true if there are any cached customers in storage.
  bool get hasCachedCustomers => _customersBox.isNotEmpty;
}
