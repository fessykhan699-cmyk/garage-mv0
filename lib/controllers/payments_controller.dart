import '../models/payment.dart';
import '../repositories/garage_repository.dart';
import '../repositories/invoice_repository.dart';
import '../repositories/payment_repository.dart';
import '../services/plan_gate.dart';

class PaymentsController {
  PaymentsController({
    required PaymentRepository paymentRepository,
    required InvoiceRepository invoiceRepository,
    required GarageRepository garageRepository,
    PlanGate? planGate,
  })  : _paymentRepository = paymentRepository,
        _invoiceRepository = invoiceRepository,
        _planGate = planGate ?? PlanGate(garageRepository);

  final PaymentRepository _paymentRepository;
  final InvoiceRepository _invoiceRepository;
  final PlanGate _planGate;

  Future<Payment?> fetch(String id) => _paymentRepository.fetch(id);

  Future<List<Payment>> listByGarage(String garageId) =>
      _paymentRepository.listByGarage(garageId);

  Stream<List<Payment>> watchByGarage(String garageId) =>
      _paymentRepository.watchByGarage(garageId);

  Future<List<Payment>> listForInvoice(String garageId, String invoiceId) async {
    final payments = await _paymentRepository.listByGarage(garageId);
    return payments
        .where((payment) => payment.invoiceId == invoiceId)
        .toList(growable: false);
  }

  Stream<List<Payment>> watchForInvoice(String garageId, String invoiceId) {
    return _paymentRepository.watchByGarage(garageId).map(
          (payments) => payments
              .where((payment) => payment.invoiceId == invoiceId)
              .toList(growable: false),
        );
  }

  Future<Payment> recordPayment(Payment payment) async {
    await _ensurePaymentsAllowed(payment.garageId);
    final invoice = await _invoiceRepository.fetch(payment.invoiceId);
    if (invoice == null) {
      throw StateError('Invoice ${payment.invoiceId} not found');
    }
    if (invoice.garageId != payment.garageId) {
      throw StateError('Payment garage does not match invoice garage');
    }
    if (payment.amount <= 0) {
      throw ArgumentError.value(payment.amount, 'amount', 'must be positive');
    }
    return _paymentRepository.create(payment);
  }

  Future<void> delete(String paymentId, {required String garageId}) async {
    await _ensurePaymentsAllowed(garageId);
    await _paymentRepository.delete(paymentId);
  }

  Future<void> _ensurePaymentsAllowed(String garageId) async {
    final allowed = await _planGate.canUseProForGarage(garageId);
    if (!allowed) {
      throw StateError('Pro plan required for payment tracking');
    }
  }
}
