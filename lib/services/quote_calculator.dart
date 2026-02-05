import '../models/line_item.dart';

class QuoteTotals {
  const QuoteTotals({
    required this.subtotal,
    required this.vatAmount,
    required this.total,
  });

  final num subtotal;
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
    num? vatRate,
  }) {
    final subtotal = _sumTotals(laborItems) + _sumTotals(partItems);
    final effectiveVatRate = resolveVatRate(vatEnabled: vatEnabled, vatRate: vatRate);
    final vatAmount = subtotal * effectiveVatRate;
    final total = subtotal + vatAmount;
    return QuoteTotals(
      subtotal: subtotal,
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
}
