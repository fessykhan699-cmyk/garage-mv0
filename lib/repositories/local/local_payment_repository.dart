import 'dart:async';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../../core/local_storage.dart';
import '../../models/payment.dart';
import '../payment_repository.dart';

class LocalPaymentRepository implements PaymentRepository {
  LocalPaymentRepository();

  final _uuid = const Uuid();
  final _streamController = StreamController<List<Payment>>.broadcast();

  Future<Box<Map<String, dynamic>>> get _box => LocalStorage.paymentsBox();

  @override
  Future<Payment> create(Payment payment) async {
    final box = await _box;
    final paymentData = payment.toMap(useIsoFormat: true);
    await box.put(payment.id, paymentData);
    _notifyListeners();
    return payment;
  }

  @override
  Future<Payment?> fetch(String id) async {
    final box = await _box;
    final data = box.get(id);
    if (data == null) return null;
    return Payment.fromMap(Map<String, dynamic>.from(data));
  }

  @override
  Future<List<Payment>> listByGarage(String garageId) async {
    final box = await _box;
    final payments = <Payment>[];
    for (var key in box.keys) {
      final data = box.get(key);
      if (data != null) {
        final payment = Payment.fromMap(Map<String, dynamic>.from(data));
        if (payment.garageId == garageId) {
          payments.add(payment);
        }
      }
    }
    return payments;
  }

  @override
  Stream<List<Payment>> watchByGarage(String garageId) async* {
    // Initial data
    yield await listByGarage(garageId);
    
    // Listen to changes
    await for (final _ in _streamController.stream) {
      yield await listByGarage(garageId);
    }
  }

  @override
  Future<void> delete(String id) async {
    final box = await _box;
    await box.delete(id);
    _notifyListeners();
  }

  void _notifyListeners() {
    _streamController.add([]);
  }

  void dispose() {
    _streamController.close();
  }
}
