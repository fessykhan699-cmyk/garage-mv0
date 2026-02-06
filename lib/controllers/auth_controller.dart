import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => throw UnimplementedError('Provide a concrete AuthRepository'),
);

final authControllerProvider =
    AutoDisposeAsyncNotifierProvider<AuthController, AuthUser?>(
  AuthController.new,
);

class AuthController extends AutoDisposeAsyncNotifier<AuthUser?> {
  StreamSubscription<AuthUser?>? _authSubscription;

  @override
  FutureOr<AuthUser?> build() {
    final repository = ref.watch(authRepositoryProvider);

    _authSubscription = repository.authStateChanges().listen(
          (user) => state = AsyncData(user),
          onError: (error, stackTrace) => state = AsyncError(error, stackTrace),
        );

    ref.onDispose(() => _authSubscription?.cancel());
    return repository.currentUser();
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    final repository = ref.read(authRepositoryProvider);
    final result = await AsyncValue.guard<AuthUser?>(
      () => repository.signIn(email: email, password: password),
    );
    state = result;
  }

  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    final repository = ref.read(authRepositoryProvider);
    final result = await AsyncValue.guard<AuthUser?>(
      () => repository.signUp(email: email, password: password),
    );
    state = result;
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    final repository = ref.read(authRepositoryProvider);
    final result = await AsyncValue.guard<AuthUser?>(() async {
      await repository.signOut();
      return null;
    });
    state = result;
  }
}
