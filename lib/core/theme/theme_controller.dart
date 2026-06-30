import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import '../services/storage/storage_keys.dart';

/// Holds the active [ThemeMode] and persists changes.
///
/// Reads the saved preference on construction so the user's choice survives
/// restarts. Defaults to [ThemeMode.system].
class ThemeController extends StateNotifier<ThemeMode> {
  ThemeController(this._ref) : super(ThemeMode.system) {
    _load();
  }

  final Ref _ref;

  void _load() {
    final stored =
        _ref.read(localStorageProvider).getString(StorageKeys.themeMode);
    state = _decode(stored);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await _ref
        .read(localStorageProvider)
        .setString(StorageKeys.themeMode, mode.name);
  }

  Future<void> toggle() => setThemeMode(
        state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
      );

  static ThemeMode _decode(String? value) => switch (value) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
}

final themeControllerProvider =
    StateNotifierProvider<ThemeController, ThemeMode>(
  ThemeController.new,
);
