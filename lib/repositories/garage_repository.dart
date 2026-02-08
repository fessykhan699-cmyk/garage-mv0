class Garage {
  Garage({
    required this.id,
    this.name,
    this.phone,
    this.email,
    this.address,
    this.trn,
    this.logoUrl,
    String plan = _defaultPlan,
    this.planActivatedAt,
    this.planExpiresAt,
    Map<String, int>? usage,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : plan = plan.isEmpty ? _defaultPlan : plan,
        usage = _normalizeUsage(usage),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final String? name;
  final String? phone;
  final String? email;
  final String? address;
  final String? trn;
  final String? logoUrl;
  final String plan;
  final DateTime? planActivatedAt;
  final DateTime? planExpiresAt;
  final Map<String, int> usage;
  final DateTime createdAt;
  final DateTime updatedAt;

  Garage copyWith({
    String? name,
    String? phone,
    String? email,
    String? address,
    String? trn,
    String? logoUrl,
    String? plan,
    DateTime? planActivatedAt,
    DateTime? planExpiresAt,
    Map<String, int>? usage,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Garage(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      trn: trn ?? this.trn,
      logoUrl: logoUrl ?? this.logoUrl,
      plan: plan ?? this.plan,
      planActivatedAt: planActivatedAt ?? this.planActivatedAt,
      planExpiresAt: planExpiresAt ?? this.planExpiresAt,
      usage: usage ?? this.usage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Garage incrementUsage({
    int jobCardsCreated = 0,
    int pdfExports = 0,
    int approvalsCreated = 0,
    int invoicesCreated = 0,
  }) {
    return copyWith(
      usage: {
        ...this.usage,
        'jobCardsCreated': (usage['jobCardsCreated'] ?? 0) + jobCardsCreated,
        'pdfExports': (usage['pdfExports'] ?? 0) + pdfExports,
        'approvalsCreated': (usage['approvalsCreated'] ?? 0) + approvalsCreated,
        'invoicesCreated': (usage['invoicesCreated'] ?? 0) + invoicesCreated,
      },
    );
  }

  Map<String, dynamic> toMap({bool useIsoFormat = true}) {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'trn': trn,
      'logoUrl': logoUrl,
      'plan': plan,
      'planActivatedAt': _serializeOptionalDateTime(
        planActivatedAt,
        useIsoFormat,
      ),
      'planExpiresAt': _serializeOptionalDateTime(
        planExpiresAt,
        useIsoFormat,
      ),
      'usage': usage,
      'createdAt': _serializeDateTime(createdAt, useIsoFormat),
      'updatedAt': _serializeDateTime(updatedAt, useIsoFormat),
    }..removeWhere((key, value) => value == null);
  }

  factory Garage.fromMap(Map<String, dynamic> map) {
    return Garage(
      id: _requireString(map, 'id'),
      name: map['name'] as String?,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      address: map['address'] as String?,
      trn: map['trn'] as String?,
      logoUrl: map['logoUrl'] as String?,
      plan: map['plan'] as String? ?? _defaultPlan,
      planActivatedAt: _parseDateTime(map['planActivatedAt']),
      planExpiresAt: _parseDateTime(map['planExpiresAt']),
      usage: _normalizeUsage(_parseUsage(map['usage'])),
      createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(map['updatedAt']) ?? DateTime.now(),
    );
  }
}

abstract class GarageRepository {
  Future<Garage> createGarage(Garage garage);
  Future<Garage?> fetchGarage(String garageId);
  Stream<Garage?> watchGarage(String garageId);
  Future<void> updateGarage(Garage garage);
  Future<void> updatePlan(String garageId, String plan);
  Future<void> incrementUsage(
    String garageId, {
    int jobCardsCreated = 0,
    int pdfExports = 0,
    int approvalsCreated = 0,
    int invoicesCreated = 0,
  });
}

const _defaultPlan = 'free';

Map<String, int> _normalizeUsage(Map<String, int>? usage) {
  const defaults = <String, int>{
    'jobCardsCreated': 0,
    'pdfExports': 0,
    'approvalsCreated': 0,
    'invoicesCreated': 0,
  };
  if (usage == null) return defaults;
  final merged = {...defaults};
  for (final entry in usage.entries) {
    merged[entry.key] = entry.value;
  }
  return merged;
}

Map<String, int>? _parseUsage(dynamic value) {
  if (value == null) return null;
  if (value is Map) {
    return value.map((key, dynamic v) => MapEntry(key.toString(), (v as num).toInt()));
  }
  throw ArgumentError('Invalid usage map: $value');
}

String _requireString(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value is String) return value;
  if (value == null) {
    throw ArgumentError('Missing required field: $key');
  }
  throw ArgumentError('Required field $key must be a String');
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is double) {
    return DateTime.fromMillisecondsSinceEpoch(value.round());
  }
  if (value is String && value.isNotEmpty) return DateTime.parse(value);
  return null;
}

dynamic _serializeDateTime(DateTime value, bool useIsoFormat) =>
    useIsoFormat ? value.toIso8601String() : value.millisecondsSinceEpoch;

dynamic _serializeOptionalDateTime(DateTime? value, bool useIsoFormat) =>
    value == null ? null : _serializeDateTime(value, useIsoFormat);
