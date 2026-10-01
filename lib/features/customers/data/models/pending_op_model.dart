/// Represents a queued offline operation awaiting synchronization.
class PendingOp {
  final dynamic key;
  final int partnerId;
  final String field;
  final String value;
  final int timestamp;

  const PendingOp({
    this.key,
    required this.partnerId,
    required this.field,
    required this.value,
    required this.timestamp,
  });

  /// Factory constructor to parse stored map data from Hive.
  factory PendingOp.fromMap(dynamic key, Map<dynamic, dynamic> map) {
    return PendingOp(
      key: key,
      partnerId: map['partnerId'] as int,
      field: map['field'] as String,
      value: map['value'] as String,
      timestamp: map['timestamp'] as int? ?? 0,
    );
  }

  /// Serializes operation to map for Hive storage.
  Map<String, dynamic> toMap() {
    return {
      'partnerId': partnerId,
      'field': field,
      'value': value,
      'timestamp': timestamp,
    };
  }
}
