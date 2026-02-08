import 'dart:async';

import 'package:hive_flutter/hive_flutter.dart';

import '../../models/job_card.dart';
import '../../services/local_storage.dart';
import '../job_card_repository.dart';
import 'counter_utils.dart';

class MockJobCardRepository implements JobCardRepository {
  MockJobCardRepository({
    Future<Box<Map<String, dynamic>>>? jobCardBox,
  }) : _jobCardBoxFuture =
            jobCardBox ?? LocalStorage.openBox<Map<String, dynamic>>('jobCards');

  final Future<Box<Map<String, dynamic>>> _jobCardBoxFuture;

  static const _counterKey = '__job_card_id_counter__';

  Future<Box<Map<String, dynamic>>> get _box => _jobCardBoxFuture;

  @override
  Future<JobCard> create(JobCard jobCard) async {
    final box = await _box;
    final normalized = await _ensureId(jobCard, box);
    await box.put(normalized.id, normalized.toMap());
    return normalized;
  }

  @override
  Future<JobCard?> fetch(String id) async {
    final box = await _box;
    final value = box.get(id);
    if (value is Map) {
      return JobCard.fromMap(Map<String, dynamic>.from(value));
    }
    return null;
  }

  @override
  Future<List<JobCard>> listByGarage(String garageId) async {
    final box = await _box;
    final items = box.values
        .whereType<Map>()
        .map((value) => Map<String, dynamic>.from(value))
        .where((map) => map['garageId'] == garageId)
        .map(JobCard.fromMap)
        .toList();
    
    // Sort by createdAt descending (newest first)
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  @override
  Stream<List<JobCard>> watchByGarage(String garageId) async* {
    yield await listByGarage(garageId);
    final box = await _box;
    yield* box.watch().asyncMap((_) => listByGarage(garageId));
  }

  @override
  Future<void> update(JobCard jobCard) async {
    final box = await _box;
    await box.put(jobCard.id, jobCard.toMap());
  }

  @override
  Future<void> delete(String id) async {
    final box = await _box;
    await box.delete(id);
  }

  Future<JobCard> _ensureId(
    JobCard jobCard,
    Box<Map<String, dynamic>> box,
  ) async {
    if (jobCard.id.isNotEmpty) return jobCard;
    final nextId = await _nextId(box);
    return JobCard(
      id: nextId,
      garageId: jobCard.garageId,
      customerId: jobCard.customerId,
      vehicleId: jobCard.vehicleId,
      jobCardNumber: jobCard.jobCardNumber,
      complaint: jobCard.complaint,
      notes: jobCard.notes,
      beforePhotoPaths: jobCard.beforePhotoPaths,
      afterPhotoPaths: jobCard.afterPhotoPaths,
      status: jobCard.status,
      createdAt: jobCard.createdAt,
      updatedAt: jobCard.updatedAt,
    );
  }

  Future<String> _nextId(Box<Map<String, dynamic>> box) async {
    final next = await nextCounterValue(box, _counterKey);
    return 'job-$next';
  }
}
