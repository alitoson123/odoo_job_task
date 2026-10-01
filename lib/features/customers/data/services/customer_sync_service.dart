import 'dart:async';
import 'package:dio/dio.dart';
import '../../../../core/services/network_info.dart';
import '../../../../core/services/odoo_client.dart';
import '../datasources/customer_local_data_source.dart';

/// Service orchestrating automatic synchronization of queued offline operations.
class CustomerSyncService {
  final CustomerLocalDataSource _localDataSource;
  final OdooClient _odooClient;
  final NetworkInfo _networkInfo;

  final StreamController<int> _syncCompletedController =
      StreamController<int>.broadcast();
  StreamSubscription<bool>? _connectivitySubscription;
  bool _isSyncing = false;

  CustomerSyncService({
    required CustomerLocalDataSource localDataSource,
    required OdooClient odooClient,
    required NetworkInfo networkInfo,
  })  : _localDataSource = localDataSource,
        _odooClient = odooClient,
        _networkInfo = networkInfo;

  /// Stream emitting the number of synced items when a sync batch finishes.
  Stream<int> get onSyncCompleted => _syncCompletedController.stream;

  /// Whether a sync operation is currently actively running.
  bool get isSyncing => _isSyncing;

  /// Begins listening to connectivity changes to trigger automatic sync.
  void initAutoSync() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription =
        _networkInfo.onConnectivityChanged.listen((isConnected) {
      if (isConnected) {
        syncPendingOperations();
      }
    });
  }

  /// Executes pending operations in FIFO order against Odoo (`res.partner/write`).
  Future<int> syncPendingOperations() async {
    if (_isSyncing) return 0;
    if (!await _networkInfo.isConnected) return 0;

    final ops = _localDataSource.getPendingOperations();
    if (ops.isEmpty) return 0;

    _isSyncing = true;
    int syncedCount = 0;

    try {
      for (final op in ops) {
        try {
          final dynamic response = await _odooClient.callRpc(
            model: 'res.partner',
            method: 'write',
            body: {
              'ids': [op.partnerId],
              'vals': {op.field: op.value.trim()},
            },
          );

          if (response == true) {
            await _localDataSource.removePendingOperation(op.key);
            syncedCount++;
          }
        } on DioException catch (e) {
          if (e.type == DioExceptionType.connectionError ||
              e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.sendTimeout ||
              e.type == DioExceptionType.receiveTimeout) {
            break;
          }
        } catch (_) {
          // On failure: keep in queue for the next attempt.
        }
      }
    } finally {
      _isSyncing = false;
    }

    if (syncedCount > 0) {
      _syncCompletedController.add(syncedCount);
    }

    return syncedCount;
  }

  /// Cancels subscriptions and disposes stream controller.
  void dispose() {
    _connectivitySubscription?.cancel();
    _syncCompletedController.close();
  }
}
