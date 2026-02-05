class Vehicle {
  const Vehicle({
    required this.id,
    required this.garageId,
    required this.customerId,
    required this.plateNumber,
    this.make,
    this.model,
    this.year,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String garageId;
  final String customerId;
  final String plateNumber;
  final String? make;
  final String? model;
  final int? year;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toMap({bool asIsoStrings = true}) {
    return {
      'id': id,
      'garageId': garageId,
      'customerId': customerId,
      'plateNumber': plateNumber,
      'make': make,
      'model': model,
      'year': year,
      'createdAt':
          asIsoStrings ? createdAt.toIso8601String() : createdAt.millisecondsSinceEpoch,
      'updatedAt':
          asIsoStrings ? updatedAt.toIso8601String() : updatedAt.millisecondsSinceEpoch,
    };
  }

  factory Vehicle.fromMap(Map<String, dynamic> map) {
    return Vehicle(
      id: map['id'] as String,
      garageId: map['garageId'] as String,
      customerId: map['customerId'] as String,
      plateNumber: map['plateNumber'] as String,
      make: map['make'] as String?,
      model: map['model'] as String?,
      year: _parseYear(map['year']),
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
    );
  }
}

DateTime _parseDateTime(dynamic value) {
  if (value is DateTime) return value;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is double) return DateTime.fromMillisecondsSinceEpoch(value.toInt());
  if (value is String) return DateTime.parse(value);
  throw ArgumentError('Invalid date value: $value');
}

int? _parseYear(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  throw ArgumentError('Invalid year value: $value');
}
