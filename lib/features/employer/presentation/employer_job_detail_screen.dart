import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/models/job_posting.dart';
import '../application/employer_jobs_controller.dart';
import '../application/employer_jobs_providers.dart';
import 'employer_jobs_l10n.dart';
import 'job_action_handler.dart';
import 'job_actions.dart';
import 'widgets/job_status_chip.dart';

/// Read-only detail for one owned posting: status, metrics foundation, openings,
/// availability, an optional archive reason, an "Applicants — coming soon" note,
/// and the status-aware lifecycle actions (shared with the list via
/// [runJobAction]).
class EmployerJobDetailScreen extends ConsumerWidget {
  const EmployerJobDetailScreen({required this.jobId, super.key});

  final String jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final job = ref.watch(employerJobByIdProvider(jobId));

    // Surface optimistic-action failures.
    ref.listen(employerJobsControllerProvider, (prev, next) {
      final failure = next.failure;
      if (failure != null && failure != prev?.failure) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(jobsActionFailureMessage(l10n, failure)),
          ));
        ref.read(employerJobsControllerProvider.notifier).clearFailure();
      }
    });

    // If the posting disappears (soft-deleted), leave the detail screen.
    ref.listen(employerJobByIdProvider(jobId), (prev, next) {
      if (prev != null && next == null && context.canPop()) context.pop();
    });

    if (job == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.jobActionFailed)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(job.title.isEmpty ? l10n.createJobTitle : job.title),
      ),
      body: SafeArea(
        top: false,
        child: ResponsiveCenter(
          maxWidth: 640,
          child: ListView(
            padding: EdgeInsets.fromLTRB(context.horizontalGutter,
                AppSpacing.lg, context.horizontalGutter, AppSpacing.xxl),
            children: [
              Row(
                children: [
                  JobStatusChip(status: job.status),
                  const SizedBox(width: AppSpacing.sm),
                  if (job.displayOpenings > 1)
                    Expanded(
                      child: Text(l10n.jobOpeningsValue(job.displayOpenings),
                          textAlign: TextAlign.end,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelMedium),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(job.title.isEmpty ? l10n.createJobTitle : job.title,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
              if (job.companyName.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(job.companyName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w700)),
              ],
              const SizedBox(height: AppSpacing.lg),
              _MetricsRow(job: job),
              const SizedBox(height: AppSpacing.lg),
              _InfoLines(job: job),
              if (job.archiveReason != null &&
                  job.archiveReason!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                _ArchiveReason(reason: job.archiveReason!),
              ],
              const SizedBox(height: AppSpacing.lg),
              _ApplicantsSoon(text: l10n.jobDetailApplicantsSoon),
              const SizedBox(height: AppSpacing.lg),
              _Actions(job: job),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricsRow extends StatelessWidget {
  const _MetricsRow({required this.job});
  final JobPosting job;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: _MetricTile(
            icon: Icons.visibility_outlined,
            label: l10n.jobMetricsViews,
            value: job.metrics.views,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _MetricTile(
            icon: Icons.description_outlined,
            label: l10n.jobMetricsApplications,
            value: job.metrics.applicationsCount,
          ),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile(
      {required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border:
            Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: theme.colorScheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$value',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800)),
                Text(label,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.6))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoLines extends StatelessWidget {
  const _InfoLines({required this.job});
  final JobPosting job;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final material = MaterialLocalizations.of(context);
    final theme = Theme.of(context);

    final lines = <String>[
      if (job.employmentType != null) job.employmentType!.label(l10n),
      if (job.experience != null) job.experience!.label(l10n),
      if (job.location.isNotEmpty)
        job.remote ? '${job.location} · ${l10n.jobRemoteLabel}' : job.location
      else if (job.remote)
        l10n.jobRemoteLabel,
      if (job.opensAt != null)
        '${l10n.jobOpensAtLabel}: ${material.formatMediumDate(job.opensAt!)}',
      if (job.expiresAt != null)
        '${l10n.jobExpiresAtLabel}: ${material.formatMediumDate(job.expiresAt!)}',
      if (job.publishedAt != null)
        l10n.jobPublishedOn(material.formatMediumDate(job.publishedAt!)),
      if (job.updatedAt != null)
        l10n.jobUpdatedOn(material.formatMediumDate(job.updatedAt!)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.circle,
                    size: 6,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                    child:
                        Text(line, style: theme.textTheme.bodyMedium)),
              ],
            ),
          ),
      ],
    );
  }
}

class _ArchiveReason extends StatelessWidget {
  const _ArchiveReason({required this.reason});
  final String reason;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.teal.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.teal.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.jobArchiveReasonLabel,
              style: theme.textTheme.labelMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(reason, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _ApplicantsSoon extends StatelessWidget {
  const _ApplicantsSoon({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(Icons.people_alt_outlined,
            size: 20, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(text,
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
        ),
      ],
    );
  }
}

class _Actions extends ConsumerWidget {
  const _Actions({required this.job});
  final JobPosting job;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    // The theme makes buttons full-width (Size.fromHeight). In a Wrap that would
    // demand infinite width, so each action button overrides minimumSize to size
    // to its content instead.
    const compact = Size(0, 40);
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final a in availableJobActions(job))
          a == JobAction.publish
              ? FilledButton.icon(
                  onPressed: () => runJobAction(context, ref, job, a),
                  style: FilledButton.styleFrom(minimumSize: compact),
                  icon: Icon(a.icon, size: 18),
                  label: Text(a.label(l10n)),
                )
              : OutlinedButton.icon(
                  onPressed: () => runJobAction(context, ref, job, a),
                  style: OutlinedButton.styleFrom(
                    minimumSize: compact,
                    foregroundColor:
                        a.isDestructive ? theme.colorScheme.error : null,
                  ),
                  icon: Icon(a.icon, size: 18),
                  label: Text(a.label(l10n)),
                ),
      ],
    );
  }
}
