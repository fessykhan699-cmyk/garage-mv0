import 'dart:async';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../../core/local_storage.dart';
import '../../models/vehicle.dart';
import '../vehicle_repository.dart';

class LocalVehicleRepository implements VehicleRepository {
  LocalVehicleRepository();

  final _uuid = const Uuid();
  final _streamController = StreamController<List<Vehicle>>.broadcast();

  Future<Box<Map<String, dynamic>>> get _box => LocalStorage.vehiclesBox();

  @override
  Future<Vehicle> create(Vehicle vehicle) async {
    final box = await _box;
    final vehicleData = vehicle.toMap(useIsoFormat: true);
    await box.put(vehicle.id, vehicleData);
    _notifyListeners();
    return vehicle;
  }

  @override
  Future<Vehicle?> fetch(String id) async {
    final box = await _box;
    final data = box.get(id);
    if (data == null) return null;
    return Vehicle.fromMap(Map<String, dynamic>.from(data));
  }

  @override
  Future<List<Vehicle>> listByGarage(String garageId) async {
    final box = await _box;
    final vehicles = <Vehicle>[];
    for (var key in box.keys) {
      final data = box.get(key);
      if (data != null) {
        final vehicle = Vehicle.fromMap(Map<String, dynamic>.from(data));
        if (vehicle.garageId == garageId) {
          vehicles.add(vehicle);
        }
      }
    }
    return vehicles;
  }

  @override
  Future<List<Vehicle>> listByCustomer(String customerId) async {
    final box = await _box;
    final vehicles = <Vehicle>[];
    for (var key in box.keys) {
      final data = box.get(key);
      if (data != null) {
        final vehicle = Vehicle.fromMap(Map<String, dynamic>.from(data));
        if (vehicle.customerId == customerId) {
          vehicles.add(vehicle);
        }
      }
    }
    return vehicles;
  }

  @override
  Stream<List<Vehicle>> watchByGarage(String garageId) async* {
    // Initial data
    yield await listByGarage(garageId);
    
    // Listen to changes
    await for (final _ in _streamController.stream) {
      yield await listByGarage(garageId);
    }
  }

  @override
  Stream<List<Vehicle>> watchByCustomer(String customerId) async* {
    // Initial data
    yield await listByCustomer(customerId);
    
    // Listen to changes
    await for (final _ in _streamController.stream) {
      yield await listByCustomer(customerId);
    }
  }

  @override
  Future<void> update(Vehicle vehicle) async {
    final box = await _box;
    final vehicleData = vehicle.toMap(useIsoFormat: true);
    await box.put(vehicle.id, vehicleData);
    _notifyListeners();
  }

  @override
  Future<void> delete(String id) async {
    final box = await _box;
    await box.delete(id);
    _notifyListeners();
  }

  void _notifyListeners() {
    _streamController.add([]);
  }

  void dispose() {
    _streamController.close();
  }
}
