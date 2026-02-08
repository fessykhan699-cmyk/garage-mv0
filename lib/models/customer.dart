class Customer {
  const Customer({
    required this.id,
    required this.garageId,
    required this.name,
    required this.phone,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String garageId;
  final String name;
  final String phone;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toMap({bool useIsoFormat = true}) {
    return {
      'id': id,
      'garageId': garageId,
      'name': name,
      'phone': phone,
      'notes': notes,
      'createdAt': _serializeDateTime(createdAt, useIsoFormat),
      'updatedAt': _serializeDateTime(updatedAt, useIsoFormat),
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as String,
      garageId: map['garageId'] as String,
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      notes: map['notes'] as String?,
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
    );
  }
}

dynamic _serializeDateTime(DateTime value, bool useIsoFormat) =>
    useIsoFormat ? value.toIso8601String() : value.millisecondsSinceEpoch;

DateTime _parseDateTime(dynamic value) {
  if (value is DateTime) return value;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is double) {
    // Some JSON serializers may emit fractional milliseconds; round to nearest ms.
    return DateTime.fromMillisecondsSinceEpoch(value.round());
  }
  if (value is String) return DateTime.parse(value);
  throw ArgumentError('Invalid date value: $value');
}
