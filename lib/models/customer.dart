class Customer {
  const Customer({
    required this.id,
    required this.garageId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String garageId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toMap({bool asIsoStrings = true}) {
    return {
      'id': id,
      'garageId': garageId,
      'createdAt':
          asIsoStrings ? createdAt.toIso8601String() : createdAt.millisecondsSinceEpoch,
      'updatedAt':
          asIsoStrings ? updatedAt.toIso8601String() : updatedAt.millisecondsSinceEpoch,
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as String,
      garageId: map['garageId'] as String,
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
    );
  }
}

DateTime _parseDateTime(dynamic value) {
  if (value is DateTime) return value;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is double) return DateTime.fromMillisecondsSinceEpoch(value.round());
  if (value is String) return DateTime.parse(value);
  throw ArgumentError('Invalid date value: $value');
}
