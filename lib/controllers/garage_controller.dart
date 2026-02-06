import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/garage_repository.dart';

final garageRepositoryProvider = Provider<GarageRepository>(
  (ref) => throw UnimplementedError('Provide a concrete GarageRepository'),
);

final garageControllerProvider =
    AutoDisposeAsyncNotifierProviderFamily<GarageController, Garage?, String>(
  GarageController.new,
);

class GarageController extends AutoDisposeAsyncNotifier<Garage?> {
  StreamSubscription<Garage?>? _garageSubscription;
  late String _garageId;

  @override
  FutureOr<Garage?> build(String garageId) {
    _garageId = garageId;
    state = const AsyncLoading();
    final repository = ref.watch(garageRepositoryProvider);

    _garageSubscription = repository.watchGarage(garageId).listen(
          (garage) => state = AsyncData(garage),
          onError: (error, stackTrace) => state = AsyncError(error, stackTrace),
        );

    ref.onDispose(() => _garageSubscription?.cancel());
    return repository.fetchGarage(garageId);
  }

  Future<void> createGarage(Garage garage) async {
    if (garage.id != _garageId) {
      throw ArgumentError.value(
        garage.id,
        'garage.id',
        'Garage id must match controller id $_garageId',
      );
    }
    _garageId = garage.id;
    state = const AsyncLoading();
    final repository = ref.read(garageRepositoryProvider);
    final result = await AsyncValue.guard<Garage?>(
      () => repository.createGarage(garage),
    );
    state = result;
  }

  Future<void> refresh() async {
    final repository = ref.read(garageRepositoryProvider);
    state = await AsyncValue.guard(() => repository.fetchGarage(_garageId));
  }

  Future<void> updateGarage(Garage garage) async {
    state = const AsyncLoading();
    final repository = ref.read(garageRepositoryProvider);
    final result = await AsyncValue.guard(() async {
      await repository.updateGarage(garage);
      return repository.fetchGarage(garage.id);
    });
    state = result;
  }

  Future<void> updatePlan(String plan) async {
    state = const AsyncLoading();
    final repository = ref.read(garageRepositoryProvider);
    final result = await AsyncValue.guard(() async {
      await repository.updatePlan(_garageId, plan);
      return repository.fetchGarage(_garageId);
    });
    state = result;
  }

  Future<void> incrementUsage({
    int jobCardsCreated = 0,
    int pdfExports = 0,
    int approvalsCreated = 0,
    int invoicesCreated = 0,
  }) async {
    final repository = ref.read(garageRepositoryProvider);
    state = await AsyncValue.guard(() async {
      await repository.incrementUsage(
        _garageId,
        jobCardsCreated: jobCardsCreated,
        pdfExports: pdfExports,
        approvalsCreated: approvalsCreated,
        invoicesCreated: invoicesCreated,
      );
      return repository.fetchGarage(_garageId);
    });
  }
}
