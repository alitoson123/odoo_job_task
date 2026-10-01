import 'package:hive/hive.dart';
import '../../../../core/storage/hive_storage.dart';
import '../models/sale_order_details_model.dart';
import '../models/sale_order_model.dart';

/// Data source handling sales orders local caching in Hive.
class OrderLocalDataSource {
  final Box _ordersBox;

  OrderLocalDataSource([Box? ordersBox])
      : _ordersBox = ordersBox ?? HiveStorage.ordersBox;

  /// Caches a list of sales orders.
  Future<void> cacheOrders(List<SaleOrderModel> orders) async {
    for (final order in orders) {
      await _ordersBox.put('order_${order.id}', order.toJson());
    }
  }

  /// Retrieves cached sales orders sorted descending by date.
  List<SaleOrderModel> getCachedOrders() {
    final list = <SaleOrderModel>[];
    for (final key in _ordersBox.keys) {
      if (key.toString().startsWith('order_')) {
        final val = _ordersBox.get(key);
        if (val is Map) {
          list.add(SaleOrderModel.fromJson(Map<String, dynamic>.from(val)));
        }
      }
    }
    list.sort((a, b) {
      final da = a.dateOrder ?? '';
      final db = b.dateOrder ?? '';
      return db.compareTo(da);
    });
    return list;
  }

  /// Caches full details (header + lines) for an order.
  Future<void> cacheOrderDetails(
    SaleOrderModel order,
    List<SaleOrderDetailsModel> lines,
  ) async {
    final payload = {
      'order': order.toJson(),
      'lines': lines.map((l) => l.toJson()).toList(),
    };
    await _ordersBox.put('details_${order.id}', payload);
  }

  /// Retrieves cached order header and line items.
  ({SaleOrderModel order, List<SaleOrderDetailsModel> lines})?
      getCachedOrderDetails(int orderId) {
    final raw = _ordersBox.get('details_$orderId');
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      final orderMap = Map<String, dynamic>.from(map['order'] as Map);
      final linesList = (map['lines'] as List)
          .whereType<Map>()
          .map((l) => SaleOrderDetailsModel.fromJson(Map<String, dynamic>.from(l)))
          .toList();
      return (
        order: SaleOrderModel.fromJson(orderMap),
        lines: linesList,
      );
    }
    return null;
  }

  /// Returns true if cached orders exist.
  bool get hasCachedOrders => _ordersBox.isNotEmpty;
}
