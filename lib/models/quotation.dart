import 'line_item.dart';

enum QuoteStatus {
  draft,
  sent,
  approved,
  rejected,
}

class Quotation {
  const Quotation({
    required this.id,
    required this.garageId,
    required this.jobCardId,
    required this.customerId,
    required this.vehicleId,
    required this.quoteNumber,
    required this.status,
    required this.laborItems,
    required this.partItems,
    required this.vatEnabled,
    required this.vatRate,
    required this.subtotal,
    required this.vatAmount,
    required this.total,
    this.pdfPath,
    this.pdfWatermarked,
    this.approvalTokenId,
    this.approvedAt,
    this.rejectedAt,
    this.customerComment,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String garageId;
  final String jobCardId;
  final String customerId;
  final String vehicleId;
  final String quoteNumber;
  final QuoteStatus status;
  final List<LineItem> laborItems;
  final List<LineItem> partItems;
  final bool vatEnabled;
  final num vatRate;
  final num subtotal;
  final num vatAmount;
  final num total;
  final String? pdfPath;
  final bool? pdfWatermarked;
  final String? approvalTokenId;
  final DateTime? approvedAt;
  final DateTime? rejectedAt;
  final String? customerComment;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toMap({bool useIsoFormat = true}) {
    return {
      'id': id,
      'garageId': garageId,
      'jobCardId': jobCardId,
      'customerId': customerId,
      'vehicleId': vehicleId,
      'quoteNumber': quoteNumber,
      'status': _serializeStatus(status),
      'laborItems': laborItems.map((item) => item.toMap()).toList(),
      'partItems': partItems.map((item) => item.toMap()).toList(),
      'vatEnabled': vatEnabled,
      'vatRate': vatRate,
      'subtotal': subtotal,
      'vatAmount': vatAmount,
      'total': total,
      'pdf': _buildPdfMap(),
      'approval': _buildApprovalMap(useIsoFormat),
      'createdAt': _serializeDateTime(createdAt, useIsoFormat),
      'updatedAt': _serializeDateTime(updatedAt, useIsoFormat),
    }..removeWhere((key, value) => value == null);
  }

  factory Quotation.fromMap(Map<String, dynamic> map) {
    return Quotation(
      id: _requireString(map, 'id'),
      garageId: _requireString(map, 'garageId'),
      jobCardId: _requireString(map, 'jobCardId'),
      customerId: _requireString(map, 'customerId'),
      vehicleId: _requireString(map, 'vehicleId'),
      quoteNumber: _requireString(map, 'quoteNumber'),
      status: _parseQuoteStatus(_requireValue(map, 'status')),
      laborItems: _parseLineItems(map['laborItems']),
      partItems: _parseLineItems(map['partItems']),
      vatEnabled: _parseBool(map['vatEnabled'] ?? false),
      vatRate: _parseNum(map['vatRate'] ?? 0.05),
      subtotal: _parseNum(_requireValue(map, 'subtotal')),
      vatAmount: _parseNum(map['vatAmount'] ?? 0),
      total: _parseNum(_requireValue(map, 'total')),
      pdfPath: _parsePdfPath(map),
      pdfWatermarked: _parsePdfWatermarked(map),
      approvalTokenId: _parseApprovalField(map, 'tokenId') as String?,
      approvedAt: _parseApprovalDate(map, 'approvedAt'),
      rejectedAt: _parseApprovalDate(map, 'rejectedAt'),
      customerComment: _parseApprovalField(map, 'customerComment') as String?,
      createdAt: _parseDateTime(_requireValue(map, 'createdAt')),
      updatedAt: _parseDateTime(_requireValue(map, 'updatedAt')),
    );
  }

  Map<String, dynamic>? _buildPdfMap() {
    if (pdfPath == null && pdfWatermarked == null) return null;
    return {
      'storagePath': pdfPath,
      'watermarked': pdfWatermarked,
    }..removeWhere((key, value) => value == null);
  }

  Map<String, dynamic>? _buildApprovalMap(bool useIsoFormat) {
    if (approvalTokenId == null &&
        approvedAt == null &&
        rejectedAt == null &&
        customerComment == null) {
      return null;
    }
    return {
      'tokenId': approvalTokenId,
      'approvedAt': _serializeOptionalDateTime(approvedAt, useIsoFormat),
      'rejectedAt': _serializeOptionalDateTime(rejectedAt, useIsoFormat),
      'customerComment': customerComment,
    }..removeWhere((key, value) => value == null);
  }
}

List<LineItem> _parseLineItems(dynamic value) {
  if (value == null) return const [];
  if (value is List) {
    final result = <LineItem>[];
    for (final element in value) {
      if (element is LineItem) {
        result.add(element);
      } else if (element is Map<String, dynamic>) {
        result.add(LineItem.fromMap(element));
      } else if (element is Map) {
        result.add(LineItem.fromMap(Map<String, dynamic>.from(element)));
      } else {
        throw ArgumentError('Invalid line item element: $element');
      }
    }
    return List<LineItem>.unmodifiable(result);
  }
  throw ArgumentError('Invalid line items list: $value');
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

bool? _parsePdfWatermarked(Map<String, dynamic> map) {
  final pdf = map['pdf'];
  if (pdf is Map<String, dynamic>) {
    final value = pdf['watermarked'];
    if (value is bool) return value;
  }
  final direct = map['pdfWatermarked'];
  return direct is bool ? direct : null;
}

dynamic _parseApprovalField(Map<String, dynamic> map, String key) {
  final approval = map['approval'];
  if (approval is Map<String, dynamic>) {
    final value = approval[key];
    if (value != null) return value;
  }
  return map[key];
}

DateTime? _parseApprovalDate(Map<String, dynamic> map, String key) {
  final value = _parseApprovalField(map, key);
  if (value == null) return null;
  return _parseDateTime(value);
}

String _serializeStatus(QuoteStatus status) => status.name;

QuoteStatus _parseQuoteStatus(dynamic value) {
  if (value is QuoteStatus) return value;
  if (value is String) {
    switch (value) {
      case 'draft':
        return QuoteStatus.draft;
      case 'sent':
        return QuoteStatus.sent;
      case 'approved':
        return QuoteStatus.approved;
      case 'rejected':
        return QuoteStatus.rejected;
    }
  }
  throw ArgumentError('Invalid quotation status: $value');
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

bool _parseBool(dynamic value) {
  if (value is bool) return value;
  if (value is String) {
    if (value.toLowerCase() == 'true') return true;
    if (value.toLowerCase() == 'false') return false;
  }
  throw ArgumentError('Invalid boolean value: $value');
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

dynamic _serializeOptionalDateTime(DateTime? value, bool useIsoFormat) =>
    value == null ? null : _serializeDateTime(value, useIsoFormat);

DateTime _parseDateTime(dynamic value) {
  if (value is DateTime) return value;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is double) {
    return DateTime.fromMillisecondsSinceEpoch(value.round());
  }
  if (value is String) return DateTime.parse(value);
  throw ArgumentError('Invalid date value: $value');
}
