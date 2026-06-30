import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';

/// Frosted-glass surface: a translucent, blurred card with a hairline border.
/// Used for elevated content over the aurora background to add depth.
class GlassCard extends StatelessWidget {
  const GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.radius = AppRadius.lg,
    this.blur = 18,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double blur;

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: dark ? AppColors.glassDark : AppColors.glassLight,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: scheme.onSurface.withValues(alpha: dark ? 0.08 : 0.06),
            ),
            boxShadow: AppShadows.card(dark: dark),
          ),
          child: child,
        ),
      ),
    );
  }
}
