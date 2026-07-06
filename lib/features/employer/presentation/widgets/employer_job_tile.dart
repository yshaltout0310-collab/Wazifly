import 'package:flutter/material.dart';

import '../../../../core/localization/generated/app_localizations.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../shared/models/job_posting.dart';
import '../employer_jobs_l10n.dart';
import '../job_actions.dart';
import 'job_status_chip.dart';

/// A card in the employer "My jobs" list: title, status, meta chips, an openings
/// hint, and a lifecycle overflow menu. Shows a subtle progress bar while an
/// optimistic action for this posting is in flight.
class EmployerJobTile extends StatelessWidget {
  const EmployerJobTile({
    required this.job,
    required this.onTap,
    required this.onAction,
    this.pending = false,
    super.key,
  });

  final JobPosting job;
  final VoidCallback onTap;
  final ValueChanged<JobAction> onAction;
  final bool pending;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final actions = availableJobActions(job);

    final meta = <String>[
      if (job.employmentType != null) job.employmentType!.label(l10n),
      if (job.experience != null) job.experience!.label(l10n),
      if (job.location.isNotEmpty)
        job.remote ? '${job.location} · ${l10n.jobRemoteLabel}' : job.location
      else if (job.remote)
        l10n.jobRemoteLabel,
    ];

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md, AppSpacing.md, AppSpacing.xs, AppSpacing.sm),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              job.title.isEmpty ? l10n.createJobTitle : job.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                JobStatusChip(status: job.status, dense: true),
                                if (job.displayOpenings > 1) ...[
                                  const SizedBox(width: AppSpacing.xs),
                                  Flexible(
                                    child: Text(
                                      l10n.jobOpeningsValue(job.displayOpenings),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.labelSmall?.copyWith(
                                          color: theme.colorScheme.onSurface
                                              .withValues(alpha: 0.6)),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<JobAction>(
                        tooltip: l10n.jobSortStatus,
                        icon: const Icon(Icons.more_vert_rounded),
                        onSelected: onAction,
                        itemBuilder: (context) => [
                          for (final a in actions)
                            PopupMenuItem(
                              value: a,
                              child: Row(
                                children: [
                                  Icon(a.icon,
                                      size: 20,
                                      color: a.isDestructive
                                          ? theme.colorScheme.error
                                          : null),
                                  const SizedBox(width: AppSpacing.sm),
                                  Text(
                                    a.label(l10n),
                                    style: a.isDestructive
                                        ? TextStyle(
                                            color: theme.colorScheme.error)
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (meta.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
                    child: Text(
                      meta.join('  ·  '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6)),
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
