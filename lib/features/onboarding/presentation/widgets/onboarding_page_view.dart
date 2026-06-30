import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/utils/responsive.dart';
import '../../domain/onboarding_page.dart';

/// Renders one onboarding page: a gradient icon badge, title, body, and an
/// optional list of AI feature chips.
class OnboardingPageView extends StatelessWidget {
  const OnboardingPageView({required this.page, super.key});

  final OnboardingPage page;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ResponsiveCenter(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: context.horizontalGutter),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(AppRadius.lg + 8),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.emerald.withValues(alpha: 0.30),
                    blurRadius: 30,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: Icon(page.icon, size: 64, color: AppColors.white),
            ).animate().scale(
                  duration: 450.ms,
                  curve: Curves.easeOutBack,
                  begin: const Offset(0.7, 0.7),
                  end: const Offset(1, 1),
                ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              page.title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ).animate().fadeIn(delay: 120.ms).moveY(begin: 14, end: 0),
            const SizedBox(height: AppSpacing.md),
            Text(
              page.body,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                height: 1.5,
              ),
            ).animate().fadeIn(delay: 220.ms),
            if (page.features.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xl),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (var i = 0; i < page.features.length; i++)
                    _FeatureChip(feature: page.features[i])
                        .animate()
                        .fadeIn(delay: (300 + i * 90).ms)
                        .moveY(begin: 10, end: 0),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.feature});

  final ({IconData icon, String label}) feature;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(feature.icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Text(
            feature.label,
            style: theme.textTheme.labelLarge
                ?.copyWith(color: theme.colorScheme.primary),
          ),
        ],
      ),
    );
  }
}
