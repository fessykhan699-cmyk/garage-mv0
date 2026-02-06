import 'dart:async';

import '../models/customer.dart';
import '../repositories/customer_repository.dart';

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

    final queryLower = normalizedQuery.toLowerCase();
    yield* _repository.watchByGarage(garageId).map(
          (customers) => _filterCustomers(customers, queryLower),
        );
  }

  Future<List<Customer>> _search(String garageId, String query) async {
    final normalizedQuery = query.toLowerCase();
    final customers = await _repository.listByGarage(garageId);
    return _filterCustomers(customers, normalizedQuery);
  }

  List<Customer> _filterCustomers(
    List<Customer> customers,
    String normalizedQuery,
  ) {
    return customers
        .where((customer) => _matchesCustomer(customer, normalizedQuery))
        .toList(growable: false);
  }

  bool _matchesCustomer(Customer customer, String normalizedQuery) {
    final customerMap = customer.toMap();
    final name = _findCustomerFieldValue(
      customerMap,
      ['name', 'customerName'],
    );
    final phone = _findCustomerFieldValue(
      customerMap,
      ['phone', 'customerPhone'],
    );
    final id = customer.id.toLowerCase();
    return name.contains(normalizedQuery) ||
        phone.contains(normalizedQuery) ||
        id.contains(normalizedQuery);
  }

  String _findCustomerFieldValue(
    Map<String, dynamic> customerMap,
    List<String> keys,
  ) {
    // Support both legacy and current field names stored by repositories.
    for (final key in keys) {
      final value = customerMap[key];
      if (value is String && value.isNotEmpty) {
        return value.toLowerCase();
      }
    }
    return '';
  }
}
