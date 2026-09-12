import 'package:flutter/services.dart' show PlatformException;
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:local_auth/local_auth.dart';

import 'biometric_service.dart';

/// [BiometricService] backed by `local_auth` — the ONLY file importing that
/// plugin. Supports fingerprint / Face ID and (via `biometricOnly: false`)
/// device-credential (PIN / pattern / passcode) fallback.
class LocalAuthBiometricService implements BiometricService {
  LocalAuthBiometricService([LocalAuthentication? auth])
      : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<BiometricCapability> capability() async {
    try {
      final supported = await _auth.isDeviceSupported();
      if (!supported) return BiometricCapability.unavailable;
      final canCheck = await _auth.canCheckBiometrics;
      final enrolled = await _auth.getAvailableBiometrics();
      if (canCheck && enrolled.isNotEmpty) return BiometricCapability.available;
      // Device-credential (PIN/passcode) can still satisfy authentication even
      // when no biometric is enrolled; treat that as "not enrolled" for the UI
      // (option shown, disabled, with an explanation) rather than unavailable.
      return BiometricCapability.notEnrolled;
    } catch (_) {
      // Any failure means "can't offer biometrics here" — a PlatformException
      // from the OS, or a MissingPluginException on a platform where local_auth
      // registers nothing. This call sits in the splash's launch gate, so it
      // must never throw: an escaping error would leave the app on the splash.
      return BiometricCapability.unavailable;
    }
  }

  @override
  Future<BiometricAuthResult> authenticate({required String reason}) async {
    try {
      final ok = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true, // survive app backgrounding during the prompt
          biometricOnly: false, // allow device-credential fallback
        ),
      );
      return ok ? BiometricAuthResult.success : BiometricAuthResult.failed;
    } on PlatformException catch (e) {
      return switch (e.code) {
        auth_error.notAvailable ||
        auth_error.notEnrolled ||
        auth_error.passcodeNotSet =>
          BiometricAuthResult.unavailable,
        auth_error.lockedOut || auth_error.permanentlyLockedOut =>
          BiometricAuthResult.lockedOut,
        // Includes user cancellation and other transient failures — the caller
        // keeps the lock screen up with a "sign in another way" fallback.
        _ => BiometricAuthResult.failed,
      };
    } catch (_) {
      // No plugin on this platform (or any other non-platform failure).
      return BiometricAuthResult.unavailable;
    }
  }
}
