import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'firebase_options.dart';

/// Owns Firebase app initialization for the whole app.
///
/// Initializes the Firebase app with the project's real credentials (generated
/// by `flutterfire configure`, see [firebase_options.dart]) and prepares Cloud
/// Messaging. [isReady] gates the Firestore + Storage layers. Crashlytics,
/// Performance and Analytics collection are wired in the app bootstrap (main /
/// app) via their providers, all best-effort.
class FirebaseService {
  FirebaseService._();
  static final FirebaseService instance = FirebaseService._();

  bool _initialized = false;

  /// True once the Firebase app has successfully initialized.
  bool get isReady => _initialized;

  Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _initialized = true;
      debugPrint('[FirebaseService] Initialized: '
          '${DefaultFirebaseOptions.currentPlatform.projectId}');

      // Pin the Firestore client cache explicitly (offline persistence is on by
      // default on mobile, but bounding it makes the production posture explicit
      // and serves warm re-entry — e.g. the employer dashboards — from cache
      // first). Must run before the first Firestore access. Best-effort.
      _configureFirestore();

      // Cloud Messaging is deliberately NOT bootstrapped here.
      //
      // This method is awaited before `runApp`, and messaging's own
      // `initialize()` awaits `requestPermission()`. On web that shows the
      // browser's native notification prompt and does not resolve until the
      // user answers it — so a visitor who ignored the prompt never reached the
      // first frame at all, staring at a blank page. `getToken()` then needs a
      // service worker the app does not ship. Messaging now starts after
      // `runApp`, un-awaited, from `main` (see `_bootstrapNotifications`).
    } catch (e) {
      debugPrint('[FirebaseService] Init failed: $e');
    }
  }

  /// Bounded offline cache (40 MB) with persistence on. Wrapped so a settings
  /// failure never aborts initialization.
  void _configureFirestore() {
    try {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: 40 * 1024 * 1024,
      );
    } catch (e) {
      debugPrint('[FirebaseService] Firestore settings failed: $e');
    }
  }
}
