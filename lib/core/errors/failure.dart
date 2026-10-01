import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';

/// Base failure class representing a domain or operational failure.
abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  /// Backward-compatible alias for errorMessage.
  String get errorMessage => message;

  @override
  List<Object?> get props => [message];
}

/// Represents server-side, network, or HTTP-related failures.
class ServerFailure extends Failure {
  final int? statusCode;

  const ServerFailure(super.message, {this.statusCode});

  @override
  List<Object?> get props => [message, statusCode];

  /// Factory constructor to map [DioException] to [ServerFailure].
  factory ServerFailure.fromDioError(DioException dioException) {
    switch (dioException.type) {
      case DioExceptionType.connectionTimeout:
        return const ServerFailure(
          'Connection timeout with the server.',
        );
      case DioExceptionType.sendTimeout:
        return const ServerFailure(
          'Request send timeout. Please try again.',
        );
      case DioExceptionType.receiveTimeout:
        return const ServerFailure(
          'Receive timeout from the server.',
        );
      case DioExceptionType.badCertificate:
        return const ServerFailure(
          'Bad SSL certificate detected.',
        );
      case DioExceptionType.badResponse:
        return ServerFailure.fromBadResponse(
          statusCode: dioException.response?.statusCode,
          response: dioException.response?.data,
        );
      case DioExceptionType.cancel:
        return const ServerFailure('Request was cancelled.');
      case DioExceptionType.connectionError:
        return const ServerFailure(
          'No internet connection or network error.',
        );
      case DioExceptionType.unknown:
        return ServerFailure(
          dioException.message ?? 'Unexpected error occurred.',
        );
      case DioExceptionType.transformTimeout:
        return const ServerFailure('Transform timeout error.');
    }
  }

  /// Maps HTTP status codes and API error response payloads to user-friendly messages.
  factory ServerFailure.fromBadResponse({
    int? statusCode,
    dynamic response,
  }) {
    final serverMessage = _extractServerMessage(response);
    
    if (serverMessage != null && serverMessage.trim().isNotEmpty) {
      return ServerFailure(serverMessage, statusCode: statusCode);
    }

    if (statusCode == null) {
      return const ServerFailure('Unknown server response.');
    }

    switch (statusCode) {
      case 400:
        return ServerFailure(
          'Bad request. Please check your input.',
          statusCode: statusCode,
        );
      case 401:
        return ServerFailure(
          'Invalid username or API key.',
          statusCode: statusCode,
        );
      case 403:
        return ServerFailure(
          'Invalid username or API key.',
          statusCode: statusCode,
        );
      case 404:
        return ServerFailure(
          'Requested resource not found.',
          statusCode: statusCode,
        );
      case 500:
        return ServerFailure(
          'Internal server error. Please try later.',
          statusCode: statusCode,
        );
      case 502:
        return ServerFailure('Bad gateway.', statusCode: statusCode);
      case 503:
        return ServerFailure(
          'Service unavailable. Try again later.',
          statusCode: statusCode,
        );
      case 504:
        return ServerFailure('Gateway timeout.', statusCode: statusCode);
      default:
        return ServerFailure(
          'There was an error, please try again.',
          statusCode: statusCode,
        );
    }
  }

  static String? _extractServerMessage(dynamic response) {
    if (response is Map<String, dynamic>) {
      if (response['message'] is String) return response['message'] as String;
      if (response['error'] is Map) {
        final error = response['error'] as Map;
        if (error['data'] is Map && error['data']['message'] is String) {
          return error['data']['message'] as String;
        }
        if (error['message'] is String) return error['message'] as String;
      }
      if (response['name'] is String) return response['name'] as String;
    }
    return null;
  }
}

/// Failure representing cancelled operations.
class CancelFailure extends Failure {
  const CancelFailure([super.message = 'Operation cancelled']);
}
