import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';

/// Contract for checking and observing device network connectivity.
abstract class NetworkInfo {
  Future<bool> get isConnected;
  Stream<bool> get onConnectivityChanged;
}

/// Implementation of [NetworkInfo] using [Connectivity] from connectivity_plus.
class NetworkInfoImpl implements NetworkInfo {
  final Connectivity _connectivity;

  NetworkInfoImpl([Connectivity? connectivity])
      : _connectivity = connectivity ?? Connectivity();

  @override
  Future<bool> get isConnected async {
    try {
      final results = await _connectivity
          .checkConnectivity()
          .timeout(const Duration(seconds: 2));
      return _hasConnection(results);
    } catch (_) {
      return true;
    }
  }

  @override
  Stream<bool> get onConnectivityChanged {
    try {
      return _connectivity.onConnectivityChanged
          .map(_hasConnection)
          .distinct();
    } catch (_) {
      return const Stream.empty();
    }
  }

  bool _hasConnection(List<ConnectivityResult> results) {
    return results.any((result) => result != ConnectivityResult.none);
  }
}

/// Helper extension for detecting network-induced Dio errors.
extension DioNetworkErrorX on Exception {
  bool get isNetworkError {
    if (this is! DioException) return false;
    final e = this as DioException;
    return e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout;
  }
}
