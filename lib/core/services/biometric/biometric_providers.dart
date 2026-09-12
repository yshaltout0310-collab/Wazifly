import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'biometric_service.dart';
import 'local_auth_biometric_service.dart';
import 'noop_biometric_service.dart';

/// The production [BiometricService]: `local_auth` on mobile/desktop, and an
/// always-unavailable no-op on the web, where `local_auth` registers no plugin
/// at all. Without the web branch the very first call would raise a
/// `MissingPluginException` inside the splash's biometric gate and the app
/// would never leave the splash. Mirrors `connectivityServiceProvider`.
///
/// Overridden in tests with a fake / Noop; this is the single swap point.
final biometricServiceProvider = Provider<BiometricService>((ref) {
  if (kIsWeb) return const NoopBiometricService();
  return LocalAuthBiometricService();
});
