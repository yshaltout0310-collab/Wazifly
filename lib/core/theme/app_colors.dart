import 'package:flutter/material.dart';

/// Central brand color palette for Career Bridge.
///
/// Primary brand = Emerald Green, secondary = White, dark surface = Dark Gray.
/// Only raw color values live here; semantic mapping happens in [AppTheme].
abstract final class AppColors {
  AppColors._();

  // --- Brand: Emerald ------------------------------------------------------
  static const Color emerald = Color(0xFF0E9F6E);
  static const Color emeraldDark = Color(0xFF0B7D57);
  static const Color emeraldLight = Color(0xFF34D399);
  static const Color emeraldSoft = Color(0xFFD1FAE5);

  // --- Accent hues (used in mesh gradients & highlights) -------------------
  static const Color teal = Color(0xFF0BAFA0);
  static const Color lime = Color(0xFF7BD88F);
  static const Color mint = Color(0xFF5EEAD4);
  static const Color deepSea = Color(0xFF064E3B);

  // --- Neutrals: Light -----------------------------------------------------
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color lightBackground = Color(0xFFF7F9F8);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFEEF2F0);
  static const Color lightOutline = Color(0xFFD7DEDB);
  static const Color lightTextPrimary = Color(0xFF0F1A16);
  static const Color lightTextSecondary = Color(0xFF5B6B65);

  // --- Neutrals: Dark (Dark Gray) -----------------------------------------
  static const Color darkBackground = Color(0xFF101413);
  static const Color darkSurface = Color(0xFF1A1F1D);
  static const Color darkSurfaceVariant = Color(0xFF242B28);
  static const Color darkOutline = Color(0xFF333C39);
  static const Color darkTextPrimary = Color(0xFFF1F5F3);
  static const Color darkTextSecondary = Color(0xFFA6B2AD);

  // --- Status --------------------------------------------------------------
  static const Color error = Color(0xFFE5484D);
  static const Color success = emerald;
  static const Color warning = Color(0xFFF5A623);

  // --- Gradients -----------------------------------------------------------
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [emeraldLight, emerald, emeraldDark],
  );

  /// Richer multi-stop gradient for hero CTAs (buttons, logo tile).
  static const LinearGradient ctaGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [mint, emerald, emeraldDark],
    stops: [0.0, 0.55, 1.0],
  );

  /// Soft aurora blobs for hero backgrounds (light theme).
  static const Color auroraLightA = Color(0xFFB8F5DF);
  static const Color auroraLightB = Color(0xFFD7F2E9);
  static const Color auroraLightC = Color(0xFFEAF7F0);

  /// Aurora blobs for dark theme.
  static const Color auroraDarkA = Color(0xFF0E5A43);
  static const Color auroraDarkB = Color(0xFF103A30);

  /// Translucent fills for glassmorphism surfaces.
  static Color glassLight = white.withValues(alpha: 0.55);
  static Color glassDark = const Color(0xFF1C2421).withValues(alpha: 0.55);
}
