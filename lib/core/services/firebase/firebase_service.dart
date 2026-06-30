import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../messaging/messaging_service.dart';
import 'firebase_options.dart';

/// Owns Firebase app initialization for the whole app.
///
/// Initializes only when real credentials are present (detected via the
/// placeholder sentinel in [firebase_options.dart]). When unconfigured it
/// no-ops gracefully so the app still launches; the auth layer then exposes a
/// friendly "not configured" state. After `flutterfire configure`, real
/// initialization (and Messaging prep) activates with zero code changes.
class FirebaseService {
  FirebaseService._();
  static final FirebaseService instance = FirebaseService._();

  // Hardcoded here (not read from firebase_options) so detection survives a
  // FlutterFire overwrite of that file.
  static const String _placeholderApiKey = 'REPLACE_WITH_FIREBASE_CONFIG';

  bool _initialized = false;

  /// True when real Firebase credentials have been wired in.
  bool get isConfigured {
    final key = DefaultFirebaseOptions.currentPlatform.apiKey;
    return key.isNotEmpty && key != _placeholderApiKey;
  }

  /// True only when configured AND successfully initialized.
  bool get isReady => _initialized && isConfigured;

  Future<void> initialize() async {
    if (!isConfigured) {
      debugPrint(
        '[FirebaseService] No real config — running unconfigured. '
        'Run `flutterfire configure` to enable Firebase.',
      );
      return;
    }

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
