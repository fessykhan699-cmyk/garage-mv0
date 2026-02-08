import '../models/invoice.dart';
import '../models/quotation.dart';
import '../repositories/garage_repository.dart';
import '../repositories/invoice_repository.dart';
import '../services/plan_gate.dart';

class InvoiceController {
  InvoiceController({
    required InvoiceRepository invoiceRepository,
    required GarageRepository garageRepository,
    PlanGate? planGate,
  })  : _invoiceRepository = invoiceRepository,
        _planGate = planGate ?? PlanGate(garageRepository);

  final InvoiceRepository _invoiceRepository;
  final PlanGate _planGate;

  Future<Invoice?> fetch(String id) => _invoiceRepository.fetch(id);

  Future<List<Invoice>> listByGarage(String garageId) =>
      _invoiceRepository.listByGarage(garageId);

  Stream<List<Invoice>> watchByGarage(String garageId) =>
      _invoiceRepository.watchByGarage(garageId);

  Future<Invoice> createFromQuotation(
    Quotation quotation, {
    String? invoiceNumber,
    String? pdfPath,
  }) async {
    await _ensurePdfAllowed(quotation.garageId, pdfPath);
    final now = DateTime.now();
    final invoice = Invoice(
      id: '',
      garageId: quotation.garageId,
      quotationId: quotation.id,
      jobCardId: quotation.jobCardId,
      customerId: quotation.customerId,
      vehicleId: quotation.vehicleId,
      invoiceNumber: invoiceNumber ?? _generateInvoiceNumber(now),
      status: InvoiceStatus.unpaid,
      subtotal: quotation.subtotal,
      discountAmount: quotation.discountAmount,
      vatAmount: quotation.vatAmount,
      total: quotation.total,
      amountPaid: 0,
      balanceDue: quotation.total,
      pdfPath: pdfPath,
      createdAt: now,
      updatedAt: now,
    );
    final created = await _invoiceRepository.create(invoice);
    await _planGate.recordUsage(
      quotation.garageId,
      invoicesCreated: 1,
      pdfExports: pdfPath != null ? 1 : 0,
    );
    return created;
  }

  Future<void> attachPdf(String invoiceId, String pdfPath) async {
    final invoice = await _invoiceRepository.fetch(invoiceId);
    if (invoice == null) {
      throw StateError('Invoice $invoiceId not found');
    }
    await _ensurePdfAllowed(invoice.garageId, pdfPath);
    final updated = Invoice(
      id: invoice.id,
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
      pdfPath: pdfPath,
      createdAt: invoice.createdAt,
      updatedAt: DateTime.now(),
    );
    await _invoiceRepository.update(updated);
    await _planGate.recordUsage(invoice.garageId, pdfExports: 1);
  }

  Future<void> _ensurePdfAllowed(String garageId, String? pdfPath) async {
    if (pdfPath == null) return;
    final allowed = await _planGate.canUseProForGarage(garageId);
    if (!allowed) {
      throw StateError('Pro plan required for invoice PDF');
    }
  }

  String _generateInvoiceNumber(DateTime now) =>
      'INV-${now.millisecondsSinceEpoch}';
}
