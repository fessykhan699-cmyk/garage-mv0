import 'dart:async';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../../core/local_storage.dart';
import '../../models/job_card.dart';
import '../job_card_repository.dart';

class LocalJobCardRepository implements JobCardRepository {
  LocalJobCardRepository();

  final _uuid = const Uuid();
  final _streamController = StreamController<List<JobCard>>.broadcast();

  Future<Box<Map<String, dynamic>>> get _box => LocalStorage.jobCardsBox();

  @override
  Future<JobCard> create(JobCard jobCard) async {
    final box = await _box;
    final jobCardData = jobCard.toMap(useIsoFormat: true);
    await box.put(jobCard.id, jobCardData);
    _notifyListeners();
    return jobCard;
  }

  @override
  Future<JobCard?> fetch(String id) async {
    final box = await _box;
    final data = box.get(id);
    if (data == null) return null;
    return JobCard.fromMap(Map<String, dynamic>.from(data));
  }

  @override
  Future<List<JobCard>> listByGarage(String garageId) async {
    final box = await _box;
    final jobCards = <JobCard>[];
    for (var key in box.keys) {
      final data = box.get(key);
      if (data != null) {
        final jobCard = JobCard.fromMap(Map<String, dynamic>.from(data));
        if (jobCard.garageId == garageId) {
          jobCards.add(jobCard);
        }
      }
    }
    return jobCards;
  }

  @override
  Stream<List<JobCard>> watchByGarage(String garageId) async* {
    // Initial data
    yield await listByGarage(garageId);
    
    // Listen to changes
    await for (final _ in _streamController.stream) {
      yield await listByGarage(garageId);
    }
  }

  @override
  Future<void> update(JobCard jobCard) async {
    final box = await _box;
    final jobCardData = jobCard.toMap(useIsoFormat: true);
    await box.put(jobCard.id, jobCardData);
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
