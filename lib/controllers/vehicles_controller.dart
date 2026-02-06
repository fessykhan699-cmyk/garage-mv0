import 'dart:async';

import '../models/vehicle.dart';
import '../repositories/vehicle_repository.dart';

class VehiclesController {
  const VehiclesController(this._repository);

  final VehicleRepository _repository;

  Future<Vehicle> create(Vehicle vehicle) => _repository.create(vehicle);

  Future<Vehicle?> fetch(String id) => _repository.fetch(id);

  Future<void> update(Vehicle vehicle) => _repository.update(vehicle);

  Future<void> delete(String id) => _repository.delete(id);

  Future<List<Vehicle>> listByGarage(String garageId, {String? plateQuery}) async {
    final normalizedQuery = _normalizeQuery(plateQuery);
    return _searchByPlate(garageId, normalizedQuery);
  }

  Future<List<Vehicle>> listByCustomer(
    String customerId, {
    String? plateQuery,
  }) async {
    final normalizedQuery = _normalizeQuery(plateQuery);
    if (normalizedQuery.isEmpty) {
      return _repository.listByCustomer(customerId);
    }
    final vehicles = await _repository.listByCustomer(customerId);
    return _filterByPlate(vehicles, normalizedQuery);
  }

  Stream<List<Vehicle>> watchByGarage(
    String garageId, {
    String? plateQuery,
  }) async* {
    final normalizedQuery = _normalizeQuery(plateQuery);
    yield await _searchByPlate(garageId, normalizedQuery);
    yield* _repository
        .watchByGarage(garageId)
        .asyncMap((_) => _searchByPlate(garageId, normalizedQuery));
  }

  Stream<List<Vehicle>> watchByCustomer(
    String customerId, {
    String? plateQuery,
  }) async* {
    final normalizedQuery = _normalizeQuery(plateQuery);
    if (normalizedQuery.isEmpty) {
      yield* _repository.watchByCustomer(customerId);
      return;
    }

    final initialVehicles = await _repository.listByCustomer(customerId);
    yield _filterByPlate(initialVehicles, normalizedQuery);
    yield* _repository.watchByCustomer(customerId).asyncMap(
          (vehicles) => _filterByPlate(vehicles, normalizedQuery),
        );
  }

  Future<List<Vehicle>> _searchByPlate(String garageId, String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      return _repository.listByGarage(garageId);
    }

    // Repository interface does not expose server-side plate search; fall back to
    // client-side filtering.
    final vehicles = await _repository.listByGarage(garageId);
    return _filterByPlate(vehicles, trimmedQuery);
  }

  List<Vehicle> _filterByPlate(List<Vehicle> vehicles, String query) {
    // Normalize here to keep callers simple; queries are trimmed by caller and
    // lowercased here for case-insensitive matching.
    final normalizedQuery = query.toLowerCase();
    return vehicles
        .where(
          (vehicle) =>
              vehicle.plateNumber.toLowerCase().contains(normalizedQuery),
        )
        .toList(growable: false);
  }

  String _normalizeQuery(String? query) => query?.trim() ?? '';
}
