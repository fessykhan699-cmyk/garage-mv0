import '../models/line_item.dart';
import '../models/quotation.dart';
import '../repositories/quotation_repository.dart';
import '../services/quote_calculator.dart';

class QuotationController {
  QuotationController({
    required QuotationRepository quotationRepository,
  }) : _quotationRepository = quotationRepository;

  final QuotationRepository _quotationRepository;

  Future<Quotation> create({
    required String garageId,
    required String jobCardId,
    required String customerId,
    required String vehicleId,
    required String quoteNumber,
    List<LineItem> laborItems = const [],
    List<LineItem> partItems = const [],
    bool vatEnabled = false,
    num? vatRate,
    QuoteStatus status = QuoteStatus.draft,
    String id = '',
    String? pdfPath,
    bool? pdfWatermarked,
    String? approvalTokenId,
    DateTime? approvedAt,
    DateTime? rejectedAt,
    String? customerComment,
  }) async {
    final now = DateTime.now();
    final normalized = _normalize(
      Quotation(
        id: id,
        garageId: garageId,
        jobCardId: jobCardId,
        customerId: customerId,
        vehicleId: vehicleId,
        quoteNumber: quoteNumber,
        status: status,
        laborItems: laborItems,
        partItems: partItems,
        vatEnabled: vatEnabled,
        vatRate: QuoteCalculator.resolveVatRate(
          vatEnabled: vatEnabled,
          vatRate: vatRate,
        ),
        subtotal: 0,
        vatAmount: 0,
        total: 0,
        pdfPath: pdfPath,
        pdfWatermarked: pdfWatermarked,
        approvalTokenId: approvalTokenId,
        approvedAt: approvedAt,
        rejectedAt: rejectedAt,
        customerComment: customerComment,
        createdAt: now,
        updatedAt: now,
      ),
    );

    return _quotationRepository.create(normalized);
  }

  Future<Quotation?> fetch(String id) => _quotationRepository.fetch(id);

  Future<List<Quotation>> listByGarage(String garageId) =>
      _quotationRepository.listByGarage(garageId);

  Stream<List<Quotation>> watchByGarage(String garageId) =>
      _quotationRepository.watchByGarage(garageId);

  Future<void> update(Quotation quotation) async {
    final normalized = _normalize(quotation);
    await _quotationRepository.update(normalized);
  }

  Future<void> delete(String id) => _quotationRepository.delete(id);

  Quotation _normalize(Quotation quotation) {
    final totals = QuoteCalculator.calculateTotals(
      laborItems: quotation.laborItems,
      partItems: quotation.partItems,
      vatEnabled: quotation.vatEnabled,
      vatRate: quotation.vatRate,
    );
    return Quotation(
      id: quotation.id,
      garageId: quotation.garageId,
      jobCardId: quotation.jobCardId,
      customerId: quotation.customerId,
      vehicleId: quotation.vehicleId,
      quoteNumber: quotation.quoteNumber,
      status: quotation.status,
      laborItems: quotation.laborItems,
      partItems: quotation.partItems,
      vatEnabled: quotation.vatEnabled,
      vatRate: QuoteCalculator.resolveVatRate(
        vatEnabled: quotation.vatEnabled,
        vatRate: quotation.vatRate,
      ),
      subtotal: totals.subtotal,
      vatAmount: totals.vatAmount,
      total: totals.total,
      pdfPath: quotation.pdfPath,
      pdfWatermarked: quotation.pdfWatermarked,
      approvalTokenId: quotation.approvalTokenId,
      approvedAt: quotation.approvedAt,
      rejectedAt: quotation.rejectedAt,
      customerComment: quotation.customerComment,
      createdAt: quotation.createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
