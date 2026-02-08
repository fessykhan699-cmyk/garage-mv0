import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/auth_controller.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/garage_repository.dart';
import 'repository_providers.dart';

final activeUserProvider = Provider<AuthUser?>(
  (ref) => ref.watch(authControllerProvider).value,
);

final activeGarageIdProvider = Provider<String?>(
  (ref) => ref.watch(activeUserProvider)?.garageId,
);

final activeGarageProvider = StreamProvider<Garage?>((ref) {
  final garageId = ref.watch(activeGarageIdProvider);
  if (garageId == null || garageId.isEmpty) {
    return Stream<Garage?>.empty();
  }
  return ref.watch(garageRepositoryProvider).watchGarage(garageId);
});
