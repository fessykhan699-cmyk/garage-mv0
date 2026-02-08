import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:garage_mv0/core/session.dart';
import 'package:garage_mv0/repositories/garage_repository.dart';
import 'package:garage_mv0/repositories/mock/mock_garage_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SessionController', () {
    late Box<Map<String, dynamic>> authBox;
    late Box<Map<String, dynamic>> garageBox;
    late GarageRepository garageRepository;
    late SessionController sessionController;

    setUp(() async {
      // Initialize Hive for testing
      await Hive.initFlutter();
      
      // Open test boxes
      authBox = await Hive.openBox<Map<String, dynamic>>('test_auth');
      garageBox = await Hive.openBox<Map<String, dynamic>>('test_garages');
      
      // Clear any existing data
      await authBox.clear();
      await garageBox.clear();
      
      garageRepository = MockGarageRepository(garageBox: Future.value(garageBox));
      sessionController = SessionController(garageRepository: garageRepository);
    });

    tearDown(() async {
      await authBox.clear();
      await garageBox.clear();
      await authBox.close();
      await garageBox.close();
    });

    test('initial state is not authenticated', () {
      expect(sessionController.state.isAuthenticated, false);
      expect(sessionController.state.garageId, null);
      expect(sessionController.state.email, null);
    });

    test('login creates garage if not exists', () async {
      final email = 'test@example.com';
      final password = 'password123';

      await sessionController.login(email, password);

      expect(sessionController.state.isAuthenticated, true);
      expect(sessionController.state.email, email);
      expect(sessionController.state.garageId, isNotNull);

      // Verify garage was created
      final garageId = sessionController.state.garageId!;
      final garage = await garageRepository.fetchGarage(garageId);
      expect(garage, isNotNull);
      expect(garage!.id, garageId);
      expect(garage.plan, 'free');
    });

    test('login saves session to storage', () async {
      final email = 'test@example.com';
      final password = 'password123';

      await sessionController.login(email, password);

      // Check that session was saved to Hive
      final savedEmail = await authBox.get('email');
      final savedGarageId = await authBox.get('garageId');

      expect(savedEmail, email);
      expect(savedGarageId, isNotNull);
    });

    test('logout clears session', () async {
      // First login
      await sessionController.login('test@example.com', 'password123');
      expect(sessionController.state.isAuthenticated, true);

      // Then logout
      await sessionController.logout();

      expect(sessionController.state.isAuthenticated, false);
      expect(sessionController.state.garageId, null);
      expect(sessionController.state.email, null);

      // Verify storage was cleared
      final savedEmail = await authBox.get('email');
      final savedGarageId = await authBox.get('garageId');

      expect(savedEmail, null);
      expect(savedGarageId, null);
    });

    test('initialize restores session from storage', () async {
      // Login and save session
      await sessionController.login('test@example.com', 'password123');
      final originalGarageId = sessionController.state.garageId;

      // Create new controller (simulating app restart)
      final newController = SessionController(garageRepository: garageRepository);
      expect(newController.state.isAuthenticated, false);

      // Initialize should restore session
      await newController.initialize();

      expect(newController.state.isAuthenticated, true);
      expect(newController.state.email, 'test@example.com');
      expect(newController.state.garageId, originalGarageId);
    });

    test('login with empty email throws error', () async {
      expect(
        () => sessionController.login('', 'password'),
        throwsArgumentError,
      );
    });

    test('login with empty password throws error', () async {
      expect(
        () => sessionController.login('test@example.com', ''),
        throwsArgumentError,
      );
    });
  });
}
