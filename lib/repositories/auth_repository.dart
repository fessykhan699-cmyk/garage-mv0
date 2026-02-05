class AuthUser {
  AuthUser({
    required this.id,
    required this.email,
    required this.garageId,
    this.role = 'owner',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? createdAt ?? DateTime.now();

  final String id;
  final String email;
  final String garageId;
  final String role;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toMap({bool useIsoFormat = true}) {
    return {
      'id': id,
      'email': email,
      'garageId': garageId,
      'role': role,
      'createdAt': _serializeDateTime(createdAt, useIsoFormat),
      'updatedAt': _serializeDateTime(updatedAt, useIsoFormat),
    };
  }

  factory AuthUser.fromMap(Map<String, dynamic> map) {
    return AuthUser(
      id: _requireString(map, 'id'),
      email: _requireString(map, 'email'),
      garageId: _requireString(map, 'garageId'),
      role: map['role'] as String? ?? 'owner',
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
    );
  }

  AuthUser copyWith({
    String? email,
    String? garageId,
    String? role,
    DateTime? updatedAt,
  }) {
    return AuthUser(
      id: id,
      email: email ?? this.email,
      garageId: garageId ?? this.garageId,
      role: role ?? this.role,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

abstract class AuthRepository {
  Future<AuthUser?> currentUser();
  Stream<AuthUser?> authStateChanges();
  Future<AuthUser> signIn({
    required String email,
    required String password,
  });
  Future<AuthUser> signUp({
    required String email,
    required String password,
  });
  Future<void> signOut();
}

String _requireString(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value is String) return value;
  if (value == null) throw ArgumentError('Missing required field: $key');
  throw ArgumentError('Required field $key must be a String');
}

DateTime _parseDateTime(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is DateTime) return value;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is double) return DateTime.fromMillisecondsSinceEpoch(value.round());
  if (value is String) return DateTime.parse(value);
  throw ArgumentError('Invalid date value: $value');
}

dynamic _serializeDateTime(DateTime value, bool useIsoFormat) =>
    useIsoFormat ? value.toIso8601String() : value.millisecondsSinceEpoch;
