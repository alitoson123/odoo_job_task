import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_task/core/storage/secure_storage.dart';

void main() {
  late SecureStorage secureStorage;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    secureStorage = const SecureStorage(FlutterSecureStorage());
  });

  group('SecureStorage', () {
    test('saveCredentials stores trimmed username and apiKey', () async {
      await secureStorage.saveCredentials(
        username: ' admin ',
        apiKey: ' key123 ',
      );

      final username = await secureStorage.getUsername();
      final apiKey = await secureStorage.getApiKey();
      final hasCreds = await secureStorage.hasCredentials();

      expect(username, equals('admin'));
      expect(apiKey, equals('key123'));
      expect(hasCreds, isTrue);
    });

    test('clearCredentials removes stored values', () async {
      await secureStorage.saveCredentials(
        username: 'admin',
        apiKey: 'key123',
      );

      await secureStorage.clearCredentials();

      final username = await secureStorage.getUsername();
      final apiKey = await secureStorage.getApiKey();
      final hasCreds = await secureStorage.hasCredentials();

      expect(username, isNull);
      expect(apiKey, isNull);
      expect(hasCreds, isFalse);
    });
  });
}
