import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_task/core/services/odoo_client.dart';

void main() {
  late Dio dio;
  late OdooClient odooClient;
  bool sessionExpiredCalled = false;

  setUp(() {
    sessionExpiredCalled = false;
    dio = Dio(BaseOptions(baseUrl: 'https://test.odoo.com'));
    odooClient = OdooClient(
      dio: dio,
      onSessionExpired: () => sessionExpiredCalled = true,
    );
  });

  group('OdooClient', () {
    test('callRpc returns response data on successful 200 response', () async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: [{'id': 2, 'name': 'Mitchell Admin', 'login': 'admin'}],
              ),
            );
          },
        ),
      );

      final result = await odooClient.callRpc(
        model: 'res.users',
        method: 'search_read',
        body: {'domain': [['login', '=', 'admin']]},
        apiKey: 'test_key',
      );

      expect(result, isA<List>());
      expect((result as List).first['name'], equals('Mitchell Admin'));
    });

    test('callRpc throws DioException and triggers callback on 401', () async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            return handler.reject(
              DioException(
                requestOptions: options,
                response: Response(
                  requestOptions: options,
                  statusCode: 401,
                  data: {'message': 'Invalid API Key'},
                ),
              ),
            );
          },
        ),
      );

      await expectLater(
        () => odooClient.callRpc(
          model: 'res.users',
          method: 'search_read',
          body: {},
          apiKey: 'wrong_key',
        ),
        throwsA(isA<DioException>()),
      );
      expect(sessionExpiredCalled, isTrue);
    });

    test('callRpc rethrows DioException on connection timeout', () async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            return handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.connectionTimeout,
              ),
            );
          },
        ),
      );

      await expectLater(
        () => odooClient.callRpc(
          model: 'res.users',
          method: 'search_read',
          body: {},
        ),
        throwsA(isA<DioException>()),
      );
    });
  });
}
