import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/router/app_router.dart';
import 'core/session.dart';
import 'services/local_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize local storage (Hive)
  await LocalStorage.init();
  
  // Initialize Firebase
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

  runApp(const ProviderScope(child: GarageApp()));
}

const FirebaseOptions _webFirebaseOptions = FirebaseOptions(
  apiKey: String.fromEnvironment('FIREBASE_API_KEY'),
  appId: String.fromEnvironment('FIREBASE_APP_ID'),
  messagingSenderId: String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID'),
  projectId: String.fromEnvironment('FIREBASE_PROJECT_ID'),
  storageBucket: String.fromEnvironment('FIREBASE_STORAGE_BUCKET'),
);

class GarageApp extends ConsumerStatefulWidget {
  const GarageApp({super.key});

  @override
  ConsumerState<GarageApp> createState() => _GarageAppState();
}

class _GarageAppState extends ConsumerState<GarageApp> {
  @override
  void initState() {
    super.initState();
    // Initialize session from storage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sessionControllerProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    
    return MaterialApp.router(
      title: 'Garage MVP',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
