import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';

/// A titled analytics section: an icon + heading followed by [child].
class AnalyticsSection extends StatelessWidget {
  const AnalyticsSection({
    required this.icon,
    required this.title,
    required this.child,
    this.trailing,
    super.key,
  });

  final IconData icon;
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(title,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        child,
      ],
    );
  }
}

/// A bordered surface card used across the analytics screen.
class AnalyticsCard extends StatelessWidget {
  const AnalyticsCard({required this.child, this.accent, super.key});

  final Widget child;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: accent?.withValues(alpha: 0.4) ??
              theme.colorScheme.outline.withValues(alpha: 0.5),
        ),
        boxShadow: AppShadows.card(dark: dark),
      ),
      child: child,
    );
  }
}

/// A compact KPI tile: value on top, label under, optional [icon].
class KpiTile extends StatelessWidget {
  const KpiTile({
    required this.label,
    required this.value,
    this.icon,
    super.key,
  });

  final String label;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border:
            Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
        boxShadow: AppShadows.card(dark: dark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: theme.colorScheme.primary),
            const SizedBox(height: 6),
          ],
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
        ],
      ),
    );
  }
}

/// One row of a horizontal bar chart (funnel stage / distribution band).
class AnalyticsBar {
  const AnalyticsBar({
    required this.label,
    required this.count,
    required this.fraction,
    required this.color,
    this.trailing,
  });

  final String label;
  final int count;

  /// Bar width as a share of the track, in `[0, 1]`.
  final double fraction;
  final Color color;

  /// Optional secondary text shown after the count (e.g. "42%").
  final String? trailing;
}

/// A stacked list of labeled horizontal bars. RTL-safe: bars grow from the
/// reading start via a directional alignment.
class HorizontalBars extends StatelessWidget {
  const HorizontalBars({required this.bars, super.key});

  final List<AnalyticsBar> bars;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        for (var i = 0; i < bars.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.md),
          _BarRow(bar: bars[i], theme: theme),
        ],
      ],
    );
  }
}

class _BarRow extends StatelessWidget {
  const _BarRow({required this.bar, required this.theme});

  final AnalyticsBar bar;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final trackColor = theme.colorScheme.onSurface.withValues(alpha: 0.06);
    final fraction = bar.fraction.clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(bar.label,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ),
            Text('${bar.count}',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
            if (bar.trailing != null) ...[
              const SizedBox(width: 6),
              Text(bar.trailing!,
                  style: theme.textTheme.bodySmall?.copyWith(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.55))),
            ],
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: Stack(
            children: [
              Container(height: 10, color: trackColor),
              FractionallySizedBox(
                alignment: AlignmentDirectional.centerStart,
                widthFactor: fraction == 0 ? 0.001 : fraction,
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: bar.color,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A simple vertical bar chart for the weekly applications trend. Bars are laid
/// oldest → newest (Row flips them in RTL automatically).
class MiniBarChart extends StatelessWidget {
  const MiniBarChart({
    required this.values,
    required this.labels,
    this.height = 96,
    super.key,
  });

  final List<int> values;
  final List<String> labels;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxV = values.fold(0, (m, v) => v > m ? v : m);
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < values.length; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Text('${values[i]}',
                        style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6))),
                    const SizedBox(height: 4),
                    // The bar fills the flexible middle area proportionally, so
                    // the fixed labels above/below never overflow the height.
                    Expanded(
                      child: FractionallySizedBox(
                        alignment: Alignment.bottomCenter,
                        heightFactor:
                            maxV == 0 ? 0.02 : (values[i] / maxV).clamp(0.02, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: AppColors.ctaGradient,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      i < labels.length ? labels[i] : '',
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                      style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 9,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.5)),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A small priority pill used on suggested-action tiles.
class PriorityChip extends StatelessWidget {
  const PriorityChip({required this.label, required this.color, super.key});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(label,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: color, fontWeight: FontWeight.w700)),
    );
  }
}
