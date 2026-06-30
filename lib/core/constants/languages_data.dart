import 'package:flutter/material.dart';

import '../../shared/models/language_model.dart';

/// Registry of languages the app knows about.
///
/// [popular] surfaces first on the language screen; [all] is the searchable
/// long list. Flip `isSupported` to true (and add an `app_<code>.arb` file)
/// to fully enable a language — the architecture imposes no limit.
abstract final class LanguagesData {
  LanguagesData._();

  static const List<LanguageModel> popular = [
    LanguageModel(
      code: 'en',
      englishName: 'English',
      nativeName: 'English',
      textDirection: TextDirection.ltr,
    ),
    LanguageModel(
      code: 'ar',
      englishName: 'Arabic',
      nativeName: 'العربية',
      textDirection: TextDirection.rtl,
    ),
  ];

  /// Additional languages shown under "More Languages". Not yet translated
  /// (isSupported: false) but ready to enable.
  static const List<LanguageModel> more = [
    LanguageModel(
      code: 'fr',
      englishName: 'French',
      nativeName: 'Français',
      textDirection: TextDirection.ltr,
      isSupported: false,
    ),
    LanguageModel(
      code: 'es',
      englishName: 'Spanish',
      nativeName: 'Español',
      textDirection: TextDirection.ltr,
      isSupported: false,
    ),
    LanguageModel(
      code: 'de',
      englishName: 'German',
      nativeName: 'Deutsch',
      textDirection: TextDirection.ltr,
      isSupported: false,
    ),
    LanguageModel(
      code: 'tr',
      englishName: 'Turkish',
      nativeName: 'Türkçe',
      textDirection: TextDirection.ltr,
      isSupported: false,
    ),
    LanguageModel(
      code: 'ur',
      englishName: 'Urdu',
      nativeName: 'اردو',
      textDirection: TextDirection.rtl,
      isSupported: false,
    ),
    LanguageModel(
      code: 'hi',
      englishName: 'Hindi',
      nativeName: 'हिन्दी',
      textDirection: TextDirection.ltr,
      isSupported: false,
    ),
    LanguageModel(
      code: 'zh',
      englishName: 'Chinese',
      nativeName: '中文',
      textDirection: TextDirection.ltr,
      isSupported: false,
    ),
    LanguageModel(
      code: 'id',
      englishName: 'Indonesian',
      nativeName: 'Bahasa Indonesia',
      textDirection: TextDirection.ltr,
      isSupported: false,
    ),
  ];

  static List<LanguageModel> get all => [...popular, ...more];
}
