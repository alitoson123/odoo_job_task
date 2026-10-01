import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/services/network_info.dart';
import '../../../../core/services/odoo_client.dart';
import '../datasources/customer_local_data_source.dart';
import '../models/customer_model.dart';

class CustomerRepository {
  final OdooClient _odooClient;
  final CustomerLocalDataSource? _localDataSource;
  final NetworkInfo? _networkInfo;
  bool isLastFetchOffline = false;

  CustomerRepository({
    required OdooClient odooClient,
    CustomerLocalDataSource? localDataSource,
    NetworkInfo? networkInfo,
  })  : _odooClient = odooClient,
        _localDataSource = localDataSource,
        _networkInfo = networkInfo;

  /// Fetches customers, serving from Hive cache if offline.
  Future<Either<Failure, List<CustomerModel>>> getCustomers({
    String? searchQuery,
  }) async {
    if (_networkInfo != null && !await _networkInfo.isConnected) {
      return _readCachedList(searchQuery);
    }
    try {
      final dynamic response = await _odooClient.callRpc(
        model: 'res.partner',
        method: 'search_read',
        body: {
          'domain': [
            ['customer_rank', '>', 0],
            if (searchQuery?.trim().isNotEmpty == true)
              ['name', 'ilike', searchQuery!.trim()],
          ],
          'fields': ['id', 'name', 'phone', 'city'],
          'order': 'name asc',
        },
      );
      if (response is List) {
        final list = response
            .whereType<Map<String, dynamic>>()
            .map(CustomerModel.fromJson)
            .toList();
        isLastFetchOffline = false;
        await _localDataSource?.cacheCustomers(list);
        return Right(list);
      }
      return const Left(ServerFailure('Invalid response from server.'));
    } on DioException catch (e) {
      if (e.isNetworkError && _hasCache) return _readCachedList(searchQuery);
      return Left(ServerFailure.fromDioError(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  /// Fetches customer details, falling back to cache if offline.
  Future<Either<Failure, CustomerModel>> getCustomerDetails(int id) async {
    if (_networkInfo != null && !await _networkInfo.isConnected) {
      return _readCachedDetails(id);
    }
    try {
      final dynamic response = await _odooClient.callRpc(
        model: 'res.partner',
        method: 'read',
        body: {
          'ids': [id],
          'fields': [
            'name', 'phone', 'email', 'street',
            'street2', 'city', 'zip', 'country_id',
          ],
        },
      );
      if (response is List && response.isNotEmpty) {
        final first = response.first;
        if (first is Map<String, dynamic>) {
          final customer = CustomerModel.fromJson(first);
          isLastFetchOffline = false;
          await _localDataSource?.cacheCustomerDetails(customer);
          return Right(customer);
        }
      }
      return const Left(ServerFailure('Customer details not found.'));
    } on DioException catch (e) {
      if (e.isNetworkError) return _readCachedDetails(id);
      return Left(ServerFailure.fromDioError(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  /// Updates phone in Odoo or queues offline if network is unreachable.
  Future<Either<Failure, bool>> updateCustomerPhone({
    required int customerId,
    required String newPhone,
  }) async {
    if (_networkInfo != null && !await _networkInfo.isConnected) {
      return _queueOfflinePhone(customerId, newPhone);
    }
    try {
      final dynamic res = await _odooClient.callRpc(
        model: 'res.partner',
        method: 'write',
        body: {'ids': [customerId], 'vals': {'phone': newPhone.trim()}},
      );
      if (res == true) {
        await _localDataSource?.updateCustomerPhoneLocally(
          customerId: customerId,
          newPhone: newPhone,
        );
        return const Right(true);
      }
      return const Left(ServerFailure('Failed to update phone number.'));
    } on DioException catch (e) {
      if (e.isNetworkError) return _queueOfflinePhone(customerId, newPhone);
      return Left(ServerFailure.fromDioError(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<Either<Failure, bool>> _queueOfflinePhone(int id, String phone) async {
    await _localDataSource?.updateCustomerPhoneLocally(customerId: id, newPhone: phone);
    await _localDataSource?.addPendingOperation(partnerId: id, field: 'phone', value: phone);
    return const Right(false);
  }

  bool get _hasCache => _localDataSource?.hasCachedCustomers == true;

  Either<Failure, List<CustomerModel>> _readCachedList(String? query) {
    if (!_hasCache) {
      return const Left(ServerFailure('Offline mode: No cached customers.'));
    }
    isLastFetchOffline = true;
    return Right(_localDataSource!.getCachedCustomers(searchQuery: query));
  }

  Either<Failure, CustomerModel> _readCachedDetails(int id) {
    final cached = _localDataSource?.getCachedCustomer(id);
    if (cached != null) {
      isLastFetchOffline = true;
      return Right(cached);
    }
    return const Left(ServerFailure('Offline mode: No cached details.'));
  }
}
