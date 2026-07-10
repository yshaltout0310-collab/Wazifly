/// Whether biometric (or device-credential) authentication can be used on this
/// device right now.
enum BiometricCapability {
  /// Hardware present and at least one biometric (or device credential) enrolled.
  available,

  /// Hardware present but nothing enrolled — offer to set it up in system
  /// settings; the option is shown but disabled with an explanation.
  notEnrolled,

  /// No supported hardware — the option is hidden entirely.
  unavailable,
}

/// Outcome of a single authentication attempt.
enum BiometricAuthResult {
  success,

  /// Presented but not satisfied (wrong finger/face, or the user dismissed it).
  failed,

  /// Cannot authenticate because nothing is available/enrolled.
  unavailable,

  /// Too many failed attempts — temporarily or permanently locked out.
  lockedOut,
}

/// Vendor-neutral biometric / device-credential authentication.
///
/// Wraps `local_auth` behind a plain-Dart interface (the only impl importing the
/// plugin is [LocalAuthBiometricService]); a Noop impl reports "unavailable" so
/// the app degrades gracefully. This gate only guards access to the already-
/// persisted Firebase session — it never stores or replaces credentials.
abstract interface class BiometricService {
  /// What the device can do right now (checked before offering/enforcing).
  Future<BiometricCapability> capability();

  /// Prompts the OS biometric/device-credential sheet. [reason] is shown to the
  /// user (localized by the caller).
  Future<BiometricAuthResult> authenticate({required String reason});
}
