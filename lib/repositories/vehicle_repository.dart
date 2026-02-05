import '../models/vehicle.dart';

abstract class VehicleRepository {
  Future<Vehicle> create(Vehicle vehicle);
  Future<Vehicle?> fetch(String id);
  Future<List<Vehicle>> listByGarage(String garageId);
  Future<List<Vehicle>> listByCustomer(String customerId);
  Stream<List<Vehicle>> watchByGarage(String garageId);
  Stream<List<Vehicle>> watchByCustomer(String customerId);
  Future<void> update(Vehicle vehicle);
  Future<void> delete(String id);
}
