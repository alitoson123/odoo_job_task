import 'package:dio/dio.dart';
import '../storage/secure_storage.dart';

/// Centralized HTTP client for interacting with Odoo JSON-2 RPC endpoints.
class OdooClient {
  static const String defaultBaseUrl = 'https://techmates.odoo.com';
  static const String defaultDatabase = 'techmates';

  final Dio _dio;
  final SecureStorage? _secureStorage;
  void Function()? onSessionExpired;

  OdooClient({
    Dio? dio,
    SecureStorage? secureStorage,
    this.onSessionExpired,
    String baseUrl = defaultBaseUrl,
  })  : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
                sendTimeout: const Duration(seconds: 15),
                headers: {
                  'X-Odoo-Database': defaultDatabase,
                  'Content-Type': 'application/json',
                },
              ),
            ),
        _secureStorage = secureStorage;

  /// Executes a JSON-2 RPC call against `POST /json/2/<model>/<method>`.
  Future<dynamic> callRpc({
    required String model,
    required String method,
    required Map<String, dynamic> body,
    String? apiKey,
  }) async {
    final key = apiKey ?? await _secureStorage?.getApiKey();

    final options = Options(
      headers: {
        if (key != null && key.isNotEmpty) 'Authorization': 'bearer $key',
      },
    );

    try {
      final response = await _dio.post(
        '/json/2/$model/$method',
        data: body,
        options: options,
      );

      return response.data;
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      if (statusCode == 401 || statusCode == 403) {
        onSessionExpired?.call();
      }
      rethrow;
    }
  }
}
