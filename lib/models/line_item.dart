class LineItem {
  const LineItem({
    required this.name,
    required this.qty,
    required this.rate,
    required this.total,
  });

  final String name;
  final num qty;
  final num rate;
  final num total;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'qty': qty,
      'rate': rate,
      'total': total,
    };
  }

  factory LineItem.fromMap(Map<String, dynamic> map) {
    return LineItem(
      name: map['name'] as String,
      qty: _parseNum(map['qty']),
      rate: _parseNum(map['rate']),
      total: _parseNum(map['total']),
    );
  }
}

num _parseNum(dynamic value) {
  if (value is num) return value;
  if (value is String) {
    final parsed = num.tryParse(value);
    if (parsed != null) return parsed;
  }
  throw ArgumentError('Invalid numeric value: $value');
}
