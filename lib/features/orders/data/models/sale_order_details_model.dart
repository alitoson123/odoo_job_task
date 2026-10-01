/// Represents a sales order line item in Odoo (`sale.order.line`).
class SaleOrderDetailsModel {
  final int id;
  final int productId;
  final String productName;
  final String name;
  final double productUomQty;
  final double priceUnit;
  final double priceSubtotal;

  const SaleOrderDetailsModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.name,
    required this.productUomQty,
    required this.priceUnit,
    required this.priceSubtotal,
  });

  /// Factory constructor to parse Odoo JSON-2 responses safely.
  factory SaleOrderDetailsModel.fromJson(Map<String, dynamic> json) {
    final product = _parseMany2one(json['product_id']);

    return SaleOrderDetailsModel(
      id: _parseInt(json['id']),
      productId: product.id,
      productName: product.name.isEmpty ? 'Product' : product.name,
      name: _parseString(json['name']) ?? 'Product Item',
      productUomQty: _parseDouble(json['product_uom_qty']),
      priceUnit: _parseDouble(json['price_unit']),
      priceSubtotal: _parseDouble(json['price_subtotal']),
    );
  }

  /// Serializes model to map for local caching.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': [productId, productName],
      'name': name,
      'product_uom_qty': productUomQty,
      'price_unit': priceUnit,
      'price_subtotal': priceSubtotal,
    };
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  static String? _parseString(dynamic value) {
    if (value == null || value == false) return null;
    final str = value.toString().trim();
    return str.isEmpty ? null : str;
  }

  static ({int id, String name}) _parseMany2one(dynamic value) {
    if (value is List && value.isNotEmpty) {
      final id = _parseInt(value[0]);
      final name = value.length > 1 ? _parseString(value[1]) ?? '' : '';
      return (id: id, name: name);
    }
    return (id: 0, name: '');
  }
}
