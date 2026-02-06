import '../models/job_card.dart';
import '../repositories/garage_repository.dart';
import '../repositories/job_card_repository.dart';
import '../services/plan_gate.dart';

class JobCardsController {
  JobCardsController({
    required JobCardRepository jobCardRepository,
    required GarageRepository garageRepository,
    PlanGate? planGate,
  })  : _jobCardRepository = jobCardRepository,
        _garageRepository = garageRepository,
        _planGate = planGate ?? PlanGate(garageRepository);

  final JobCardRepository _jobCardRepository;
  final GarageRepository _garageRepository;
  final PlanGate _planGate;

  static const int _freePlanJobCardLimit = 3;

  Future<JobCard> create(JobCard jobCard) async {
    await _enforceJobCardLimit(jobCard.garageId);
    final created = await _jobCardRepository.create(jobCard);
    try {
      await _planGate.recordUsage(
        created.garageId,
        jobCardsCreated: 1,
      );
    } catch (error, stackTrace) {
      try {
        await _jobCardRepository.delete(created.id);
      } catch (_) {
        // Best-effort rollback; preserve the original error context.
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
    return created;
  }

  Future<JobCard?> fetch(String id) => _jobCardRepository.fetch(id);

  Future<List<JobCard>> listByGarage(String garageId) =>
      _jobCardRepository.listByGarage(garageId);

  Stream<List<JobCard>> watchByGarage(String garageId) =>
      _jobCardRepository.watchByGarage(garageId);

  Future<void> update(JobCard jobCard) => _jobCardRepository.update(jobCard);

  Future<void> delete(String id) => _jobCardRepository.delete(id);

  Future<void> _enforceJobCardLimit(String garageId) async {
    final garage = await _garageRepository.fetchGarage(garageId);
    final isPro = _planGate.canUseProFeatures(garage?.plan);
    if (isPro) return;

    final usageCount = garage?.usage['jobCardsCreated'];
    final createdCount = _parseUsageCount(usageCount);
    if (createdCount >= _freePlanJobCardLimit) {
      throw StateError(
        'Free plan limit of $_freePlanJobCardLimit job cards reached. Upgrade to Pro to add more job cards.',
      );
    }
  }

  int _parseUsageCount(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    throw StateError(
      'Invalid usage count for job cards. Expected int, found ${value.runtimeType}. '
      'Please retry or contact support if the issue persists.',
    );
  }
}
