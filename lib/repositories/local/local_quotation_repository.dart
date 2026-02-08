import 'dart:async';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../../core/local_storage.dart';
import '../../models/quotation.dart';
import '../quotation_repository.dart';

class LocalQuotationRepository implements QuotationRepository {
  LocalQuotationRepository();

  final _uuid = const Uuid();
  final _streamController = StreamController<List<Quotation>>.broadcast();

  Future<Box<Map<String, dynamic>>> get _box => LocalStorage.quotationsBox();

  @override
  Future<Quotation> create(Quotation quotation) async {
    final box = await _box;
    final quotationData = quotation.toMap(useIsoFormat: true);
    await box.put(quotation.id, quotationData);
    _notifyListeners();
    return quotation;
  }

  @override
  Future<Quotation?> fetch(String id) async {
    final box = await _box;
    final data = box.get(id);
    if (data == null) return null;
    return Quotation.fromMap(Map<String, dynamic>.from(data));
  }

  @override
  Future<List<Quotation>> listByGarage(String garageId) async {
    final box = await _box;
    final quotations = <Quotation>[];
    for (var key in box.keys) {
      final data = box.get(key);
      if (data != null) {
        final quotation = Quotation.fromMap(Map<String, dynamic>.from(data));
        if (quotation.garageId == garageId) {
          quotations.add(quotation);
        }
      }
    }
    return quotations;
  }

  @override
  Stream<List<Quotation>> watchByGarage(String garageId) async* {
    // Initial data
    yield await listByGarage(garageId);
    
    // Listen to changes
    await for (final _ in _streamController.stream) {
      yield await listByGarage(garageId);
    }
  }

  @override
  Future<void> update(Quotation quotation) async {
    final box = await _box;
    final quotationData = quotation.toMap(useIsoFormat: true);
    await box.put(quotation.id, quotationData);
    _notifyListeners();
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
