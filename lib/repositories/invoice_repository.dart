import '../models/invoice.dart';

abstract class InvoiceRepository {
  Future<Invoice> create(Invoice invoice);
  Future<Invoice?> fetch(String id);
  Future<List<Invoice>> listByGarage(String garageId);
  Stream<List<Invoice>> watchByGarage(String garageId);
  Future<void> update(Invoice invoice);
  Future<void> delete(String id);
}
