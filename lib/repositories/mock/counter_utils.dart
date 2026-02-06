import 'package:hive_flutter/hive_flutter.dart';

Future<int> nextCounterValue(
  Box<Map<String, dynamic>> box,
  String counterKey,
) async {
  final entry = box.get(counterKey);
  int current = 0;
  if (entry is Map<String, dynamic>) {
    final value = entry['value'];
    if (value is int) current = value;
  } else if (entry is int) {
    current = entry;
  }

  final next = current + 1;
  await box.put(counterKey, {'value': next});
  return next;
}
