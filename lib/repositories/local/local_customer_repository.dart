import 'dart:async';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../../core/local_storage.dart';
import '../../models/customer.dart';
import '../customer_repository.dart';

class LocalCustomerRepository implements CustomerRepository {
  LocalCustomerRepository();

  final _uuid = const Uuid();
  final _streamController = StreamController<List<Customer>>.broadcast();

  Future<Box<Map<String, dynamic>>> get _box => LocalStorage.customersBox();

  @override
  Future<Customer> create(Customer customer) async {
    final box = await _box;
    final customerData = customer.toMap(useIsoFormat: true);
    await box.put(customer.id, customerData);
    _notifyListeners();
    return customer;
  }

  @override
  Future<Customer?> fetch(String id) async {
    final box = await _box;
    final data = box.get(id);
    if (data == null) return null;
    return Customer.fromMap(Map<String, dynamic>.from(data));
  }

  @override
  Future<List<Customer>> listByGarage(String garageId) async {
    final box = await _box;
    final customers = <Customer>[];
    for (var key in box.keys) {
      final data = box.get(key);
      if (data != null) {
        final customer = Customer.fromMap(Map<String, dynamic>.from(data));
        if (customer.garageId == garageId) {
          customers.add(customer);
        }
      }
    }
    return customers;
  }

  @override
  Stream<List<Customer>> watchByGarage(String garageId) async* {
    // Initial data
    yield await listByGarage(garageId);
    
    // Listen to changes
    await for (final _ in _streamController.stream) {
      yield await listByGarage(garageId);
    }
  }

  @override
  Future<void> update(Customer customer) async {
    final box = await _box;
    final customerData = customer.toMap(useIsoFormat: true);
    await box.put(customer.id, customerData);
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
