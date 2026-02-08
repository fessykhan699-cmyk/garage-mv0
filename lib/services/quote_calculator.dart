import '../models/line_item.dart';

class QuoteTotals {
  const QuoteTotals({
    required this.subtotal,
    required this.discountAmount,
    required this.vatAmount,
    required this.total,
  });

  final num subtotal;
  final num discountAmount;
  final num vatAmount;
  final num total;
}

class QuoteCalculator {
  QuoteCalculator._();

  static const num _defaultVatRate = 0.05;

  static QuoteTotals calculateTotals({
    required List<LineItem> laborItems,
    required List<LineItem> partItems,
    required bool vatEnabled,
    num discountAmount = 0,
    num? vatRate,
  }) {
    final subtotal = _sumTotals(laborItems) + _sumTotals(partItems);
    final sanitizedDiscount = _sanitizeDiscount(subtotal, discountAmount);
    final effectiveVatRate =
        resolveVatRate(vatEnabled: vatEnabled, vatRate: vatRate);
    final taxableSubtotal = subtotal - sanitizedDiscount;
    final vatAmount = taxableSubtotal * effectiveVatRate;
    final total = taxableSubtotal + vatAmount;
    return QuoteTotals(
      subtotal: subtotal,
      discountAmount: sanitizedDiscount,
      vatAmount: vatAmount,
      total: total,
    );
  }

  static num resolveVatRate({required bool vatEnabled, num? vatRate}) {
    if (!vatEnabled) return 0;
    return vatRate ?? _defaultVatRate;
  }

  static num _sumTotals(List<LineItem> items) =>
      items.fold<num>(0, (sum, item) => sum + item.total);

  static num _sanitizeDiscount(num subtotal, num discountAmount) {
    if (discountAmount is double && discountAmount.isNaN) return 0;
    if (discountAmount < 0) return 0;
    if (discountAmount > subtotal) return subtotal;
    return discountAmount;
  }
}
