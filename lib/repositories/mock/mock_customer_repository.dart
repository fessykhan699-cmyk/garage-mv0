import 'dart:async';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:meta/meta.dart';

import '../../models/customer.dart';
import '../../services/local_storage.dart';
import '../customer_repository.dart';
import 'counter_utils.dart';

class MockCustomerRepository implements CustomerRepository {
  MockCustomerRepository({
    Future<Box<Map<String, dynamic>>>? customerBox,
  }) : _customerBoxFuture =
            customerBox ?? LocalStorage.openBox<Map<String, dynamic>>('customers');

  final Future<Box<Map<String, dynamic>>> _customerBoxFuture;

  static const _counterKey = '__customer_id_counter__';
  static const _optionalFields = ['name', 'phone', 'notes'];

  Future<Box<Map<String, dynamic>>> get _box => _customerBoxFuture;

  @override
  Future<Customer> create(Customer customer) async {
    final box = await _box;
    final normalized = await _ensureId(customer, box);
    final customerMap = normalized.toMap();
    final data = Map<String, dynamic>.from(customerMap);
    _mergeExistingOptionalFields(box.get(normalized.id), data);
    await box.put(normalized.id, data);
    return normalized;
  }

  @override
  Future<Customer?> fetch(String id) async {
    final box = await _box;
    final value = box.get(id);
    if (value is Map) {
      return Customer.fromMap(Map<String, dynamic>.from(value));
    }
    return null;
  }

  @override
  Future<List<Customer>> listByGarage(String garageId) async {
    final box = await _box;
    final items = box.values
        .whereType<Map>()
        .map((value) => Map<String, dynamic>.from(value))
        .where((map) => map['garageId'] == garageId)
        .map(Customer.fromMap)
        .toList();
    
    // Sort by createdAt descending (newest first)
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  @override
  Stream<List<Customer>> watchByGarage(String garageId) async* {
    yield await listByGarage(garageId);
    final box = await _box;
    yield* box.watch().asyncMap((_) => listByGarage(garageId));
  }

  @visibleForTesting
  Future<List<Customer>> search(String garageId, String query) async {
    final normalizedQuery = query.toLowerCase();
    final box = await _box;
    return box.values
        .whereType<Map>()
        .map((value) => Map<String, dynamic>.from(value))
        .where((map) => map['garageId'] == garageId)
        .where((map) {
          final name = (map['name'] ?? '').toString().toLowerCase();
          final phone = (map['phone'] ?? '').toString().toLowerCase();
          return name.contains(normalizedQuery) || phone.contains(normalizedQuery);
        })
        .map(Customer.fromMap)
        .toList(growable: false);
  }

  @override
  Future<void> update(Customer customer) async {
    final box = await _box;
    final customerMap = customer.toMap();
    final data = Map<String, dynamic>.from(customerMap);
    _mergeExistingOptionalFields(box.get(customer.id), data);
    await box.put(customer.id, data);
  }

  @override
  Future<void> delete(String id) async {
    final box = await _box;
    await box.delete(id);
  }

  Future<Customer> _ensureId(Customer customer, Box<Map<String, dynamic>> box) async {
    if (customer.id.isNotEmpty) return customer;
    final nextId = await _nextId(box);
    return Customer(
      id: nextId,
      garageId: customer.garageId,
      createdAt: customer.createdAt,
      updatedAt: customer.updatedAt,
    );
  }

  Future<String> _nextId(Box<Map<String, dynamic>> box) async {
    final next = await nextCounterValue(box, _counterKey);
    return 'cust-$next';
  }

  void _mergeExistingOptionalFields(
    dynamic existing,
    Map<String, dynamic> target,
  ) {
    if (existing is Map) {
      final existingMap = Map<String, dynamic>.from(existing);
      _copyOptionalFields(existingMap, target);
    }
  }

  void _copyOptionalFields(
    Map<String, dynamic> source,
    Map<String, dynamic> target,
  ) {
    for (final key in _optionalFields) {
      if (source.containsKey(key)) {
        target[key] = source[key];
      }
    }
  }
}
