import 'dart:async';

import 'package:hive_flutter/hive_flutter.dart';

import '../../models/invoice.dart';
import '../../services/local_storage.dart';
import '../invoice_repository.dart';
import 'counter_utils.dart';

class MockInvoiceRepository implements InvoiceRepository {
  MockInvoiceRepository({
    Future<Box<Map<String, dynamic>>>? invoiceBox,
  }) : _invoiceBoxFuture =
            invoiceBox ?? LocalStorage.openBox<Map<String, dynamic>>('invoices');

  final Future<Box<Map<String, dynamic>>> _invoiceBoxFuture;

  static const _counterKey = '__invoice_id_counter__';

  Future<Box<Map<String, dynamic>>> get _box => _invoiceBoxFuture;

  @override
  Future<Invoice> create(Invoice invoice) async {
    final box = await _box;
    final normalized = _normalize(await _ensureId(invoice, box));
    await box.put(normalized.id, normalized.toMap());
    return normalized;
  }

  @override
  Future<Invoice?> fetch(String id) async {
    final box = await _box;
    final value = box.get(id);
    if (value is Map) {
      return Invoice.fromMap(Map<String, dynamic>.from(value));
    }
    return null;
  }

  @override
  Future<List<Invoice>> listByGarage(String garageId) async {
    final box = await _box;
    return box.values
        .whereType<Map>()
        .map((value) => Map<String, dynamic>.from(value))
        .where((map) => map['garageId'] == garageId)
        .map(Invoice.fromMap)
        .toList(growable: false);
  }

  @override
  Stream<List<Invoice>> watchByGarage(String garageId) async* {
    yield await listByGarage(garageId);
    final box = await _box;
    yield* box.watch().asyncMap((_) => listByGarage(garageId));
  }

  @override
  Future<void> update(Invoice invoice) async {
    final box = await _box;
    final normalized = _normalize(invoice);
    await box.put(normalized.id, normalized.toMap());
  }

  @override
  Future<void> delete(String id) async {
    final box = await _box;
    await box.delete(id);
  }

  Invoice _normalize(Invoice invoice) {
    final rawBalanceDue = invoice.total - invoice.amountPaid;
    final balanceDue = rawBalanceDue < 0 ? 0 : rawBalanceDue;
    final status = _deriveStatus(invoice.total, invoice.amountPaid);
    return Invoice(
      id: invoice.id,
      garageId: invoice.garageId,
      quotationId: invoice.quotationId,
      jobCardId: invoice.jobCardId,
      customerId: invoice.customerId,
      vehicleId: invoice.vehicleId,
      invoiceNumber: invoice.invoiceNumber,
      status: status,
      subtotal: invoice.subtotal,
      discountAmount: invoice.discountAmount,
      vatAmount: invoice.vatAmount,
      total: invoice.total,
      amountPaid: invoice.amountPaid,
      balanceDue: balanceDue,
      pdfPath: invoice.pdfPath,
      createdAt: invoice.createdAt,
      updatedAt: invoice.updatedAt,
    );
  }

  InvoiceStatus _deriveStatus(num total, num amountPaid) {
    if (amountPaid <= 0) return InvoiceStatus.unpaid;
    if (amountPaid < total) return InvoiceStatus.partial;
    return InvoiceStatus.paid;
  }

  Future<Invoice> _ensureId(
    Invoice invoice,
    Box<Map<String, dynamic>> box,
  ) async {
    if (invoice.id.isNotEmpty) return invoice;
    final nextId = await _nextId(box);
    return Invoice(
      id: nextId,
      garageId: invoice.garageId,
      quotationId: invoice.quotationId,
      jobCardId: invoice.jobCardId,
      customerId: invoice.customerId,
      vehicleId: invoice.vehicleId,
      invoiceNumber: invoice.invoiceNumber,
      status: invoice.status,
      subtotal: invoice.subtotal,
      discountAmount: invoice.discountAmount,
      vatAmount: invoice.vatAmount,
      total: invoice.total,
      amountPaid: invoice.amountPaid,
      balanceDue: invoice.balanceDue,
      pdfPath: invoice.pdfPath,
      createdAt: invoice.createdAt,
      updatedAt: invoice.updatedAt,
    );
  }

  Future<String> _nextId(Box<Map<String, dynamic>> box) async {
    final next = await nextCounterValue(box, _counterKey);
    return 'inv-$next';
  }
}
