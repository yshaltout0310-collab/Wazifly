import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';

/// Brand mark: a rounded emerald-gradient tile with a "bridge" glyph.
///
/// Used on the splash screen and reusable anywhere the logo is needed.
class AppLogo extends StatelessWidget {
  const AppLogo({this.size = 96, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.ctaGradient,
        borderRadius: BorderRadius.circular(size * 0.30),
        boxShadow: [
          BoxShadow(
            color: AppColors.emerald.withValues(alpha: 0.45),
            blurRadius: size * 0.35,
            offset: Offset(0, size * 0.14),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Subtle top highlight for a glossy, premium finish.
          Positioned(
            top: size * 0.12,
            child: Container(
              width: size * 0.7,
              height: size * 0.28,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(size),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.white.withValues(alpha: 0.28),
                    AppColors.white.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Icon(Icons.hub_rounded, size: size * 0.52, color: AppColors.white),
        ],
      ),
    );
  }
}

/// Wordmark + tagline lockup.
class AppWordmark extends StatelessWidget {
  const AppWordmark({
    required this.title,
    this.subtitle,
    super.key,
  });

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ],
    );
  }
}
