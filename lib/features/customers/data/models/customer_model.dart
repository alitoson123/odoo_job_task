/// Represents an Odoo customer partner (`res.partner`).
class CustomerModel {
  final int id;
  final String name;
  final String? phone;
  final String? email;
  final String? street;
  final String? street2;
  final String? city;
  final String? zip;
  final String? countryName;
  final bool isPendingSync;

  const CustomerModel({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.street,
    this.street2,
    this.city,
    this.zip,
    this.countryName,
    this.isPendingSync = false,
  });

  /// Factory constructor to parse Odoo JSON-2 responses safely.
  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: _parseId(json['id']),
      name: _parseString(json['name']) ?? 'Unnamed Customer',
      phone: _parseString(json['phone']),
      email: _parseString(json['email']),
      street: _parseString(json['street']),
      street2: _parseString(json['street2']),
      city: _parseString(json['city']),
      zip: _parseString(json['zip']),
      countryName: _parseMany2one(json['country_id']),
      isPendingSync: json['is_pending_sync'] as bool? ?? false,
    );
  }

  /// Serializes customer to Map for Hive caching.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'street': street,
      'street2': street2,
      'city': city,
      'zip': zip,
      'country_id': countryName != null ? [0, countryName] : false,
      'is_pending_sync': isPendingSync,
    };
  }

  /// Composes a formatted multi-part address line.
  String get displayAddress {
    final parts = [street, street2, city, zip, countryName]
        .where((part) => part != null && part.trim().isNotEmpty)
        .cast<String>()
        .toList();

    return parts.isEmpty ? 'No address provided' : parts.join(', ');
  }

  /// Returns a copy of the customer with updated fields.
  CustomerModel copyWith({
    int? id,
    String? name,
    String? phone,
    String? email,
    String? street,
    String? street2,
    String? city,
    String? zip,
    String? countryName,
    bool? isPendingSync,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      street: street ?? this.street,
      street2: street2 ?? this.street2,
      city: city ?? this.city,
      zip: zip ?? this.zip,
      countryName: countryName ?? this.countryName,
      isPendingSync: isPendingSync ?? this.isPendingSync,
    );
  }

  static int _parseId(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String? _parseString(dynamic value) {
    if (value == null || value == false) return null;
    final str = value.toString().trim();
    return str.isEmpty ? null : str;
  }

  static String? _parseMany2one(dynamic value) {
    if (value is List && value.length >= 2) {
      final name = value[1];
      if (name is String && name.trim().isNotEmpty) {
        return name.trim();
      }
    }
    return null;
  }
}
