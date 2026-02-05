import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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

final _routerProvider = Provider<GoRouter>(
  (ref) => GoRouter(
    initialLocation: '/',
    routes: <GoRoute>[
      GoRoute(
        path: '/',
        builder: (context, state) => const _BootstrapHome(),
      ),
    ],
  ),
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
      routerConfig: ref.watch(_routerProvider),
    );
  }
}

class _BootstrapHome extends StatelessWidget {
  const _BootstrapHome();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Garage MVP')),
      body: const Center(
        child: Text('Bootstrap is ready. Add features next.'),
      ),
    );
  }
}
