import 'dart:async';

import 'package:hive_flutter/hive_flutter.dart';

import '../../models/quotation.dart';
import '../../services/local_storage.dart';
import '../../services/plan_gate.dart';
import '../../services/quote_calculator.dart';
import '../garage_repository.dart';
import '../quotation_repository.dart';
import 'mock_garage_repository.dart';
import 'counter_utils.dart';

class MockQuotationRepository implements QuotationRepository {
  MockQuotationRepository({
    GarageRepository? garageRepository,
    PlanGate? planGate,
    Future<Box<Map<String, dynamic>>>? quotationBox,
  }) : _quotationBoxFuture =
            quotationBox ?? LocalStorage.openBox<Map<String, dynamic>>('quotations') {
    final repo = garageRepository ?? MockGarageRepository();
    _garageRepository = repo;
    _planGate = planGate ?? PlanGate(repo);
  }

  late final GarageRepository _garageRepository;
  late final PlanGate _planGate;
  final Future<Box<Map<String, dynamic>>> _quotationBoxFuture;

  static const _counterKey = '__quotation_id_counter__';

  Future<Box<Map<String, dynamic>>> get _box => _quotationBoxFuture;

  @override
  Future<Quotation> create(Quotation quotation) async {
    final box = await _box;
    final normalized = _normalize(await _ensureId(quotation, box));
    await _enforceProGates(normalized);
    await box.put(normalized.id, normalized.toMap());
    await _garageRepository.incrementUsage(
      normalized.garageId,
      jobCardsCreated: 0,
      pdfExports: normalized.pdfPath != null ? 1 : 0,
      approvalsCreated: normalized.approvalTokenId != null ? 1 : 0,
    );
    return normalized;
  }

  @override
  Future<Quotation?> fetch(String id) async {
    final box = await _box;
    final value = box.get(id);
    if (value is Map) {
      return Quotation.fromMap(Map<String, dynamic>.from(value));
    }
    return null;
  }

  @override
  Future<List<Quotation>> listByGarage(String garageId) async {
    final box = await _box;
    final items = box.values
        .whereType<Map>()
        .map((value) => Map<String, dynamic>.from(value))
        .where((map) => map['garageId'] == garageId)
        .map(Quotation.fromMap)
        .toList();
    
    // Sort by createdAt descending (newest first)
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  @override
  Stream<List<Quotation>> watchByGarage(String garageId) async* {
    yield await listByGarage(garageId);
    final box = await _box;
    yield* box.watch().asyncMap((_) => listByGarage(garageId));
  }

  @override
  Future<void> update(Quotation quotation) async {
    final normalized = _normalize(quotation);
    await _enforceProGates(normalized);
    final box = await _box;
    await box.put(normalized.id, normalized.toMap());
  }

  @override
  Future<void> delete(String id) async {
    final box = await _box;
    await box.delete(id);
  }

  Quotation _normalize(Quotation quotation) {
    final effectiveVatRate = QuoteCalculator.resolveVatRate(
      vatEnabled: quotation.vatEnabled,
      vatRate: quotation.vatRate,
    );
    final totals = QuoteCalculator.calculateTotals(
      laborItems: quotation.laborItems,
      partItems: quotation.partItems,
      vatEnabled: quotation.vatEnabled,
      vatRate: effectiveVatRate,
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
      vatRate: effectiveVatRate,
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
      updatedAt: quotation.updatedAt,
    );
  }

  Future<void> _enforceProGates(Quotation quotation) async {
    await _requireProIf(
      garageId: quotation.garageId,
      reason: 'PDF export',
      isBlocked: quotation.pdfPath != null || quotation.pdfWatermarked == true,
    );
    await _requireProIf(
      garageId: quotation.garageId,
      reason: 'approval token creation',
      isBlocked: quotation.approvalTokenId != null,
    );
    await _requireProIf(
      garageId: quotation.garageId,
      reason: 'WhatsApp share',
      isBlocked: quotation.status == QuoteStatus.sent,
    );
  }

  Future<void> _requireProIf({
    required String garageId,
    required String reason,
    required bool isBlocked,
  }) async {
    if (!isBlocked) return;
    final allowed = await _planGate.canUseProForGarage(garageId);
    if (!allowed) {
      throw StateError('Pro plan required for $reason');
    }
  }

  Future<Quotation> _ensureId(
    Quotation quotation,
    Box<Map<String, dynamic>> box,
  ) async {
    if (quotation.id.isNotEmpty) return quotation;
    final nextId = await _nextId(box);
    return Quotation(
      id: nextId,
      garageId: quotation.garageId,
      jobCardId: quotation.jobCardId,
      customerId: quotation.customerId,
      vehicleId: quotation.vehicleId,
      quoteNumber: quotation.quoteNumber,
      status: quotation.status,
      laborItems: quotation.laborItems,
      partItems: quotation.partItems,
      vatEnabled: quotation.vatEnabled,
      vatRate: quotation.vatRate,
      subtotal: quotation.subtotal,
      vatAmount: quotation.vatAmount,
      total: quotation.total,
      pdfPath: quotation.pdfPath,
      pdfWatermarked: quotation.pdfWatermarked,
      approvalTokenId: quotation.approvalTokenId,
      approvedAt: quotation.approvedAt,
      rejectedAt: quotation.rejectedAt,
      customerComment: quotation.customerComment,
      createdAt: quotation.createdAt,
      updatedAt: quotation.updatedAt,
    );
  }

  Future<String> _nextId(Box<Map<String, dynamic>> box) async {
    final next = await nextCounterValue(box, _counterKey);
    return 'quote-$next';
  }
}
