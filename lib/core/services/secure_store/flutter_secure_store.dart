import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'secure_store.dart';

/// [SecureStore] backed by `flutter_secure_storage` — the ONLY file importing
/// that plugin. On Android it uses EncryptedSharedPreferences (AES via the
/// Keystore); on iOS the Keychain.
class FlutterSecureStore implements SecureStore {
  FlutterSecureStore([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<bool> readBool(String key, {bool defaultValue = false}) async {
    final raw = await _storage.read(key: key);
    if (raw == null) return defaultValue;
    return raw == 'true';
  }

  @override
  Future<void> writeBool(String key, {required bool value}) =>
      _storage.write(key: key, value: value ? 'true' : 'false');

  @override
  Future<void> delete(String key) => _storage.delete(key: key);

  @override
  Future<void> deleteAll() => _storage.deleteAll();
}
