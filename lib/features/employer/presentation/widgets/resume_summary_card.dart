import 'package:flutter/material.dart';

import '../../../../core/localization/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../shared/models/applicant_snapshot.dart';

/// The applicant's denormalized resume-analysis summary: ATS score + top
/// strengths + summary. Reuses the resume analysis captured at apply time (never
/// re-runs AI, never reads the applicant's private analysis doc).
class ResumeSummaryCard extends StatelessWidget {
  const ResumeSummaryCard({required this.snapshot, super.key});

  final ApplicantSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    if (!snapshot.hasResumeAnalysis) {
      return Text(
        l10n.applicantNoResumeAnalysis,
        style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (snapshot.atsScore != null)
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.emerald.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  '${l10n.applicantAtsScore}: ${snapshot.atsScore}/100',
                  style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.emeraldDark,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        if ((snapshot.resumeSummary ?? '').isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(snapshot.resumeSummary!,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.4)),
        ],
        if (snapshot.resumeStrengths.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          for (final s in snapshot.resumeStrengths.take(5))
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_rounded,
                      size: 16, color: AppColors.emerald),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                      child: Text(s, style: theme.textTheme.bodyMedium)),
                ],
              ),
            ),
        ],
      ],
    );
  }
}
