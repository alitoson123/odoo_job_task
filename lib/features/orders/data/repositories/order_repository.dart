import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/services/network_info.dart';
import '../../../../core/services/odoo_client.dart';
import '../datasources/order_local_data_source.dart';
import '../models/sale_order_details_model.dart';
import '../models/sale_order_model.dart';

class OrderRepository {
  final OdooClient _odooClient;
  final OrderLocalDataSource? _localDataSource;
  final NetworkInfo? _networkInfo;
  bool isLastFetchOffline = false;

  OrderRepository({
    required OdooClient odooClient,
    OrderLocalDataSource? localDataSource,
    NetworkInfo? networkInfo,
  })  : _odooClient = odooClient,
        _localDataSource = localDataSource,
        _networkInfo = networkInfo;

  /// Fetches sales orders, falling back to cache if offline.
  Future<Either<Failure, List<SaleOrderModel>>> getOrders() async {
    if (_networkInfo != null && !await _networkInfo.isConnected) {
      return _readCachedOrders();
    }
    try {
      final dynamic res = await _odooClient.callRpc(
        model: 'sale.order',
        method: 'search_read',
        body: {'fields': ['name', 'partner_id', 'date_order', 'state'], 'order': 'date_order desc'},
      );
      if (res is List) {
        final orders = res.whereType<Map<String, dynamic>>().map(SaleOrderModel.fromJson).toList();
        isLastFetchOffline = false;
        await _localDataSource?.cacheOrders(orders);
        return Right(orders);
      }
      return const Left(ServerFailure('Invalid response from server.'));
    } on DioException catch (e) {
      if (e.isNetworkError && _hasCache) return _readCachedOrders();
      return Left(ServerFailure.fromDioError(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  /// Fetches order header and corresponding order line items.
  Future<Either<Failure, ({SaleOrderModel order, List<SaleOrderDetailsModel> lines})>>
      getOrderDetails(int orderId) async {
    if (_networkInfo != null && !await _networkInfo.isConnected) {
      return _readCachedOrderDetails(orderId);
    }
    try {
      final dynamic orderRes = await _odooClient.callRpc(
        model: 'sale.order',
        method: 'read',
        body: {'ids': [orderId], 'fields': ['name', 'partner_id', 'date_order', 'state', 'order_line', 'amount_untaxed', 'amount_tax', 'amount_total']},
      );
      if (orderRes is! List || orderRes.isEmpty) {
        return const Left(ServerFailure('Order details not found.'));
      }
      final order = SaleOrderModel.fromJson(orderRes.first as Map<String, dynamic>);
      final lines = await _fetchOrderLines(order.orderLineIds);
      isLastFetchOffline = false;
      await _localDataSource?.cacheOrderDetails(order, lines);
      return Right((order: order, lines: lines));
    } on DioException catch (e) {
      if (e.isNetworkError) return _readCachedOrderDetails(orderId);
      return Left(ServerFailure.fromDioError(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  /// Confirms a quotation / sales order (`sale.order/action_confirm`).
  Future<Either<Failure, bool>> confirmOrder(int orderId) async {
    try {
      await _odooClient.callRpc(
        model: 'sale.order',
        method: 'action_confirm',
        body: {'ids': [orderId]},
      );
      return const Right(true);
    } on DioException catch (e) {
      return Left(ServerFailure.fromDioError(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  /// Checks whether a user belongs to `base.group_user`, caching permission for offline use.
  Future<Either<Failure, bool>> checkIsInternalUser(int userId) async {
    if (_networkInfo != null && !await _networkInfo.isConnected) {
      return _readCachedIsInternalUser(userId);
    }
    try {
      final dynamic res = await _odooClient.callRpc(
        model: 'res.users',
        method: 'has_group',
        body: {'ids': [userId], 'group_ext_id': 'base.group_user'},
      );
      if (res is bool) {
        await _localDataSource?.cacheIsInternalUser(userId, res);
        return Right(res);
      }
      return const Left(ServerFailure('Invalid response from server.'));
    } on DioException catch (e) {
      if (e.isNetworkError) return _readCachedIsInternalUser(userId);
      return Left(ServerFailure.fromDioError(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<List<SaleOrderDetailsModel>> _fetchOrderLines(List<int> ids) async {
    if (ids.isEmpty) return const [];
    final dynamic res = await _odooClient.callRpc(
      model: 'sale.order.line',
      method: 'read',
      body: {'ids': ids, 'fields': ['product_id', 'name', 'product_uom_qty', 'price_unit', 'price_subtotal']},
    );
    if (res is! List) return const [];
    return res.whereType<Map<String, dynamic>>().map(SaleOrderDetailsModel.fromJson).toList();
  }

  bool get _hasCache => _localDataSource?.hasCachedOrders == true;

  Either<Failure, List<SaleOrderModel>> _readCachedOrders() {
    if (!_hasCache) return const Left(ServerFailure('Offline: No cached orders.'));
    isLastFetchOffline = true;
    return Right(_localDataSource!.getCachedOrders());
  }

  Either<Failure, ({SaleOrderModel order, List<SaleOrderDetailsModel> lines})>
      _readCachedOrderDetails(int id) {
    final c = _localDataSource?.getCachedOrderDetails(id);
    if (c != null) {
      isLastFetchOffline = true;
      return Right(c);
    }
    return const Left(ServerFailure('Offline: No cached details for order.'));
  }

  Either<Failure, bool> _readCachedIsInternalUser(int userId) {
    final cached = _localDataSource?.getCachedIsInternalUser(userId);
    if (cached != null) return Right(cached);
    if (_localDataSource?.hasCachedOrders == true) return const Right(true);
    return const Left(ServerFailure('Offline: User permissions unavailable.'));
  }
}
