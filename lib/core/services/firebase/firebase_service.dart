import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../messaging/firebase_notification_service.dart';
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

      // Prepare Cloud Messaging (permissions + token). Best-effort.
      await FirebaseNotificationService.instance.initialize();
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
