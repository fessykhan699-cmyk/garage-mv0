import 'dart:async';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:meta/meta.dart';

import '../../models/vehicle.dart';
import '../../services/local_storage.dart';
import '../vehicle_repository.dart';

class MockVehicleRepository implements VehicleRepository {
  MockVehicleRepository({
    Future<Box<Map<String, dynamic>>>? vehicleBox,
  }) : _vehicleBoxFuture =
            vehicleBox ?? LocalStorage.openBox<Map<String, dynamic>>('vehicles');

  final Future<Box<Map<String, dynamic>>> _vehicleBoxFuture;

  static const _counterKey = '__vehicle_id_counter__';

  Future<Box<Map<String, dynamic>>> get _box => _vehicleBoxFuture;

  @override
  Future<Vehicle> create(Vehicle vehicle) async {
    final box = await _box;
    final normalized = await _ensureId(vehicle, box);
    await box.put(normalized.id, normalized.toMap());
    return normalized;
  }

  @override
  Future<Vehicle?> fetch(String id) async {
    final box = await _box;
    final value = box.get(id);
    if (value is Map) {
      return Vehicle.fromMap(Map<String, dynamic>.from(value));
    }
    return null;
  }

  @override
  Future<List<Vehicle>> listByGarage(String garageId) async {
    final box = await _box;
    final items = box.values
        .whereType<Map>()
        .map((value) => Map<String, dynamic>.from(value))
        .where((map) => map['garageId'] == garageId)
        .map(Vehicle.fromMap)
        .toList();
    
    // Sort by createdAt descending (newest first)
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  @override
  Future<List<Vehicle>> listByCustomer(String customerId) async {
    final box = await _box;
    final items = box.values
        .whereType<Map>()
        .map((value) => Map<String, dynamic>.from(value))
        .where((map) => map['customerId'] == customerId)
        .map(Vehicle.fromMap)
        .toList();
    
    // Sort by createdAt descending (newest first)
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  @override
  Stream<List<Vehicle>> watchByGarage(String garageId) async* {
    yield await listByGarage(garageId);
    final box = await _box;
    yield* box.watch().asyncMap((_) => listByGarage(garageId));
  }

  @override
  Stream<List<Vehicle>> watchByCustomer(String customerId) async* {
    yield await listByCustomer(customerId);
    final box = await _box;
    yield* box.watch().asyncMap((_) => listByCustomer(customerId));
  }

  @visibleForTesting
  Future<List<Vehicle>> searchByPlate(String garageId, String query) async {
    final normalizedQuery = query.toLowerCase();
    final box = await _box;
    return box.values
        .whereType<Map>()
        .map((value) => Map<String, dynamic>.from(value))
        .where((map) => map['garageId'] == garageId)
        .where((map) {
          final plate = (map['plateNumber'] ?? '').toString().toLowerCase();
          return plate.contains(normalizedQuery);
        })
        .map(Vehicle.fromMap)
        .toList(growable: false);
  }

  @override
  Future<void> update(Vehicle vehicle) async {
    final box = await _box;
    await box.put(vehicle.id, vehicle.toMap());
  }

  @override
  Future<void> delete(String id) async {
    final box = await _box;
    await box.delete(id);
  }

  Future<Vehicle> _ensureId(
    Vehicle vehicle,
    Box<Map<String, dynamic>> box,
  ) async {
    if (vehicle.id.isNotEmpty) return vehicle;
    final nextId = await _nextId(box);
    return Vehicle(
      id: nextId,
      garageId: vehicle.garageId,
      customerId: vehicle.customerId,
      plateNumber: vehicle.plateNumber,
      make: vehicle.make,
      model: vehicle.model,
      year: vehicle.year,
      createdAt: vehicle.createdAt,
      updatedAt: vehicle.updatedAt,
    );
  }

  Future<String> _nextId(Box<Map<String, dynamic>> box) async {
    final current = (box.get(_counterKey) as int?) ?? 0;
    final next = current + 1;
    await box.put(_counterKey, next);
    return 'veh-$next';
  }
}
