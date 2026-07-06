import 'package:flutter/material.dart';

import '../../../../core/localization/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../shared/models/applicant_snapshot.dart';

/// Read-only interview-readiness snapshot (practice sessions + best score). Full
/// interview history stays private to the applicant; only this lightweight
/// summary is denormalized at apply time.
class InterviewReadinessCard extends StatelessWidget {
  const InterviewReadinessCard({required this.snapshot, super.key});

  final ApplicantSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(Icons.record_voice_over_outlined,
            size: 22, color: theme.colorScheme.primary),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.applicantInterviewSessions(snapshot.interviewSessions),
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              if (snapshot.interviewBestScore != null) ...[
                const SizedBox(height: 2),
                Text(
                  l10n.applicantInterviewBest(snapshot.interviewBestScore!),
                  style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.emeraldDark,
                      fontWeight: FontWeight.w700),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
