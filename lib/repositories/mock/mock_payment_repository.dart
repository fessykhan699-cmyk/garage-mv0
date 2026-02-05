import 'dart:async';

import 'package:hive_flutter/hive_flutter.dart';

import '../../models/invoice.dart';
import '../../models/payment.dart';
import '../../services/local_storage.dart';
import '../invoice_repository.dart';
import '../payment_repository.dart';
import 'mock_invoice_repository.dart';

class MockPaymentRepository implements PaymentRepository {
  MockPaymentRepository({
    InvoiceRepository? invoiceRepository,
    Future<Box<Map<String, dynamic>>>? paymentBox,
  })  : _invoiceRepository = invoiceRepository ?? MockInvoiceRepository(),
        _paymentBoxFuture =
            paymentBox ?? LocalStorage.openBox<Map<String, dynamic>>('payments');

  final InvoiceRepository _invoiceRepository;
  final Future<Box<Map<String, dynamic>>> _paymentBoxFuture;

  static const _counterKey = '__payment_id_counter__';

  Future<Box<Map<String, dynamic>>> get _box => _paymentBoxFuture;

  @override
  Future<Payment> create(Payment payment) async {
    final box = await _box;
    final normalized = await _ensureId(payment, box);
    await box.put(normalized.id, normalized.toMap());
    await _applyPaymentToInvoice(normalized);
    return normalized;
  }

  @override
  Future<Payment?> fetch(String id) async {
    final box = await _box;
    final value = box.get(id);
    if (value is Map) {
      return Payment.fromMap(Map<String, dynamic>.from(value));
    }
    return null;
  }

  @override
  Future<List<Payment>> listByGarage(String garageId) async {
    final box = await _box;
    return box.values
        .whereType<Map>()
        .map((value) => Map<String, dynamic>.from(value))
        .where((map) => map['garageId'] == garageId)
        .map(Payment.fromMap)
        .toList(growable: false);
  }

  @override
  Stream<List<Payment>> watchByGarage(String garageId) async* {
    yield await listByGarage(garageId);
    final box = await _box;
    yield* box.watch().asyncMap((_) => listByGarage(garageId));
  }

  @override
  Future<void> delete(String id) async {
    final box = await _box;
    await box.delete(id);
  }

  Future<void> _applyPaymentToInvoice(Payment payment) async {
    final invoice = await _invoiceRepository.fetch(payment.invoiceId);
    if (invoice == null) return;
    final newAmountPaid = invoice.amountPaid + payment.amount;
    final balanceDue = invoice.total - newAmountPaid;
    final status = _deriveStatus(invoice.total, newAmountPaid);
    final updated = Invoice(
      id: invoice.id,
      garageId: invoice.garageId,
      quotationId: invoice.quotationId,
      jobCardId: invoice.jobCardId,
      customerId: invoice.customerId,
      vehicleId: invoice.vehicleId,
      invoiceNumber: invoice.invoiceNumber,
      status: status,
      subtotal: invoice.subtotal,
      vatAmount: invoice.vatAmount,
      total: invoice.total,
      amountPaid: newAmountPaid,
      balanceDue: balanceDue,
      pdfPath: invoice.pdfPath,
      createdAt: invoice.createdAt,
      updatedAt: DateTime.now(),
    );
    await _invoiceRepository.update(updated);
  }

  InvoiceStatus _deriveStatus(num total, num amountPaid) {
    if (amountPaid <= 0) return InvoiceStatus.unpaid;
    if (amountPaid < total) return InvoiceStatus.partial;
    return InvoiceStatus.paid;
  }

  Future<Payment> _ensureId(
    Payment payment,
    Box<Map<String, dynamic>> box,
  ) async {
    if (payment.id.isNotEmpty) return payment;
    final nextId = await _nextId(box);
    return Payment(
      id: nextId,
      garageId: payment.garageId,
      invoiceId: payment.invoiceId,
      amount: payment.amount,
      method: payment.method,
      paidAt: payment.paidAt,
      note: payment.note,
      createdAt: payment.createdAt,
    );
  }

  Future<String> _nextId(Box<Map<String, dynamic>> box) async {
    final current = (box.get(_counterKey) as int?) ?? 0;
    final next = current + 1;
    await box.put(_counterKey, next);
    return 'pay-$next';
  }
}
