import 'package:flutter/material.dart';

import '../../../../core/theme/app_dimensions.dart';
import '../../domain/resume_analysis.dart';

/// A titled result card (Strengths, Weaknesses, …) with an accent icon, a count
/// badge, and arbitrary [child] content.
class AnalysisSection extends StatelessWidget {
  const AnalysisSection({
    required this.title,
    required this.icon,
    required this.accent,
    required this.count,
    required this.child,
    super.key,
  });

  final String title;
  final IconData icon;
  final Color accent;
  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
        boxShadow: AppShadows.card(dark: dark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, color: accent, size: 20),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  '$count',
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: accent, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

/// Renders a list of strings as accent-marked bullet rows.
class BulletItems extends StatelessWidget {
  const BulletItems({required this.items, required this.accent, this.icon, super.key});

  final List<String> items;
  final Color accent;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < items.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == items.length - 1 ? 0 : 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(icon ?? Icons.circle, size: icon != null ? 18 : 7,
                      color: accent),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    items[i],
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Renders grammar issues as "issue → suggestion" tiles.
class GrammarIssueList extends StatelessWidget {
  const GrammarIssueList({
    required this.issues,
    required this.accent,
    required this.suggestionLabel,
    super.key,
  });

  final List<GrammarIssue> issues;
  final Color accent;
  final String suggestionLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < issues.length; i++)
          Container(
            width: double.infinity,
            margin: EdgeInsets.only(bottom: i == issues.length - 1 ? 0 : AppSpacing.sm),
            padding: const EdgeInsets.all(AppSpacing.sm + 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  issues[i].issue,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600, height: 1.35),
                ),
                if (issues[i].suggestion.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      style: theme.textTheme.bodySmall
                          ?.copyWith(height: 1.35, color: theme.colorScheme.onSurface),
                      children: [
                        TextSpan(
                          text: '$suggestionLabel: ',
                          style: TextStyle(
                              color: accent, fontWeight: FontWeight.w700),
                        ),
                        TextSpan(text: issues[i].suggestion),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
