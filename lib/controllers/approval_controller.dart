import '../models/quotation.dart';
import '../repositories/approval_repository.dart';
import '../repositories/quotation_repository.dart';

/// Coordinates customer approval decisions with quotations.
///
/// This controller keeps the approval token and quotation in sync by updating
/// both layers whenever a customer approves or rejects a quotation.
class ApprovalController {
  ApprovalController({
    required ApprovalRepository approvalRepository,
    required QuotationRepository quotationRepository,
  })  : _approvalRepository = approvalRepository,
        _quotationRepository = quotationRepository;

  final ApprovalRepository _approvalRepository;
  final QuotationRepository _quotationRepository;

  /// Fetch a token once.
  Future<ApprovalToken?> fetchToken(String tokenId) {
    return _approvalRepository.fetch(tokenId);
  }

  /// Watch live updates for a token.
  Stream<ApprovalToken?> watchToken(String tokenId) {
    return _approvalRepository.watch(tokenId);
  }

  /// Create a new approval token for a quotation and attach it back to the
  /// quotation record.
  Future<ApprovalToken> createToken({
    required String garageId,
    required String quotationId,
    DateTime? expiresAt,
  }) async {
    final created = await _approvalRepository.create(
      ApprovalToken(
        id: '',
        garageId: garageId,
        quotationId: quotationId,
        createdAt: DateTime.now(),
        expiresAt: expiresAt,
      ),
    );
    await _attachTokenToQuotation(created);
    return created;
  }

  /// Approve the quotation linked to [tokenId].
  Future<ApprovalDecision> approve(
    String tokenId, {
    String? customerComment,
  }) {
    return _decide(
      tokenId: tokenId,
      status: ApprovalStatus.approved,
      customerComment: customerComment,
    );
  }

  /// Reject the quotation linked to [tokenId].
  Future<ApprovalDecision> reject(
    String tokenId, {
    String? customerComment,
  }) {
    return _decide(
      tokenId: tokenId,
      status: ApprovalStatus.rejected,
      customerComment: customerComment,
    );
  }

  Future<ApprovalDecision> _decide({
    required String tokenId,
    required ApprovalStatus status,
    String? customerComment,
  }) async {
    final token = await _approvalRepository.fetch(tokenId);
    if (token == null) {
      throw StateError('Approval token not found: $tokenId');
    }
    if (token.expiresAt != null && token.expiresAt!.isBefore(DateTime.now())) {
      throw StateError('Approval token $tokenId has expired');
    }
    if (token.status != ApprovalStatus.pending) {
      throw StateError(
        'Approval token $tokenId has already been decided with status: ${token.status}',
      );
    }

    final now = DateTime.now();
    final updatedToken = token.copyWith(
      status: status,
      customerComment: customerComment ?? token.customerComment,
      decidedAt: token.decidedAt ?? now,
      used: true,
      usedAt: token.usedAt ?? now,
    );
    await _approvalRepository.update(updatedToken);

    final quotation = await _quotationRepository.fetch(token.quotationId);
    final updatedQuotation = quotation == null
        ? null
        : _updateQuotationWithDecision(
            quotation: quotation,
            tokenId: token.id,
            decision: status,
            customerComment: customerComment,
          );
    if (updatedQuotation != null) {
      await _quotationRepository.update(updatedQuotation);
    }

    return ApprovalDecision(
      token: updatedToken,
      quotation: updatedQuotation,
    );
  }

  Future<void> _attachTokenToQuotation(ApprovalToken token) async {
    final quotation = await _quotationRepository.fetch(token.quotationId);
    if (quotation == null) return;

    final updated = Quotation(
      id: quotation.id,
      garageId: quotation.garageId,
      jobCardId: quotation.jobCardId,
      customerId: quotation.customerId,
      vehicleId: quotation.vehicleId,
      quoteNumber: quotation.quoteNumber,
      status: quotation.status == QuoteStatus.draft
          ? QuoteStatus.sent
          : quotation.status,
      laborItems: quotation.laborItems,
      partItems: quotation.partItems,
      vatEnabled: quotation.vatEnabled,
      vatRate: quotation.vatRate,
      subtotal: quotation.subtotal,
      vatAmount: quotation.vatAmount,
      total: quotation.total,
      pdfPath: quotation.pdfPath,
      pdfWatermarked: quotation.pdfWatermarked,
      approvalTokenId: token.id,
      approvedAt: quotation.approvedAt,
      rejectedAt: quotation.rejectedAt,
      customerComment: quotation.customerComment,
      createdAt: quotation.createdAt,
      updatedAt: DateTime.now(),
    );
    await _quotationRepository.update(updated);
  }

  Quotation _updateQuotationWithDecision({
    required Quotation quotation,
    required String tokenId,
    required ApprovalStatus decision,
    required String? customerComment,
  }) {
    final isApproved = decision == ApprovalStatus.approved;
    final now = DateTime.now();

    return Quotation(
      id: quotation.id,
      garageId: quotation.garageId,
      jobCardId: quotation.jobCardId,
      customerId: quotation.customerId,
      vehicleId: quotation.vehicleId,
      quoteNumber: quotation.quoteNumber,
      status: isApproved ? QuoteStatus.approved : QuoteStatus.rejected,
      laborItems: quotation.laborItems,
      partItems: quotation.partItems,
      vatEnabled: quotation.vatEnabled,
      vatRate: quotation.vatRate,
      subtotal: quotation.subtotal,
      vatAmount: quotation.vatAmount,
      total: quotation.total,
      pdfPath: quotation.pdfPath,
      pdfWatermarked: quotation.pdfWatermarked,
      approvalTokenId: quotation.approvalTokenId ?? tokenId,
      approvedAt: isApproved ? (quotation.approvedAt ?? now) : null,
      rejectedAt: isApproved ? null : (quotation.rejectedAt ?? now),
      customerComment: customerComment ?? quotation.customerComment,
      createdAt: quotation.createdAt,
      updatedAt: now,
    );
  }
}

/// Result of an approval decision, containing both the token and the
/// (optional) updated quotation.
class ApprovalDecision {
  const ApprovalDecision({
    required this.token,
    this.quotation,
  });

  final ApprovalToken token;
  final Quotation? quotation;
}
