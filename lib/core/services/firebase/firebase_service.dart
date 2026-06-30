import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../messaging/messaging_service.dart';
import 'firebase_options.dart';

/// Owns Firebase app initialization for the whole app.
///
/// Initializes the Firebase app with the project's real credentials (generated
/// by `flutterfire configure`, see [firebase_options.dart]) and prepares Cloud
/// Messaging. [isReady] gates the Firestore profile layer.
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

      // Prepare Cloud Messaging (permissions + token). Best-effort.
      await MessagingService.instance.initialize();
    } catch (e) {
      debugPrint('[FirebaseService] Init failed: $e');
    }
  }
}
