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
    final name = map['name'];
    if (name is! String) {
      throw ArgumentError('Required field name must be a String');
    }
    return LineItem(
      name: name,
      qty: _parseNum(_requireValue(map, 'qty')),
      rate: _parseNum(_requireValue(map, 'rate')),
      total: _parseNum(_requireValue(map, 'total')),
    );
  }
}

dynamic _requireValue(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value != null) return value;
  throw ArgumentError('Missing required field: $key');
}

num _parseNum(dynamic value) {
  if (value is num) return value;
  if (value is String) {
    final parsed = num.tryParse(value);
    if (parsed != null) return parsed;
  }
  throw ArgumentError('Invalid numeric value: $value');
}
