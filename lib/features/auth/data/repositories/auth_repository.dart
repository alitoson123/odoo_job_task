import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/services/odoo_client.dart';
import '../../../../core/storage/secure_storage.dart';
import '../models/user_model.dart';

/// Repository interface and implementation handling authentication.
class AuthRepository {
  final OdooClient _odooClient;
  final SecureStorage _secureStorage;

  const AuthRepository({
    required OdooClient odooClient,
    required SecureStorage secureStorage,
  })  : _odooClient = odooClient,
        _secureStorage = secureStorage;

  /// Authenticates a sales rep by querying `res.users/search_read`.
  Future<Either<Failure, UserModel>> login({
    required String username,
    required String apiKey,
  }) async {
    final cleanUsername = username.trim();
    final cleanKey = apiKey.trim();

    if (cleanUsername.isEmpty || cleanKey.isEmpty) {
      return const Left(
        ServerFailure('Username and API key cannot be empty'),
      );
    }

    try {
      final dynamic response = await _odooClient.callRpc(
        model: 'res.users',
        method: 'search_read',
        body: {
          'domain': [
            ['login', '=', cleanUsername]
          ],
          'fields': ['id', 'name', 'login'],
          'limit': 1,
        },
        apiKey: cleanKey,
      );

      if (response is List && response.isNotEmpty) {
        final user = UserModel.fromJson(
          response.first as Map<String, dynamic>,
        );
        await _secureStorage.saveCredentials(
          username: cleanUsername,
          apiKey: cleanKey,
        );
        return Right(user);
      }

      return const Left(
        ServerFailure('Invalid username or API key'),
      );
    } on DioException catch (e) {
      return Left(ServerFailure.fromDioError(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  /// Clears stored credentials.
  Future<void> logout() async {
    await _secureStorage.clearCredentials();
  }

  /// Retrieves previously saved credentials if present.
  Future<({String? username, String? apiKey})> getSavedCredentials() async {
    final username = await _secureStorage.getUsername();
    final apiKey = await _secureStorage.getApiKey();
    return (username: username, apiKey: apiKey);
  }
}
