enum ApprovalStatus {
  pending,
  approved,
  rejected,
}

class ApprovalToken {
  ApprovalToken({
    required this.id,
    required this.garageId,
    required this.quotationId,
    this.status = ApprovalStatus.pending,
    this.customerComment,
    this.createdAt,
    this.decidedAt,
    this.expiresAt,
    this.used = false,
    this.usedAt,
  });

  final String id;
  final String garageId;
  final String quotationId;
  final ApprovalStatus status;
  final String? customerComment;
  final DateTime? createdAt;
  final DateTime? decidedAt;
  final DateTime? expiresAt;
  final bool used;
  final DateTime? usedAt;

  ApprovalToken copyWith({
    ApprovalStatus? status,
    String? customerComment,
    DateTime? decidedAt,
    DateTime? expiresAt,
    bool? used,
    DateTime? usedAt,
  }) {
    return ApprovalToken(
      id: id,
      garageId: garageId,
      quotationId: quotationId,
      status: status ?? this.status,
      customerComment: customerComment ?? this.customerComment,
      createdAt: createdAt,
      decidedAt: decidedAt ?? this.decidedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      used: used ?? this.used,
      usedAt: usedAt ?? this.usedAt,
    );
  }

  Map<String, dynamic> toMap({bool useIsoFormat = true}) {
    return {
      'id': id,
      'garageId': garageId,
      'quotationId': quotationId,
      'status': status.name,
      'customerComment': customerComment,
      'createdAt': _serializeOptionalDateTime(createdAt, useIsoFormat),
      'decidedAt': _serializeOptionalDateTime(decidedAt, useIsoFormat),
      'expiresAt': _serializeOptionalDateTime(expiresAt, useIsoFormat),
      'used': used,
      'usedAt': _serializeOptionalDateTime(usedAt, useIsoFormat),
    }..removeWhere((key, value) => value == null);
  }

  factory ApprovalToken.fromMap(Map<String, dynamic> map) {
    return ApprovalToken(
      id: _requireString(map, 'id'),
      garageId: _requireString(map, 'garageId'),
      quotationId: _requireString(map, 'quotationId'),
      status: _parseStatus(map['status']),
      customerComment: map['customerComment'] as String?,
      createdAt: _parseDateTime(map['createdAt']),
      decidedAt: _parseDateTime(map['decidedAt']),
      expiresAt: _parseDateTime(map['expiresAt']),
      used: map['used'] == true,
      usedAt: _parseDateTime(map['usedAt']),
    );
  }
}

abstract class ApprovalRepository {
  Future<ApprovalToken> create(ApprovalToken token);
  Future<ApprovalToken?> fetch(String tokenId);
  Stream<ApprovalToken?> watch(String tokenId);
  Future<void> update(ApprovalToken token);
  Future<void> delete(String tokenId);
}

ApprovalStatus _parseStatus(dynamic value) {
  if (value is ApprovalStatus) return value;
  if (value is String) {
    switch (value) {
      case 'pending':
        return ApprovalStatus.pending;
      case 'approved':
        return ApprovalStatus.approved;
      case 'rejected':
        return ApprovalStatus.rejected;
    }
  }
  throw ArgumentError('Invalid approval status: $value');
}

String _requireString(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value is String) return value;
  if (value == null) throw ArgumentError('Missing required field: $key');
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

dynamic _serializeOptionalDateTime(DateTime? value, bool useIsoFormat) =>
    value == null
        ? null
        : (useIsoFormat ? value.toIso8601String() : value.millisecondsSinceEpoch);
