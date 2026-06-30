import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/languages_data.dart';
import '../providers/app_providers.dart';
import '../services/storage/storage_keys.dart';

/// Holds the active [Locale] and persists the user's language choice.
///
/// A null locale means "follow the device locale". Setting a locale writes the
/// language code so the selection survives restarts (language persistence).
class LocaleController extends StateNotifier<Locale?> {
  LocaleController(this._ref) : super(null) {
    _load();
  }

  final Ref _ref;

  void _load() {
    final code =
        _ref.read(localStorageProvider).getString(StorageKeys.languageCode);
    if (code != null && code.isNotEmpty) {
      state = Locale(code);
    }
  }

  Future<void> setLanguage(String code) async {
    state = Locale(code);
    await _ref
        .read(localStorageProvider)
        .setString(StorageKeys.languageCode, code);
  }

  /// Whether a language has been explicitly chosen (drives the welcome flow).
  bool get hasSelection =>
      _ref.read(localStorageProvider).getString(StorageKeys.languageCode) !=
          null;
}

final localeControllerProvider =
    StateNotifierProvider<LocaleController, Locale?>(
  LocaleController.new,
);

/// Locales the app currently ships translations for. Derived from the language
/// registry so enabling a language in one place flows everywhere.
final supportedLocales = LanguagesData.all
    .where((l) => l.isSupported)
    .map((l) => l.locale)
    .toList(growable: false);
