import '../models/payment.dart';

abstract class PaymentRepository {
  Future<Payment> create(Payment payment);
  Future<Payment?> fetch(String id);
  Future<List<Payment>> listByGarage(String garageId);
  Stream<List<Payment>> watchByGarage(String garageId);
  Future<void> delete(String id);
}
