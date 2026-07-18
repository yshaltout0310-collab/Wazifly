import 'package:flutter/material.dart';

/// Central brand color palette for **Wazifly**.
///
/// Canonical brand colors (from the Wazifly brand board) are declared first:
/// Deep Navy (anchor), Royal Blue (interactive/CTA), Sky Blue (accent),
/// Teal (support/success) and Mist Gray (neutral). Only raw color values live
/// here; semantic mapping happens in [AppTheme].
///
/// **Legacy accessor names** (`emerald*`, `mint`, `lime`, `deepSea`) are kept as
/// aliases that now point at the Wazifly palette. They exist purely so the
/// ~130 existing call sites keep working unchanged — updating a value here
/// repaints the whole app with no churn. New code should prefer the canonical
/// names ([royalBlue], [navy], [skyBlue], [teal], [mist]).
abstract final class AppColors {
  AppColors._();

  // --- Wazifly brand palette (canonical) -----------------------------------
  /// Deep Navy — dark anchor: splash + app-icon background, headings, dark UI.
  static const Color navy = Color(0xFF0B1D3A);

  /// Royal Blue — interactive / CTA primary: buttons, links, selection, FAB.
  static const Color royalBlue = Color(0xFF1677FF);

  /// A deeper Royal Blue for gradient ends, pressed states and shadows.
  static const Color royalBlueDark = Color(0xFF0B54C4);

  /// Sky Blue — accent / highlight / gradient endpoint (matches the W mark).
  static const Color skyBlue = Color(0xFF00C2FF);

  /// Mist Gray — neutral light background / hairline outlines.
  static const Color mist = Color(0xFFE6EBF1);

  // --- Legacy aliases (kept to avoid churn; map onto the Wazifly palette) ---
  static const Color emerald = royalBlue; // primary / CTA
  static const Color emeraldDark = royalBlueDark; // secondary / gradient end
  static const Color emeraldLight = skyBlue; // gradient start / bright accent
  static const Color emeraldSoft = Color(0xFFD6E9FF); // soft brand tint

  static const Color teal = Color(0xFF00B59C); // support / success (Wazifly)
  static const Color lime = skyBlue;
  static const Color mint = skyBlue; // bright gradient start
  static const Color deepSea = navy;

  // --- Neutrals: Light (cool, blue-tinted to suit the navy/blue brand) -----
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color lightBackground = Color(0xFFF6F8FB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFEDF1F7);
  static const Color lightOutline = Color(0xFFD5DDE8);
  static const Color lightTextPrimary = Color(0xFF0B1D3A); // Deep Navy
  static const Color lightTextSecondary = Color(0xFF5A6B85);

  // --- Neutrals: Dark (deep navy, not neutral gray) ------------------------
  static const Color darkBackground = Color(0xFF0A1526);
  static const Color darkSurface = Color(0xFF0F1E33);
  static const Color darkSurfaceVariant = Color(0xFF182A44);
  static const Color darkOutline = Color(0xFF29394F);
  static const Color darkTextPrimary = Color(0xFFEDF1F8);
  static const Color darkTextSecondary = Color(0xFF9DAEC4);

  // --- Status --------------------------------------------------------------
  static const Color error = Color(0xFFE5484D);
  static const Color success = teal; // semantic green-teal
  static const Color warning = Color(0xFFF5A623);

  // --- Gradients -----------------------------------------------------------
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [skyBlue, royalBlue, royalBlueDark],
  );

  /// Richer multi-stop gradient for hero CTAs (buttons, logo mark).
  static const LinearGradient ctaGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [skyBlue, royalBlue, royalBlueDark],
    stops: [0.0, 0.55, 1.0],
  );

  /// Soft aurora blobs for hero backgrounds (light theme).
  static const Color auroraLightA = Color(0xFFCDE6FF);
  static const Color auroraLightB = Color(0xFFE0EEFF);
  static const Color auroraLightC = Color(0xFFEDF4FF);

  /// Aurora blobs for dark theme.
  static const Color auroraDarkA = Color(0xFF0E3A6B);
  static const Color auroraDarkB = Color(0xFF102A4D);

  /// Translucent fills for glassmorphism surfaces.
  static Color glassLight = white.withValues(alpha: 0.55);
  static Color glassDark = const Color(0xFF14243D).withValues(alpha: 0.55);
}
