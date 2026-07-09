import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firebase/firebase_service.dart';
import 'app_check_service.dart';
import 'noop_app_check_service.dart';

/// Firebase App Check implementation of [AppCheckService] — the **only** file
/// that imports `firebase_app_check`. All calls are wrapped so a failure can
/// never block startup: [activate] returns false instead of throwing, and the
/// bootstrap records that failure and continues (the app stays usable, just
/// unattested).
class FirebaseAppCheckService implements AppCheckService {
  FirebaseAppCheckService([FirebaseAppCheck? appCheck])
      : _appCheck = appCheck ?? FirebaseAppCheck.instance;

  final FirebaseAppCheck _appCheck;

  @override
  Future<bool> activate() async {
    try {
      // Debug builds attest with the debug provider (register the printed debug
      // token in the Firebase Console → App Check). Release builds use Play
      // Integrity on Android / Device Check on iOS. Token auto-refresh is left
      // on so a short-lived token is transparently renewed.
      await _appCheck.activate(
        androidProvider:
            kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
        appleProvider:
            kDebugMode ? AppleProvider.debug : AppleProvider.deviceCheck,
      );
      return true;
    } catch (e) {
      debugPrint('[AppCheck] activate failed: $e');
      return false;
    }
  }

  @override
  Future<String?> getToken({bool forceRefresh = false}) async {
    try {
      return await _appCheck.getToken(forceRefresh);
    } catch (e) {
      debugPrint('[AppCheck] getToken failed: $e');
      return null;
    }
  }
}

/// The app-wide App Check service: Firebase when the app is initialized, else an
/// inert no-op (tests / unconfigured runs never touch the plugin) — the same
/// gate as the other production services.
final appCheckServiceProvider = Provider<AppCheckService>(
  (ref) => FirebaseService.instance.isReady
      ? FirebaseAppCheckService()
      : const NoopAppCheckService(),
);
