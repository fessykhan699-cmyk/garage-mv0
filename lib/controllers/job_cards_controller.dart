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
    await _planGate.recordUsage(created.garageId, jobCardsCreated: 1);
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

    final createdCount = garage?.usage['jobCardsCreated'] ?? 0;
    if (createdCount >= _freePlanJobCardLimit) {
      throw StateError('Free plan limited to $_freePlanJobCardLimit job cards');
    }
  }
}
