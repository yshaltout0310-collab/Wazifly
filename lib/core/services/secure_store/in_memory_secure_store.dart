import 'secure_store.dart';

/// In-memory [SecureStore] for tests (and the Noop fallback). Never touches the
/// platform keychain.
class InMemorySecureStore implements SecureStore {
  final Map<String, String> _values = {};

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async => _values[key] = value;

  @override
  Future<bool> readBool(String key, {bool defaultValue = false}) async {
    final raw = _values[key];
    if (raw == null) return defaultValue;
    return raw == 'true';
  }

  @override
  Future<void> writeBool(String key, {required bool value}) async =>
      _values[key] = value ? 'true' : 'false';

  @override
  Future<void> delete(String key) async => _values.remove(key);

  @override
  Future<void> deleteAll() async => _values.clear();
}
