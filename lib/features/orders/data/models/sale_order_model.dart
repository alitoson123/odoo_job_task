/// Represents a sales order in Odoo (`sale.order`).
class SaleOrderModel {
  final int id;
  final String name;
  final int partnerId;
  final String partnerName;
  final String? dateOrder;
  final String state;
  final List<int> orderLineIds;
  final double amountUntaxed;
  final double amountTax;
  final double amountTotal;

  const SaleOrderModel({
    required this.id,
    required this.name,
    required this.partnerId,
    required this.partnerName,
    this.dateOrder,
    required this.state,
    this.orderLineIds = const [],
    this.amountUntaxed = 0.0,
    this.amountTax = 0.0,
    this.amountTotal = 0.0,
  });

  /// Factory constructor to parse Odoo JSON-2 dictionaries.
  factory SaleOrderModel.fromJson(Map<String, dynamic> json) {
    final partner = _parseMany2one(json['partner_id']);

    return SaleOrderModel(
      id: _parseInt(json['id']),
      name: _parseString(json['name']) ?? 'Unnamed Order',
      partnerId: partner.id,
      partnerName: partner.name.isEmpty ? 'Unknown Partner' : partner.name,
      dateOrder: _parseString(json['date_order']),
      state: _parseString(json['state']) ?? 'draft',
      orderLineIds: _parseIntList(json['order_line']),
      amountUntaxed: _parseDouble(json['amount_untaxed']),
      amountTax: _parseDouble(json['amount_tax']),
      amountTotal: _parseDouble(json['amount_total']),
    );
  }

  /// Serializes model to map for local caching.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'partner_id': [partnerId, partnerName],
      'date_order': dateOrder,
      'state': state,
      'order_line': orderLineIds,
      'amount_untaxed': amountUntaxed,
      'amount_tax': amountTax,
      'amount_total': amountTotal,
    };
  }

  /// Whether the order can be confirmed from draft or sent state.
  bool get isConfirmable => state == 'draft' || state == 'sent';

  /// Human-readable label corresponding to the Odoo order state.
  String get statusLabel {
    switch (state) {
      case 'draft':
        return 'Quotation';
      case 'sent':
        return 'Quotation Sent';
      case 'sale':
        return 'Confirmed';
      case 'done':
        return 'Locked';
      case 'cancel':
        return 'Cancelled';
      default:
        return state;
    }
  }

  /// Returns a copy of the model with updated state.
  SaleOrderModel copyWith({
    String? state,
  }) {
    return SaleOrderModel(
      id: id,
      name: name,
      partnerId: partnerId,
      partnerName: partnerName,
      dateOrder: dateOrder,
      state: state ?? this.state,
      orderLineIds: orderLineIds,
      amountUntaxed: amountUntaxed,
      amountTax: amountTax,
      amountTotal: amountTotal,
    );
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

  static List<int> _parseIntList(dynamic value) {
    if (value is List) {
      return value
          .map((e) => _parseInt(e))
          .where((id) => id > 0)
          .toList();
    }
    return const [];
  }
}
