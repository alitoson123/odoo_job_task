import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_task/core/errors/failure.dart';
import 'package:job_task/core/services/odoo_client.dart';
import 'package:job_task/core/storage/secure_storage.dart';
import 'package:job_task/features/auth/data/repositories/auth_repository.dart';

class FakeOdooClient extends Fake implements OdooClient {
  dynamic responseToReturn;
  Exception? exceptionToThrow;

  @override
  Future<dynamic> callRpc({
    required String model,
    required String method,
    required Map<String, dynamic> body,
    String? apiKey,
  }) async {
    if (exceptionToThrow != null) {
      throw exceptionToThrow!;
    }
    return responseToReturn;
  }
}

void main() {
  late FakeOdooClient fakeOdooClient;
  late SecureStorage secureStorage;
  late AuthRepository authRepository;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    fakeOdooClient = FakeOdooClient();
    secureStorage = const SecureStorage(FlutterSecureStorage());
    authRepository = AuthRepository(
      odooClient: fakeOdooClient,
      secureStorage: secureStorage,
    );
  });

  group('AuthRepository', () {
    test('login returns Right(UserModel) and stores credentials', () async {
      fakeOdooClient.responseToReturn = [
        {'id': 2, 'name': 'Mitchell Admin', 'login': 'admin'}
      ];

      final result = await authRepository.login(
        username: 'admin',
        apiKey: 'key_123',
      );

      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Expected Right but got Left'),
        (user) {
          expect(user.id, equals(2));
          expect(user.name, equals('Mitchell Admin'));
        },
      );

      final storedKey = await secureStorage.getApiKey();
      expect(storedKey, equals('key_123'));
    });

    test('login returns Left(ServerFailure) when user not found', () async {
      fakeOdooClient.responseToReturn = [];

      final result = await authRepository.login(
        username: 'unknown',
        apiKey: 'key_123',
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, equals('Invalid username or API key'));
        },
        (user) => fail('Expected Left but got Right'),
      );
    });

    test('login returns Left(ServerFailure) on empty fields', () async {
      final result = await authRepository.login(
        username: '',
        apiKey: 'key_123',
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) {
          expect(failure.message, equals('Username and API key cannot be empty'));
        },
        (user) => fail('Expected Left but got Right'),
      );
    });

    test('login returns Left(ServerFailure) on DioException', () async {
      fakeOdooClient.exceptionToThrow = DioException(
        requestOptions: RequestOptions(path: '/json/2/res.users/search_read'),
        type: DioExceptionType.connectionTimeout,
      );

      final result = await authRepository.login(
        username: 'admin',
        apiKey: 'key_123',
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) {
          expect(
            failure.message,
            equals('Connection timeout with the server.'),
          );
        },
        (user) => fail('Expected Left but got Right'),
      );
    });

    test('logout clears secure storage', () async {
      await secureStorage.saveCredentials(username: 'admin', apiKey: 'key');
      await authRepository.logout();

      final hasCreds = await secureStorage.hasCredentials();
      expect(hasCreds, isFalse);
    });
  });
}
