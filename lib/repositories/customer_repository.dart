import '../models/customer.dart';

abstract class CustomerRepository {
  Future<Customer> create(Customer customer);
  Future<Customer?> fetch(String id);
  Future<List<Customer>> listByGarage(String garageId);
  Stream<List<Customer>> watchByGarage(String garageId);
  Future<void> update(Customer customer);
  Future<void> delete(String id);
}
