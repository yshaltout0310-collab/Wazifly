/// Vendor-neutral secure key/value storage.
///
/// Backed on-device by the OS secure store (Android Keystore /
/// EncryptedSharedPreferences, iOS Keychain) via [FlutterSecureStore]; an
/// in-memory impl is used in tests. Only the single Firebase-style impl imports
/// the plugin, keeping the rest of the app platform-agnostic (the `AiService`
/// seam pattern).
///
/// This is intentionally the "swap the backing store to secure storage later"
/// seam that [LocalStorageService] anticipated. It stores ONLY non-credential
/// markers (the biometric preference + trusted-device id) — never passwords or
/// session tokens (Firebase persists its own session securely).
abstract interface class SecureStore {
  /// Reads a string value, or null if absent.
  Future<String?> read(String key);

  /// Writes a string value.
  Future<void> write(String key, String value);

  /// Reads a boolean (stored as `'true'`/`'false'`), defaulting when absent.
  Future<bool> readBool(String key, {bool defaultValue = false});

  /// Writes a boolean.
  Future<void> writeBool(String key, {required bool value});

  /// Deletes a single key.
  Future<void> delete(String key);

  /// Clears every value this app stored (used on logout / remove-trusted-device).
  Future<void> deleteAll();
}
