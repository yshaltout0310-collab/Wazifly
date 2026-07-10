/// Keys for sensitive on-device values held in [SecureStore].
///
/// Kept separate from [StorageKeys] (SharedPreferences) so it is obvious which
/// values live in the encrypted store. NONE of these are credentials — only the
/// biometric preference + a trusted-device marker.
abstract final class SecureKeys {
  SecureKeys._();

  /// `true` when the user has enabled biometric login on this device.
  static const String biometricEnabled = 'sec_biometric_enabled';

  /// `true` once the user tapped "Not Now" on the enable prompt, so we don't
  /// re-ask after every sign-in (they can still enable it from Security
  /// Settings). Cleared when biometric is enabled or on logout.
  static const String biometricPromptDeclined = 'sec_biometric_prompt_declined';

  /// Opaque marker identifying this device as "trusted" while biometric login
  /// is enabled. Cleared on logout / remove-trusted-device.
  static const String trustedDeviceId = 'sec_trusted_device_id';
}
