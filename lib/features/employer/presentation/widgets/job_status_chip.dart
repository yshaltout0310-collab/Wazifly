import 'package:flutter/material.dart';

import '../../../../core/localization/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../domain/job_status.dart';
import '../employer_jobs_l10n.dart';

/// A small colored pill showing a posting's lifecycle [JobStatus].
class JobStatusChip extends StatelessWidget {
  const JobStatusChip({required this.status, this.dense = false, super.key});

  final JobStatus status;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final color = _color(status);

    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: dense ? 8 : 10, vertical: dense ? 3 : 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        status.label(l10n),
        style: (dense ? theme.textTheme.labelSmall : theme.textTheme.labelMedium)
            ?.copyWith(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }

  static Color _color(JobStatus status) => switch (status) {
        JobStatus.draft => AppColors.warning,
        JobStatus.published => AppColors.emerald,
        JobStatus.archived => AppColors.teal,
        JobStatus.closed => AppColors.error,
      };
}
