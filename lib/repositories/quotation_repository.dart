import '../models/quotation.dart';

abstract class QuotationRepository {
  Future<Quotation> create(Quotation quotation);
  Future<Quotation?> fetch(String id);
  Future<List<Quotation>> listByGarage(String garageId);
  Stream<List<Quotation>> watchByGarage(String garageId);
  Future<void> update(Quotation quotation);
  Future<void> delete(String id);
}
