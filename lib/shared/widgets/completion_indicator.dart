import 'package:flutter/material.dart';

import '../../core/localization/generated/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';

/// Compact completion card: a circular percentage ring plus a title and a
/// contextual hint (celebratory when complete, a nudge otherwise).
///
/// Shared by the job-seeker profile and the employer company profile. Pass
/// [title]/[nudge]/[complete] to override the default profile strings (the
/// company screens pass company-specific copy).
class CompletionIndicator extends StatelessWidget {
  const CompletionIndicator({
    required this.percent,
    this.title,
    this.nudge,
    this.complete,
    super.key,
  });

  /// Completion in `[0, 100]`.
  final int percent;

  /// Optional copy overrides (default to the profile strings when null).
  final String? title;
  final String? nudge;
  final String? complete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final dark = theme.brightness == Brightness.dark;
    final isComplete = percent >= 100;
    final ratio = (percent / 100).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border:
            Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
        boxShadow: AppShadows.card(dark: dark),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 56,
                  height: 56,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: ratio),
                    duration: AppDurations.slow,
                    curve: AppCurves.standard,
                    builder: (context, value, _) => CircularProgressIndicator(
                      value: value,
                      strokeWidth: 5,
                      backgroundColor:
                          theme.colorScheme.primary.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isComplete
                            ? AppColors.emerald
                            : theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                Text(
                  '$percent%',
                  style: theme.textTheme.labelMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title ?? l10n.profileCompletionTitle,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  isComplete
                      ? (complete ?? l10n.profileCompletionComplete)
                      : (nudge ?? l10n.profileCompletionNudge),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
