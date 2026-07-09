import 'package:flutter/material.dart';

/// Builds a locale-aware [TextTheme].
///
/// Latin scripts use **Inter** (clean, modern, excellent for product UI);
/// Arabic uses **Cairo**, which has full, well-balanced Arabic glyph coverage.
/// Selecting the font by locale keeps both LTR and RTL text looking premium.
///
/// The fonts are **bundled** (`assets/fonts/Inter.ttf`, `assets/fonts/Cairo.ttf`,
/// declared in `pubspec.yaml`) rather than fetched at runtime, so text renders
/// correctly on a cold **offline** first launch (no network dependency, no
/// google_fonts fallback). Both are variable fonts — Flutter drives the weight
/// axis from each style's `fontWeight`, so every weight is available.
abstract final class AppTypography {
  AppTypography._();

  static const String _arabicLanguageCode = 'ar';
  static const String _interFamily = 'Inter';
  static const String _cairoFamily = 'Cairo';

  static TextTheme textTheme(Locale locale, TextTheme base) {
    final String family =
        locale.languageCode == _arabicLanguageCode ? _cairoFamily : _interFamily;
    final TextTheme themed = base.apply(fontFamily: family);

    return themed.copyWith(
      displayLarge: themed.displayLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      headlineMedium: themed.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      titleLarge: themed.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      labelLarge: themed.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
    );
  }
}
