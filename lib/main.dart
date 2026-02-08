import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/providers/repository_providers.dart' as repo_providers;
import 'app/router/app_router.dart';
import 'controllers/auth_controller.dart' as auth_controller;
import 'controllers/garage_controller.dart' as garage_controller;
import 'services/local_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStorage.init();
  const useFirebase = bool.fromEnvironment('USE_FIREBASE', defaultValue: false);
  if (useFirebase) {
    if (kIsWeb) {
      assert(
        _webFirebaseOptions.apiKey.isNotEmpty &&
            _webFirebaseOptions.appId.isNotEmpty &&
            _webFirebaseOptions.messagingSenderId.isNotEmpty &&
            _webFirebaseOptions.projectId.isNotEmpty,
        'Provide Firebase web configuration via --dart-define variables.',
      );
      await Firebase.initializeApp(options: _webFirebaseOptions);
    } else {
      await Firebase.initializeApp();
    }
  }

  runApp(
    ProviderScope(
      overrides: [
        auth_controller.authRepositoryProvider.overrideWith(
          (ref) => ref.read(repo_providers.authRepositoryProvider),
        ),
        garage_controller.garageRepositoryProvider.overrideWith(
          (ref) => ref.read(repo_providers.garageRepositoryProvider),
        ),
      ],
      child: const GarageApp(),
    ),
  );
}

const FirebaseOptions _webFirebaseOptions = FirebaseOptions(
  apiKey: String.fromEnvironment('FIREBASE_API_KEY'),
  appId: String.fromEnvironment('FIREBASE_APP_ID'),
  messagingSenderId: String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID'),
  projectId: String.fromEnvironment('FIREBASE_PROJECT_ID'),
  storageBucket: String.fromEnvironment('FIREBASE_STORAGE_BUCKET'),
);

class GarageApp extends ConsumerWidget {
  const GarageApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Garage MVP',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
      ),
      routerConfig: AppRouter.router,
    );
  }
}
