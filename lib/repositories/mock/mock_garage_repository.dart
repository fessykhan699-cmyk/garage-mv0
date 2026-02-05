import 'dart:async';

import 'package:hive_flutter/hive_flutter.dart';

import '../garage_repository.dart';
import '../../services/local_storage.dart';

class MockGarageRepository implements GarageRepository {
  MockGarageRepository({
    Future<Box<Map<String, dynamic>>>? garageBox,
  }) : _garageBoxFuture = garageBox ?? LocalStorage.garageBox();

  final Future<Box<Map<String, dynamic>>> _garageBoxFuture;

  Future<Box<Map<String, dynamic>>> get _box => _garageBoxFuture;

  @override
  Future<Garage> createGarage(Garage garage) async {
    final box = await _box;
    final normalized = _ensureDefaults(garage);
    await box.put(normalized.id, normalized.toMap());
    return normalized;
  }

  @override
  Future<Garage?> fetchGarage(String garageId) async {
    final box = await _box;
    final value = box.get(garageId);
    if (value is Map) {
      return Garage.fromMap(Map<String, dynamic>.from(value));
    }
    return null;
  }

  @override
  Stream<Garage?> watchGarage(String garageId) async* {
    yield await fetchGarage(garageId);
    final box = await _box;
    yield* box
        .watch(key: garageId)
        .map((event) => _mapToGarage(event.value, allowNull: true));
  }

  @override
  Future<void> updateGarage(Garage garage) async {
    final box = await _box;
    final normalized = _ensureDefaults(garage);
    await box.put(normalized.id, normalized.toMap());
  }

  @override
  Future<void> updatePlan(String garageId, String plan) async {
    final existing = await fetchGarage(garageId) ??
        Garage(id: garageId, plan: plan, usage: const {});
    final updated = existing.copyWith(plan: plan, updatedAt: DateTime.now());
    final box = await _box;
    await box.put(garageId, updated.toMap());
  }

  @override
  Future<void> incrementUsage(
    String garageId, {
    int jobCardsCreated = 0,
    int pdfExports = 0,
    int approvalsCreated = 0,
    int invoicesCreated = 0,
  }) async {
    final existing = await fetchGarage(garageId) ??
        Garage(id: garageId, plan: 'free', usage: const {});
    final updated = existing
        .incrementUsage(
          jobCardsCreated: jobCardsCreated,
          pdfExports: pdfExports,
          approvalsCreated: approvalsCreated,
          invoicesCreated: invoicesCreated,
        )
        .copyWith(updatedAt: DateTime.now());
    final box = await _box;
    await box.put(garageId, updated.toMap());
  }

  Garage _ensureDefaults(Garage garage) {
    return garage.copyWith(
      plan: garage.plan.isEmpty ? 'free' : garage.plan,
      usage: {
        'jobCardsCreated': garage.usage['jobCardsCreated'] ?? 0,
        'pdfExports': garage.usage['pdfExports'] ?? 0,
        'approvalsCreated': garage.usage['approvalsCreated'] ?? 0,
        'invoicesCreated': garage.usage['invoicesCreated'] ?? 0,
      },
    );
  }

  Garage? _mapToGarage(dynamic value, {bool allowNull = false}) {
    if (value == null && allowNull) return null;
    if (value is Map) {
      return Garage.fromMap(Map<String, dynamic>.from(value));
    }
    return null;
  }
}
