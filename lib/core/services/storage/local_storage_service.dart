import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Thin, typed wrapper around [SharedPreferences].
///
/// Centralizing access here keeps persistence logic out of UI/state code and
/// makes it trivial to swap the backing store (e.g. secure storage) later.
class LocalStorageService {
  LocalStorageService(this._prefs);

  final SharedPreferences _prefs;

  /// Loads the singleton instance. Call once during app bootstrap.
  static Future<LocalStorageService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalStorageService(prefs);
  }

  String? getString(String key) => _prefs.getString(key);
  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);

  bool getBool(String key, {bool defaultValue = false}) =>
      _prefs.getBool(key) ?? defaultValue;
  Future<void> setBool(String key, {required bool value}) =>
      _prefs.setBool(key, value);

  Map<String, dynamic>? getJson(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> setJson(String key, Map<String, dynamic> value) =>
      _prefs.setString(key, jsonEncode(value));

  Future<void> remove(String key) => _prefs.remove(key);
}
