import 'package:meta/meta.dart';

import '../repositories/garage_repository.dart';

class PlanGate {
  PlanGate(this._garageRepository);

  final GarageRepository _garageRepository;

  static const defaultPlan = 'free';

  String normalizePlan(String? plan) {
    if (plan == null || plan.isEmpty) return defaultPlan;
    return plan;
  }

  bool canUseProFeatures(String? plan) =>
      normalizePlan(plan).toLowerCase() == 'pro';

  Future<bool> canUseProForGarage(String garageId) async {
    final garage = await _garageRepository.fetchGarage(garageId);
    return canUseProFeatures(garage?.plan);
  }

  Future<Garage?> recordUsage(
    String garageId, {
    int jobCardsCreated = 0,
    int pdfExports = 0,
    int approvalsCreated = 0,
    int invoicesCreated = 0,
  }) async {
    await _garageRepository.incrementUsage(
      garageId,
      jobCardsCreated: jobCardsCreated,
      pdfExports: pdfExports,
      approvalsCreated: approvalsCreated,
      invoicesCreated: invoicesCreated,
    );
    return _garageRepository.fetchGarage(garageId);
  }

  @visibleForTesting
  Future<void> manualProToggle(String garageId, {required bool enable}) {
    return _garageRepository.updatePlan(
      garageId,
      enable ? 'pro' : defaultPlan,
    );
  }
}
