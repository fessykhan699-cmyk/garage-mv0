import 'dart:async';

import '../models/vehicle.dart';
import '../repositories/mock/mock_vehicle_repository.dart';
import '../repositories/vehicle_repository.dart';

class VehiclesController {
  const VehiclesController(this._repository);

  final VehicleRepository _repository;

  Future<Vehicle> create(Vehicle vehicle) => _repository.create(vehicle);

  Future<Vehicle?> fetch(String id) => _repository.fetch(id);

  Future<void> update(Vehicle vehicle) => _repository.update(vehicle);

  Future<void> delete(String id) => _repository.delete(id);

  Future<List<Vehicle>> listByGarage(String garageId, {String? plateQuery}) async {
    final normalizedQuery = plateQuery?.trim();
    if (normalizedQuery == null || normalizedQuery.isEmpty) {
      return _repository.listByGarage(garageId);
    }
    return _searchByPlate(garageId, normalizedQuery);
  }

  Future<List<Vehicle>> listByCustomer(
    String customerId, {
    String? plateQuery,
  }) async {
    final normalizedQuery = plateQuery?.trim();
    if (normalizedQuery == null || normalizedQuery.isEmpty) {
      return _repository.listByCustomer(customerId);
    }
    final vehicles = await _repository.listByCustomer(customerId);
    final queryLower = normalizedQuery.toLowerCase();
    return vehicles
        .where(
          (vehicle) => vehicle.plateNumber.toLowerCase().contains(queryLower),
        )
        .toList(growable: false);
  }

  Stream<List<Vehicle>> watchByGarage(
    String garageId, {
    String? plateQuery,
  }) async* {
    final normalizedQuery = plateQuery?.trim();
    if (normalizedQuery == null || normalizedQuery.isEmpty) {
      yield* _repository.watchByGarage(garageId);
      return;
    }

    yield await _searchByPlate(garageId, normalizedQuery);
    yield* _repository
        .watchByGarage(garageId)
        .asyncMap((_) => _searchByPlate(garageId, normalizedQuery));
  }

  Stream<List<Vehicle>> watchByCustomer(
    String customerId, {
    String? plateQuery,
  }) async* {
    final normalizedQuery = plateQuery?.trim();
    if (normalizedQuery == null || normalizedQuery.isEmpty) {
      yield* _repository.watchByCustomer(customerId);
      return;
    }

    final queryLower = normalizedQuery.toLowerCase();
    yield await listByCustomer(customerId, plateQuery: normalizedQuery);
    yield* _repository.watchByCustomer(customerId).asyncMap(
          (vehicles) => vehicles
              .where(
                (vehicle) =>
                    vehicle.plateNumber.toLowerCase().contains(queryLower),
              )
              .toList(growable: false),
        );
  }

  Future<List<Vehicle>> _searchByPlate(String garageId, String query) async {
    if (_repository is MockVehicleRepository) {
      return (_repository as MockVehicleRepository)
          .searchByPlate(garageId, query);
    }

    final normalizedQuery = query.toLowerCase();
    final vehicles = await _repository.listByGarage(garageId);
    return vehicles
        .where(
          (vehicle) => vehicle.plateNumber.toLowerCase().contains(normalizedQuery),
        )
        .toList(growable: false);
  }
}
