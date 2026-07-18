import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';

/// Wazifly brand mark: the "W" logo on a rounded Deep Navy tile.
///
/// The W image is generated from `assets/brand/wazifly_logo.svg` (the single
/// source of truth) into `assets/images/wazifly_mark.png`; replacing the SVG and
/// re-running the raster script updates every surface, including this widget.
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
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: AppColors.royalBlue.withValues(alpha: 0.35),
            blurRadius: size * 0.35,
            offset: Offset(0, size * 0.14),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(size * 0.14),
        child: Image.asset(
          'assets/images/wazifly_mark.png',
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
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
