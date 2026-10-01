import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_task/core/errors/failure.dart';

void main() {
  group('ServerFailure', () {
    test('supports value equality', () {
      const failure1 = ServerFailure('Internal error', statusCode: 500);
      const failure2 = ServerFailure('Internal error', statusCode: 500);
      const failure3 = ServerFailure('Not found', statusCode: 404);

      expect(failure1, equals(failure2));
      expect(failure1, isNot(equals(failure3)));
      expect(failure1.errorMessage, equals('Internal error'));
    });

    test('fromDioError maps connectionTimeout correctly', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionTimeout,
      );

      final failure = ServerFailure.fromDioError(dioException);

      expect(
        failure.message,
        equals('Connection timeout with the server.'),
      );
    });

    test('fromDioError maps connectionError correctly', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionError,
      );

      final failure = ServerFailure.fromDioError(dioException);

      expect(
        failure.message,
        equals('No internet connection or network error.'),
      );
    });

    test('fromBadResponse extracts backend error message from map', () {
      final failure = ServerFailure.fromBadResponse(
        statusCode: 400,
        response: {
          'error': {
            'data': {'message': 'Invalid session token'},
          },
        },
      );

      expect(failure.message, equals('Invalid session token'));
      expect(failure.statusCode, equals(400));
    });

    test('fromBadResponse falls back to status code message', () {
      final failure = ServerFailure.fromBadResponse(
        statusCode: 404,
      );

      expect(failure.message, equals('Requested resource not found.'));
      expect(failure.statusCode, equals(404));
    });
  });

  group('CancelFailure', () {
    test('uses default message and supports equality', () {
      const failure1 = CancelFailure();
      const failure2 = CancelFailure('Operation cancelled');

      expect(failure1.message, equals('Operation cancelled'));
      expect(failure1, equals(failure2));
    });
  });
}
