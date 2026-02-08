import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../repositories/garage_repository.dart';
import '../repositories/mock/mock_garage_repository.dart';
import '../services/local_storage.dart';

/// Session state representing the current user and garage
class SessionState {
  const SessionState({
    required this.isAuthenticated,
    this.garageId,
    this.email,
  });

  final bool isAuthenticated;
  final String? garageId;
  final String? email;

  SessionState copyWith({
    bool? isAuthenticated,
    String? garageId,
    String? email,
  }) {
    return SessionState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      garageId: garageId ?? this.garageId,
      email: email ?? this.email,
    );
  }
}

/// Session controller managing authentication and garage context
class SessionController extends StateNotifier<SessionState> {
  SessionController({
    GarageRepository? garageRepository,
  })  : _garageRepository = garageRepository ?? MockGarageRepository(),
        super(const SessionState(isAuthenticated: false));

  final GarageRepository _garageRepository;

  /// Initialize session from local storage
  Future<void> initialize() async {
    final box = await LocalStorage.authBox();
    final email = box.get('email') as String?;
    final garageId = box.get('garageId') as String?;

    if (email != null && garageId != null) {
      state = SessionState(
        isAuthenticated: true,
        email: email,
        garageId: garageId,
      );
    }
  }

  /// Login with email and password (local mode)
  /// In local mode, any email/password logs in and creates a garage if needed
  Future<void> login(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      throw ArgumentError('Email and password are required');
    }

    // Generate garage ID from email
    final garageId = _generateGarageId(email);

    // Check if garage exists, create if not
    var garage = await _garageRepository.fetchGarage(garageId);
    if (garage == null) {
      garage = Garage(
        id: garageId,
        name: null,
        phone: null,
        address: null,
        logoUrl: null,
        plan: 'free',
        usage: const {
          'jobCardsCreated': 0,
          'pdfExports': 0,
          'approvalsCreated': 0,
          'invoicesCreated': 0,
        },
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _garageRepository.createGarage(garage);
    }

    // Save session to local storage
    final box = await LocalStorage.authBox();
    await box.put('email', email);
    await box.put('garageId', garageId);

    // Update state
    state = SessionState(
      isAuthenticated: true,
      email: email,
      garageId: garageId,
    );
  }

  /// Logout and clear session
  Future<void> logout() async {
    final box = await LocalStorage.authBox();
    await box.delete('email');
    await box.delete('garageId');

    state = const SessionState(isAuthenticated: false);
  }

  /// Generate a deterministic garage ID from email
  String _generateGarageId(String email) {
    // Use email as base for garage ID (simple implementation)
    // In production, this could be a UUID or hash
    final normalized = email.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    return 'garage-$normalized';
  }
}

/// Provider for session controller
final sessionControllerProvider =
    StateNotifierProvider<SessionController, SessionState>((ref) {
  return SessionController();
});

/// Provider for current garage ID
final currentGarageIdProvider = Provider<String?>((ref) {
  final session = ref.watch(sessionControllerProvider);
  return session.garageId;
});

/// Provider for authentication status
final isAuthenticatedProvider = Provider<bool>((ref) {
  final session = ref.watch(sessionControllerProvider);
  return session.isAuthenticated;
});
