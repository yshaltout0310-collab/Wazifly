import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';

/// Colour band for a 0–100 interview score.
Color scoreColor(int score) {
  if (score >= 80) return AppColors.emerald;
  if (score >= 60) return AppColors.warning;
  return AppColors.error;
}

/// A circular gauge for the headline (overall) score.
class OverallScoreGauge extends StatelessWidget {
  const OverallScoreGauge({required this.score, this.size = 96, super.key});

  final int score;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = scoreColor(score);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: (score / 100).clamp(0.0, 1.0)),
              duration: AppDurations.slow,
              curve: AppCurves.standard,
              builder: (context, value, _) => CircularProgressIndicator(
                value: value,
                strokeWidth: 8,
                backgroundColor: color.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$score',
                style: TextStyle(
                  fontSize: size * 0.32,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              if (size >= 72)
                Text('/100',
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.5))),
            ],
          ),
        ],
      ),
    );
  }
}

/// Labelled horizontal bars for the sub-dimension scores.
class ScoreBars extends StatelessWidget {
  const ScoreBars({required this.rows, super.key});

  final List<({String label, int value})> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        for (final r in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                SizedBox(
                  width: 120,
                  child: Text(r.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(
                          begin: 0, end: (r.value / 100).clamp(0.0, 1.0)),
                      duration: AppDurations.medium,
                      curve: AppCurves.standard,
                      builder: (context, value, _) => LinearProgressIndicator(
                        value: value,
                        minHeight: 8,
                        backgroundColor:
                            theme.colorScheme.outline.withValues(alpha: 0.25),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(scoreColor(r.value)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                SizedBox(
                  width: 30,
                  child: Text('${r.value}',
                      textAlign: TextAlign.end,
                      style: theme.textTheme.labelMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
