import 'dart:async';
import 'package:hive/hive.dart';

import '../../core/local_storage.dart';
import '../garage_repository.dart';

class LocalGarageRepository implements GarageRepository {
  LocalGarageRepository();

  final _streamController = StreamController<Garage?>.broadcast();

  Future<Box<Map<String, dynamic>>> get _box => LocalStorage.garageBox();

  @override
  Future<Garage> createGarage(Garage garage) async {
    final box = await _box;
    final garageData = garage.toMap(useIsoFormat: true);
    await box.put(garage.id, garageData);
    _notifyListeners(garage.id);
    return garage;
  }

  @override
  Future<Garage?> fetchGarage(String garageId) async {
    final box = await _box;
    final data = box.get(garageId);
    if (data == null) return null;
    return Garage.fromMap(Map<String, dynamic>.from(data));
  }

  @override
  Stream<Garage?> watchGarage(String garageId) async* {
    // Initial data
    yield await fetchGarage(garageId);
    
    // Listen to changes
    await for (final _ in _streamController.stream) {
      yield await fetchGarage(garageId);
    }
  }

  @override
  Future<void> updateGarage(Garage garage) async {
    final box = await _box;
    final garageData = garage.toMap(useIsoFormat: true);
    await box.put(garage.id, garageData);
    _notifyListeners(garage.id);
  }

  @override
  Future<void> updatePlan(String garageId, String plan) async {
    final garage = await fetchGarage(garageId);
    if (garage == null) {
      throw StateError('Garage not found: $garageId');
    }
    final updatedGarage = garage.copyWith(
      plan: plan,
      planActivatedAt: DateTime.now(),
    );
    await updateGarage(updatedGarage);
  }

  @override
  Future<void> incrementUsage(
    String garageId, {
    int jobCardsCreated = 0,
    int pdfExports = 0,
    int approvalsCreated = 0,
    int invoicesCreated = 0,
  }) async {
    final garage = await fetchGarage(garageId);
    if (garage == null) {
      throw StateError('Garage not found: $garageId');
    }
    final updatedGarage = garage.incrementUsage(
      jobCardsCreated: jobCardsCreated,
      pdfExports: pdfExports,
      approvalsCreated: approvalsCreated,
      invoicesCreated: invoicesCreated,
    );
    await updateGarage(updatedGarage);
  }

  void _notifyListeners(String garageId) {
    _streamController.add(null);
  }

  void dispose() {
    _streamController.close();
  }
}
