enum JobCardStatus {
  draft,
  awaitingApproval,
  approved,
  inProgress,
  ready,
  closed,
}

class JobCard {
  const JobCard({
    required this.id,
    required this.garageId,
    required this.customerId,
    required this.vehicleId,
    required this.jobCardNumber,
    required this.complaint,
    this.notes,
    this.beforePhotoPaths = const [],
    this.afterPhotoPaths = const [],
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String garageId;
  final String customerId;
  final String vehicleId;
  final String jobCardNumber;
  final String complaint;
  final String? notes;
  final List<String> beforePhotoPaths;
  final List<String> afterPhotoPaths;
  final JobCardStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toMap({bool useIsoFormat = true}) {
    return {
      'id': id,
      'garageId': garageId,
      'customerId': customerId,
      'vehicleId': vehicleId,
      'jobCardNumber': jobCardNumber,
      'complaint': complaint,
      'notes': notes,
      'beforePhotoPaths': beforePhotoPaths,
      'afterPhotoPaths': afterPhotoPaths,
      'status': _serializeStatus(status),
      'createdAt': _serializeDateTime(createdAt, useIsoFormat),
      'updatedAt': _serializeDateTime(updatedAt, useIsoFormat),
    };
  }

  factory JobCard.fromMap(Map<String, dynamic> map) {
    return JobCard(
      id: map['id'] as String,
      garageId: map['garageId'] as String,
      customerId: map['customerId'] as String,
      vehicleId: map['vehicleId'] as String,
      jobCardNumber: map['jobCardNumber'] as String,
      complaint: map['complaint'] as String,
      notes: map['notes'] as String?,
      beforePhotoPaths: _parseStringList(map['beforePhotoPaths']),
      afterPhotoPaths: _parseStringList(map['afterPhotoPaths']),
      status: _parseJobCardStatus(map['status']),
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
    );
  }
}

String _serializeStatus(JobCardStatus status) {
  switch (status) {
    case JobCardStatus.awaitingApproval:
      return 'awaitingApproval';
    case JobCardStatus.inProgress:
      return 'inProgress';
    default:
      return status.name;
  }
}

JobCardStatus _parseJobCardStatus(dynamic value) {
  if (value is JobCardStatus) return value;
  if (value is String) {
    switch (value) {
      case 'draft':
        return JobCardStatus.draft;
      case 'awaitingApproval':
      case 'awaiting_approval':
        return JobCardStatus.awaitingApproval;
      case 'approved':
        return JobCardStatus.approved;
      case 'inProgress':
      case 'in_progress':
        return JobCardStatus.inProgress;
      case 'ready':
        return JobCardStatus.ready;
      case 'closed':
        return JobCardStatus.closed;
    }
  }
  throw ArgumentError('Invalid job card status: $value');
}

List<String> _parseStringList(dynamic value) {
  if (value == null) return const [];
  if (value is List) {
    return value.where((e) => e != null).map((e) => e.toString()).toList();
  }
  throw ArgumentError('Invalid list value: $value');
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
