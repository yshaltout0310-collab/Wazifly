import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Builds a locale-aware [TextTheme].
///
/// Latin scripts use **Inter** (clean, modern, excellent for product UI);
/// Arabic uses **Cairo**, which has full, well-balanced Arabic glyph coverage.
/// Selecting the font by locale keeps both LTR and RTL text looking premium.
abstract final class AppTypography {
  AppTypography._();

  static const String _arabicLanguageCode = 'ar';

  static TextTheme textTheme(Locale locale, TextTheme base) {
    final TextTheme themed = locale.languageCode == _arabicLanguageCode
        ? GoogleFonts.cairoTextTheme(base)
        : GoogleFonts.interTextTheme(base);

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
