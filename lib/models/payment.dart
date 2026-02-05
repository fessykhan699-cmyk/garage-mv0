enum PaymentMethod {
  cash,
  card,
  bank,
}

class Payment {
  const Payment({
    required this.id,
    required this.garageId,
    required this.invoiceId,
    required this.amount,
    required this.method,
    required this.paidAt,
    this.note,
    required this.createdAt,
  });

  final String id;
  final String garageId;
  final String invoiceId;
  final num amount;
  final PaymentMethod method;
  final DateTime paidAt;
  final String? note;
  final DateTime createdAt;

  Map<String, dynamic> toMap({bool useIsoFormat = true}) {
    return {
      'id': id,
      'garageId': garageId,
      'invoiceId': invoiceId,
      'amount': amount,
      'method': _serializeMethod(method),
      'paidAt': _serializeDateTime(paidAt, useIsoFormat),
      'note': note,
      'createdAt': _serializeDateTime(createdAt, useIsoFormat),
    }..removeWhere((key, value) => value == null);
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: _requireString(map, 'id'),
      garageId: _requireString(map, 'garageId'),
      invoiceId: _requireString(map, 'invoiceId'),
      amount: _parseNum(_requireValue(map, 'amount')),
      method: _parseMethod(_requireValue(map, 'method')),
      paidAt: _parseDateTime(_requireValue(map, 'paidAt')),
      note: map['note'] as String?,
      createdAt: _parseDateTime(_requireValue(map, 'createdAt')),
    );
  }
}

String _serializeMethod(PaymentMethod method) => method.name;

PaymentMethod _parseMethod(dynamic value) {
  if (value is PaymentMethod) return value;
  if (value is String) {
    switch (value) {
      case 'cash':
        return PaymentMethod.cash;
      case 'card':
        return PaymentMethod.card;
      case 'bank':
        return PaymentMethod.bank;
    }
  }
  throw ArgumentError('Invalid payment method: $value');
}

String _requireString(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value is String) return value;
  if (value == null) {
    throw ArgumentError('Missing required field: $key');
  }
  throw ArgumentError('Required field $key must be a String');
}

dynamic _requireValue(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value != null) return value;
  throw ArgumentError('Missing required field: $key');
}

num _parseNum(dynamic value) {
  if (value is num) return value;
  if (value is String) {
    final parsed = num.tryParse(value);
    if (parsed != null) return parsed;
  }
  throw ArgumentError('Invalid numeric value: $value');
}

dynamic _serializeDateTime(DateTime value, bool useIsoFormat) =>
    useIsoFormat ? value.toIso8601String() : value.millisecondsSinceEpoch;

DateTime _parseDateTime(dynamic value) {
  if (value is DateTime) return value;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is double) {
    return DateTime.fromMillisecondsSinceEpoch(value.round());
  }
  if (value is String) return DateTime.parse(value);
  throw ArgumentError('Invalid date value: $value');
}
