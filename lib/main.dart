import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/providers/app_providers.dart';
import 'core/services/firebase/firebase_service.dart';
import 'core/services/storage/local_storage_service.dart';

/// Application entry point.
///
/// Bootstraps persistence and (optionally) Firebase, then runs the app with a
/// Riverpod [ProviderScope] whose storage provider is overridden with the
/// already-loaded instance.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load persisted preferences (theme, language, country, onboarding flag).
  final storage = await LocalStorageService.create();

  // Prepared, but no-ops until real Firebase config is added (see
  // firebase_options.dart). Never blocks startup.
  await FirebaseService.instance.initialize();

  runApp(
    ProviderScope(
      overrides: [
        localStorageProvider.overrideWithValue(storage),
      ],
      child: const CareerBridgeApp(),
    ),
  );
}
