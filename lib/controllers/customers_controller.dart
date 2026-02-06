import 'dart:async';

import '../models/customer.dart';
import '../repositories/customer_repository.dart';
import '../repositories/mock/mock_customer_repository.dart';

class CustomersController {
  const CustomersController(this._repository);

  final CustomerRepository _repository;

  Future<Customer> create(Customer customer) => _repository.create(customer);

  Future<Customer?> fetch(String id) => _repository.fetch(id);

  Future<void> update(Customer customer) => _repository.update(customer);

  Future<void> delete(String id) => _repository.delete(id);

  Future<List<Customer>> listByGarage(String garageId, {String? query}) async {
    final normalizedQuery = query?.trim();
    if (normalizedQuery == null || normalizedQuery.isEmpty) {
      return _repository.listByGarage(garageId);
    }
    return _search(garageId, normalizedQuery);
  }

  Stream<List<Customer>> watchByGarage(String garageId, {String? query}) async* {
    final normalizedQuery = query?.trim();
    if (normalizedQuery == null || normalizedQuery.isEmpty) {
      yield* _repository.watchByGarage(garageId);
      return;
    }

    yield await _search(garageId, normalizedQuery);
    yield* _repository
        .watchByGarage(garageId)
        .asyncMap((_) => _search(garageId, normalizedQuery));
  }

  Future<List<Customer>> _search(String garageId, String query) async {
    if (_repository is MockCustomerRepository) {
      return (_repository as MockCustomerRepository).search(garageId, query);
    }

    final normalizedQuery = query.toLowerCase();
    final customers = await _repository.listByGarage(garageId);
    return customers
        .where(
          (customer) => customer.id.toLowerCase().contains(normalizedQuery),
        )
        .toList(growable: false);
  }
}
