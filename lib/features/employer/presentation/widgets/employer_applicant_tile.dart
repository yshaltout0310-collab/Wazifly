import 'package:flutter/material.dart';

import '../../../../core/localization/generated/app_localizations.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../shared/models/application.dart';
import '../../../../shared/widgets/application_status_chip.dart';
import 'applicant_avatar.dart';
import 'match_score_badge.dart';

/// A card in the applicants list: avatar, name, headline, status chip, match
/// score, and applied date. Mirrors `EmployerJobTile`.
class EmployerApplicantTile extends StatelessWidget {
  const EmployerApplicantTile({
    required this.application,
    required this.onTap,
    this.pending = false,
    super.key,
  });

  final Application application;
  final VoidCallback onTap;
  final bool pending;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final snap = application.applicant;
    final name = (snap?.name.trim().isNotEmpty ?? false)
        ? snap!.name.trim()
        : l10n.employerApplicantsTitle;
    final headline = snap?.headline;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.5)),
              boxShadow: AppShadows.card(dark: dark),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ApplicantAvatar(name: name, photoUrl: snap?.photoUrl),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            if ((headline ?? '').isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                headline!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.6)),
                              ),
                            ],
                            const SizedBox(height: AppSpacing.sm),
                            Wrap(
                              spacing: AppSpacing.xs,
                              runSpacing: AppSpacing.xs,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                StatusChip(
                                    status: application.status, compact: true),
                                if (snap?.matchScore != null)
                                  MatchScoreBadge(
                                      score: snap!.matchScore!, dense: true),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                ),
                if (pending)
                  const ClipRRect(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(AppRadius.lg),
                      bottomRight: Radius.circular(AppRadius.lg),
                    ),
                    child: LinearProgressIndicator(minHeight: 2.5),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
