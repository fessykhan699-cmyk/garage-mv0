import 'dart:async';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../../core/local_storage.dart';
import '../auth_repository.dart';
import '../garage_repository.dart';

class LocalAuthRepository implements AuthRepository {
  LocalAuthRepository({required this.garageRepository});

  final GarageRepository garageRepository;
  final _uuid = const Uuid();
  final _streamController = StreamController<AuthUser?>.broadcast();
  
  AuthUser? _currentUser;

  Future<Box<Map<String, dynamic>>> get _usersBox => LocalStorage.usersBox();
  Future<Box<Map<String, dynamic>>> get _authBox => LocalStorage.authBox();

  @override
  Future<AuthUser?> currentUser() async {
    if (_currentUser != null) return _currentUser;
    
    // Check if there's a logged-in user
    final authBox = await _authBox;
    final currentUserId = authBox.get('currentUserId') as String?;
    if (currentUserId == null) return null;
    
    final usersBox = await _usersBox;
    final userData = usersBox.get(currentUserId);
    if (userData == null) return null;
    
    _currentUser = AuthUser.fromMap(Map<String, dynamic>.from(userData));
    return _currentUser;
  }

  @override
  Stream<AuthUser?> authStateChanges() async* {
    // Initial value
    yield await currentUser();
    
    // Listen to changes
    await for (final user in _streamController.stream) {
      yield user;
    }
  }

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async {
    final usersBox = await _usersBox;
    
    // Find user by email
    AuthUser? foundUser;
    for (var key in usersBox.keys) {
      final data = usersBox.get(key);
      if (data != null) {
        final user = AuthUser.fromMap(Map<String, dynamic>.from(data));
        if (user.email.toLowerCase() == email.toLowerCase()) {
          foundUser = user;
          break;
        }
      }
    }
    
    if (foundUser == null) {
      throw Exception('User not found. Please sign up first.');
    }
    
    // In local mode, we don't actually verify password
    // Just simulate successful login
    _currentUser = foundUser;
    
    // Set as current user
    final authBox = await _authBox;
    await authBox.put('currentUserId', foundUser.id);
    
    // Set session garageId
    await LocalStorage.setSessionGarageId(foundUser.garageId);
    
    _streamController.add(_currentUser);
    return foundUser;
  }

  @override
  Future<AuthUser> signUp({
    required String email,
    required String password,
  }) async {
    final usersBox = await _usersBox;
    
    // Check if user already exists
    for (var key in usersBox.keys) {
      final data = usersBox.get(key);
      if (data != null) {
        final user = AuthUser.fromMap(Map<String, dynamic>.from(data));
        if (user.email.toLowerCase() == email.toLowerCase()) {
          throw Exception('User already exists. Please sign in.');
        }
      }
    }
    
    // Create new garage for the user
    final garageId = _uuid.v4();
    final garage = Garage(
      id: garageId,
      name: 'My Garage',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await garageRepository.createGarage(garage);
    
    // Create new user
    final userId = _uuid.v4();
    final user = AuthUser(
      id: userId,
      email: email,
      garageId: garageId,
      role: 'owner',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    final userData = user.toMap(useIsoFormat: true);
    await usersBox.put(userId, userData);
    
    _currentUser = user;
    
    // Set as current user
    final authBox = await _authBox;
    await authBox.put('currentUserId', userId);
    
    // Set session garageId
    await LocalStorage.setSessionGarageId(garageId);
    
    _streamController.add(_currentUser);
    return user;
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    
    // Clear current user
    final authBox = await _authBox;
    await authBox.delete('currentUserId');
    
    // Clear session garageId
    await LocalStorage.setSessionGarageId(null);
    
    _streamController.add(null);
  }

  void dispose() {
    _streamController.close();
  }
}
