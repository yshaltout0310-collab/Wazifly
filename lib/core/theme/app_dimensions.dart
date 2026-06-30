import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';

import 'app_colors.dart';

/// Design tokens for spacing, radii, and animation durations.
///
/// Keeping these centralized guarantees a consistent rhythm across every
/// screen and makes global tuning a one-line change.
abstract final class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

abstract final class AppRadius {
  AppRadius._();

  static const double sm = 10;
  static const double md = 16;
  static const double lg = 24;
  static const double pill = 999;
}

abstract final class AppDurations {
  AppDurations._();

  static const Duration fast = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 400);
  static const Duration slow = Duration(milliseconds: 700);
  static const Duration splash = Duration(milliseconds: 2400);
}

/// Signature easing curves for a consistent, premium motion language.
abstract final class AppCurves {
  AppCurves._();

  static const Curve emphasized = Cubic(0.2, 0.0, 0.0, 1.0);
  static const Curve standard = Curves.easeInOutCubic;
  static const Curve spring = Curves.easeOutBack;
}

/// Layered, emerald-tinted shadow tokens. Soft shadows read far more premium
/// than a single hard drop shadow.
abstract final class AppShadows {
  AppShadows._();

  static List<BoxShadow> soft({bool dark = false}) => [
        BoxShadow(
          color: (dark ? AppColors.black : AppColors.deepSea)
              .withValues(alpha: dark ? 0.40 : 0.06),
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
      ];

  static List<BoxShadow> card({bool dark = false}) => [
        BoxShadow(
          color: (dark ? AppColors.black : const Color(0xFF0B3A2C))
              .withValues(alpha: dark ? 0.45 : 0.05),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> brandGlow = [
    BoxShadow(
      color: AppColors.emerald.withValues(alpha: 0.45),
      blurRadius: 32,
      offset: const Offset(0, 16),
    ),
  ];
}
