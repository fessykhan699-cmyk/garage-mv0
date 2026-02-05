import 'dart:async';
import 'dart:math';

import 'package:hive_flutter/hive_flutter.dart';

import '../../services/local_storage.dart';
import '../auth_repository.dart';
import '../garage_repository.dart';
import 'mock_garage_repository.dart';

class MockAuthRepository implements AuthRepository {
  MockAuthRepository({
    GarageRepository? garageRepository,
    Future<Box<Map<String, dynamic>>>? authBox,
  })  : _garageRepository = garageRepository ?? MockGarageRepository(),
        _authBoxFuture = authBox ?? LocalStorage.authBox();

  final GarageRepository _garageRepository;
  final Future<Box<Map<String, dynamic>>> _authBoxFuture;
  final Random _random = Random();

  static const _currentUserKey = '__currentUserId__';

  Future<Box<Map<String, dynamic>>> get _box => _authBoxFuture;

  @override
  Future<AuthUser?> currentUser() async {
    final box = await _box;
    final currentId = box.get(_currentUserKey) as String?;
    if (currentId == null) return null;
    return _getUserById(box, currentId);
  }

  @override
  Stream<AuthUser?> authStateChanges() async* {
    yield await currentUser();
    final box = await _box;
    yield* box.watch(key: _currentUserKey).asyncMap((_) => currentUser());
  }

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async {
    final box = await _box;
    final existing = _findUserByEmail(box, email);
    if (existing != null) {
      await box.put(_currentUserKey, existing.id);
      return existing;
    }
    return _createUser(box, email);
  }

  @override
  Future<AuthUser> signUp({
    required String email,
    required String password,
  }) {
    return signIn(email: email, password: password);
  }

  @override
  Future<void> signOut() async {
    final box = await _box;
    await box.delete(_currentUserKey);
  }

  Future<AuthUser> _createUser(
    Box<Map<String, dynamic>> box,
    String email,
  ) async {
    final userId = _generateId('user');
    final garage = await _garageRepository.createGarage(
      Garage(
        id: _generateId('garage'),
        plan: 'free',
        usage: const {},
      ),
    );
    final now = DateTime.now();
    final user = AuthUser(
      id: userId,
      email: email,
      garageId: garage.id,
      role: 'owner',
      createdAt: now,
      updatedAt: now,
    );
    await box.put(user.id, user.toMap());
    await box.put(_currentUserKey, user.id);
    return user;
  }

  AuthUser? _findUserByEmail(Box<Map<String, dynamic>> box, String email) {
    for (final key in box.keys) {
      if (key == _currentUserKey) continue;
      final value = box.get(key);
      if (value is Map && value['email'] == email) {
        return AuthUser.fromMap(Map<String, dynamic>.from(value));
      }
    }
    return null;
  }

  AuthUser? _getUserById(Box<Map<String, dynamic>> box, String userId) {
    final value = box.get(userId);
    if (value is Map) {
      return AuthUser.fromMap(Map<String, dynamic>.from(value));
    }
    return null;
  }

  String _generateId(String prefix) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final salt = _random.nextInt(0xFFFFFF);
    return '$prefix-$timestamp-$salt';
  }
}
