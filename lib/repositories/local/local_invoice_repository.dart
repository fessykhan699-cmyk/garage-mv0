import 'dart:async';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../../core/local_storage.dart';
import '../../models/invoice.dart';
import '../invoice_repository.dart';

class LocalInvoiceRepository implements InvoiceRepository {
  LocalInvoiceRepository();

  final _uuid = const Uuid();
  final _streamController = StreamController<List<Invoice>>.broadcast();

  Future<Box<Map<String, dynamic>>> get _box => LocalStorage.invoicesBox();

  @override
  Future<Invoice> create(Invoice invoice) async {
    final box = await _box;
    final invoiceData = invoice.toMap(useIsoFormat: true);
    await box.put(invoice.id, invoiceData);
    _notifyListeners();
    return invoice;
  }

  @override
  Future<Invoice?> fetch(String id) async {
    final box = await _box;
    final data = box.get(id);
    if (data == null) return null;
    return Invoice.fromMap(Map<String, dynamic>.from(data));
  }

  @override
  Future<List<Invoice>> listByGarage(String garageId) async {
    final box = await _box;
    final invoices = <Invoice>[];
    for (var key in box.keys) {
      final data = box.get(key);
      if (data != null) {
        final invoice = Invoice.fromMap(Map<String, dynamic>.from(data));
        if (invoice.garageId == garageId) {
          invoices.add(invoice);
        }
      }
    }
    return invoices;
  }

  @override
  Stream<List<Invoice>> watchByGarage(String garageId) async* {
    // Initial data
    yield await listByGarage(garageId);
    
    // Listen to changes
    await for (final _ in _streamController.stream) {
      yield await listByGarage(garageId);
    }
  }

  @override
  Future<void> update(Invoice invoice) async {
    final box = await _box;
    final invoiceData = invoice.toMap(useIsoFormat: true);
    await box.put(invoice.id, invoiceData);
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
