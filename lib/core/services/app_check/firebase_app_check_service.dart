import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart'
    show debugPrint, kDebugMode, kIsWeb, visibleForTesting;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firebase/firebase_service.dart';
import '../service_diagnostics.dart';
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
  Future<bool>? _activation;
  bool _activated = false;

  /// reCAPTCHA **Enterprise** site key used to attest the web build, injected
  /// at build time:
  ///
  /// ```bash
  /// flutter build web --release --dart-define=RECAPTCHA_SITE_KEY=<site-key>
  /// ```
  ///
  /// **Enterprise, not v3.** Firebase AI Logic accepts only reCAPTCHA
  /// Enterprise as the web attestation provider — reCAPTCHA v3 is still a valid
  /// App Check provider in general (and is not deprecated), but it is not an
  /// accepted provider for AI Logic, so a v3 key would leave every AI feature
  /// denied on the web build. The key must therefore be a **score-based
  /// reCAPTCHA Enterprise** site key.
  ///
  /// Web has no device attestation to fall back on, so without a provider the
  /// web client is unattested — fatal now that App Check enforcement is
  /// required for Firebase AI Logic. A reCAPTCHA site key is public by design
  /// (it is served inside the page) but is environment-specific, so it is
  /// injected rather than committed. When absent, behaviour is unchanged: no
  /// web provider, and activation degrades without blocking startup.
  static const String webRecaptchaSiteKey =
      String.fromEnvironment('RECAPTCHA_SITE_KEY');

  /// Whether a web attestation provider can be supplied on this build.
  static bool get hasWebProvider => kIsWeb && webRecaptchaSiteKey.isNotEmpty;

  @override
  Future<bool> activate() {
    if (_activated) return Future.value(true);
    // Bootstrap and an early protected request share one in-flight activation.
    return _activation ??= _activate().whenComplete(() => _activation = null);
  }

  Future<bool> _activate() async {
    // Emitted BEFORE activation: on web with no site key the plugin call itself
    // throws, so a warning placed after it would never run — exactly in the
    // case it is meant to explain.
    if (kIsWeb && !hasWebProvider) {
      debugPrint('[AppCheck] web build has no RECAPTCHA_SITE_KEY - this client '
          'is UNATTESTED and will be denied by any backend with App Check '
          'enforced (including Firebase AI Logic). Rebuild with '
          '--dart-define=RECAPTCHA_SITE_KEY=<site-key>.');
      return false;
    }
    try {
      // Debug builds attest with the debug provider (register the printed debug
      // token in the Firebase Console → App Check). Release builds use Play
      // Integrity on Android / Device Check on iOS. Token auto-refresh is left
      // on so a short-lived token is transparently renewed.
      final providers = selectAppCheckProviders(
        isWeb: kIsWeb,
        isDebug: kDebugMode,
        webRecaptchaSiteKey: webRecaptchaSiteKey,
      );
      await _appCheck.activate(
        androidProvider: providers.androidProvider,
        appleProvider: providers.appleProvider,
        webProvider: providers.webProvider,
      );
      _activated = true;
      return true;
    } catch (error, stack) {
      logServiceFailure(
          service: 'AppCheck',
          operation: 'activate',
          error: error,
          stack: stack);
      return false;
    }
  }

  @override
  Future<String?> getToken({bool forceRefresh = false}) async {
    if (!await activate()) return null;
    try {
      return await _appCheck.getToken(forceRefresh);
    } catch (error, stack) {
      logServiceFailure(
          service: 'AppCheck',
          operation: 'getToken',
          error: error,
          stack: stack);
      return null;
    }
  }
}

/// Selects the App Check providers for the current platform and build mode.
///
/// Kept separate from plugin activation so provider choices can be covered by
/// unit tests without initializing Firebase or a platform channel.
@visibleForTesting
({
  AndroidProvider androidProvider,
  AppleProvider appleProvider,
  ReCaptchaEnterpriseProvider? webProvider,
}) selectAppCheckProviders({
  required bool isWeb,
  required bool isDebug,
  required String webRecaptchaSiteKey,
}) =>
    (
      androidProvider:
          isDebug ? AndroidProvider.debug : AndroidProvider.playIntegrity,
      appleProvider: isDebug ? AppleProvider.debug : AppleProvider.deviceCheck,
      webProvider: isWeb && webRecaptchaSiteKey.isNotEmpty
          ? ReCaptchaEnterpriseProvider(webRecaptchaSiteKey)
          : null,
    );

/// The app-wide App Check service: Firebase when the app is initialized, else an
/// inert no-op (tests / unconfigured runs never touch the plugin) — the same
/// gate as the other production services.
final appCheckServiceProvider = Provider<AppCheckService>(
  (ref) => FirebaseService.instance.isReady
      ? FirebaseAppCheckService()
      : const NoopAppCheckService(),
);
