import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage wrapper providing encrypted storage for sensitive credentials.
class SecureStorage {
  static const String _keyUsername = 'auth_username';
  static const String _keyApiKey = 'auth_api_key';

  final FlutterSecureStorage _storage;

  const SecureStorage([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  /// Saves the authenticated username and API key into encrypted hardware storage.
  Future<void> saveCredentials({
    required String username,
    required String apiKey,
  }) async {
    await _storage.write(key: _keyUsername, value: username.trim());
    await _storage.write(key: _keyApiKey, value: apiKey.trim());
  }

  /// Retrieves the saved username from storage, or null if unset.
  Future<String?> getUsername() async {
    return await _storage.read(key: _keyUsername);
  }

  /// Retrieves the saved API key from storage, or null if unset.
  Future<String?> getApiKey() async {
    return await _storage.read(key: _keyApiKey);
  }

  /// Clears stored credentials upon logout or invalidation.
  Future<void> clearCredentials() async {
    await _storage.delete(key: _keyUsername);
    await _storage.delete(key: _keyApiKey);
  }

  /// Returns true if valid credentials exist in storage.
  Future<bool> hasCredentials() async {
    final apiKey = await getApiKey();
    return apiKey != null && apiKey.isNotEmpty;
  }
}
