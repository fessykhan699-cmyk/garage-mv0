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
      id: _requireString(map, 'id'),
      garageId: _requireString(map, 'garageId'),
      customerId: _requireString(map, 'customerId'),
      vehicleId: _requireString(map, 'vehicleId'),
      jobCardNumber: _requireString(map, 'jobCardNumber'),
      complaint: _requireString(map, 'complaint'),
      notes: map['notes'] as String?,
      beforePhotoPaths: _parseStringList(map['beforePhotoPaths']),
      afterPhotoPaths: _parseStringList(map['afterPhotoPaths']),
      status: _parseJobCardStatus(_requireValue(map, 'status')),
      createdAt: _parseDateTime(_requireValue(map, 'createdAt')),
      updatedAt: _parseDateTime(_requireValue(map, 'updatedAt')),
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
    final result = <String>[];
    for (final element in value) {
      if (element is! String) {
        throw ArgumentError(
          'List elements must be strings. Found ${element.runtimeType}: $element',
        );
      }
      result.add(element);
    }
    return List<String>.unmodifiable(result);
  }
  throw ArgumentError('Invalid list value: $value');
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

dynamic _serializeDateTime(DateTime value, bool useIsoFormat) =>
    useIsoFormat ? value.toIso8601String() : value.millisecondsSinceEpoch;

DateTime _parseDateTime(dynamic value) {
  if (value is DateTime) return value;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is double) {
    return DateTime.fromMillisecondsSinceEpoch(value.toInt());
  }
  if (value is String) return DateTime.parse(value);
  throw ArgumentError('Invalid date value: $value');
}
