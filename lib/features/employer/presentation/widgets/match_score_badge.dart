import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';

/// A compact colored pill showing an applicant's AI match score.
class MatchScoreBadge extends StatelessWidget {
  const MatchScoreBadge({required this.score, this.dense = false, super.key});

  final int score;
  final bool dense;

  static Color colorFor(int score) {
    if (score >= 80) return AppColors.emerald;
    if (score >= 60) return AppColors.teal;
    if (score >= 40) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = colorFor(score);
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: dense ? 7 : 9, vertical: dense ? 2 : 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.insights_rounded, size: dense ? 12 : 14, color: color),
          const SizedBox(width: 3),
          Text(
            '$score%',
            style: (dense ? theme.textTheme.labelSmall : theme.textTheme.labelMedium)
                ?.copyWith(color: color, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
