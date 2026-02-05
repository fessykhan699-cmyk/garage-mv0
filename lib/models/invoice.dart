enum InvoiceStatus {
  unpaid,
  partial,
  paid,
}

class Invoice {
  const Invoice({
    required this.id,
    required this.garageId,
    required this.quotationId,
    required this.jobCardId,
    required this.customerId,
    required this.vehicleId,
    required this.invoiceNumber,
    required this.status,
    required this.subtotal,
    required this.vatAmount,
    required this.total,
    required this.amountPaid,
    required this.balanceDue,
    this.pdfPath,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String garageId;
  final String quotationId;
  final String jobCardId;
  final String customerId;
  final String vehicleId;
  final String invoiceNumber;
  final InvoiceStatus status;
  final num subtotal;
  final num vatAmount;
  final num total;
  final num amountPaid;
  final num balanceDue;
  final String? pdfPath;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toMap({bool useIsoFormat = true}) {
    return {
      'id': id,
      'garageId': garageId,
      'quotationId': quotationId,
      'jobCardId': jobCardId,
      'customerId': customerId,
      'vehicleId': vehicleId,
      'invoiceNumber': invoiceNumber,
      'status': _serializeStatus(status),
      'subtotal': subtotal,
      'vatAmount': vatAmount,
      'total': total,
      'amountPaid': amountPaid,
      'balanceDue': balanceDue,
      'pdf': _buildPdfMap(pdfPath),
      'createdAt': _serializeDateTime(createdAt, useIsoFormat),
      'updatedAt': _serializeDateTime(updatedAt, useIsoFormat),
    }..removeWhere((key, value) => value == null);
  }

  factory Invoice.fromMap(Map<String, dynamic> map) {
    return Invoice(
      id: _requireString(map, 'id'),
      garageId: _requireString(map, 'garageId'),
      quotationId: _requireString(map, 'quotationId'),
      jobCardId: _requireString(map, 'jobCardId'),
      customerId: _requireString(map, 'customerId'),
      vehicleId: _requireString(map, 'vehicleId'),
      invoiceNumber: _requireString(map, 'invoiceNumber'),
      status: _parseStatus(_requireValue(map, 'status')),
      subtotal: _parseNum(_requireValue(map, 'subtotal')),
      vatAmount: _parseNum(map['vatAmount'] ?? 0),
      total: _parseNum(_requireValue(map, 'total')),
      amountPaid: _parseNum(map['amountPaid'] ?? 0),
      balanceDue: _parseNum(map['balanceDue'] ?? 0),
      pdfPath: _parsePdfPath(map),
      createdAt: _parseDateTime(_requireValue(map, 'createdAt')),
      updatedAt: _parseDateTime(_requireValue(map, 'updatedAt')),
    );
  }
}

Map<String, dynamic>? _buildPdfMap(String? pdfPath) {
  if (pdfPath == null) return null;
  return {'storagePath': pdfPath};
}

String? _parsePdfPath(Map<String, dynamic> map) {
  final pdf = map['pdf'];
  if (pdf is Map<String, dynamic>) {
    final storagePath = pdf['storagePath'];
    if (storagePath is String) return storagePath;
    final downloadUrl = pdf['downloadUrl'];
    if (downloadUrl is String) return downloadUrl;
  }
  final directPath = map['pdfPath'];
  return directPath is String ? directPath : null;
}

String _serializeStatus(InvoiceStatus status) => status.name;

InvoiceStatus _parseStatus(dynamic value) {
  if (value is InvoiceStatus) return value;
  if (value is String) {
    switch (value) {
      case 'unpaid':
        return InvoiceStatus.unpaid;
      case 'partial':
        return InvoiceStatus.partial;
      case 'paid':
        return InvoiceStatus.paid;
    }
  }
  throw ArgumentError('Invalid invoice status: $value');
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
