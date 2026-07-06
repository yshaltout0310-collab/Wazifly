import 'package:flutter/material.dart';

import '../../core/localization/generated/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/utils/responsive.dart';
import '../models/job.dart';

/// The public job body — title, company, meta chips, description, and required
/// skills — rendered from a shared [Job].
///
/// Shared by the seeker `JobDetailScreen` (which injects its resume-match panel
/// via [afterMeta]) and the employer job **preview**, guaranteeing the preview
/// looks *exactly* as a job seeker sees it, with no duplicated layout. Reused
/// identically for draft and published postings.
class JobDetailView extends StatelessWidget {
  const JobDetailView({
    required this.job,
    this.afterMeta,
    this.padding,
    super.key,
  });

  final Job job;

  /// Optional widget inserted between the meta chips and the description (the
  /// seeker uses this for its on-demand resume match; the preview omits it).
  final Widget? afterMeta;

  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return ListView(
      padding: padding ??
          EdgeInsets.fromLTRB(context.horizontalGutter, AppSpacing.lg,
              context.horizontalGutter, AppSpacing.lg),
      children: [
        Text(job.title,
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800)),
        if (job.company.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(job.company,
              style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700)),
        ],
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            if (job.location.isNotEmpty)
              _MetaChip(
                  icon: job.remote
                      ? Icons.public_rounded
                      : Icons.place_outlined,
                  label: job.remote
                      ? '${job.location} · ${l10n.jobsRemote}'
                      : job.location)
            else if (job.remote)
              _MetaChip(icon: Icons.public_rounded, label: l10n.jobsRemote),
            if (job.employmentType.isNotEmpty)
              _MetaChip(
                  icon: Icons.work_outline_rounded,
                  label: job.employmentType),
            if (job.seniority.isNotEmpty)
              _MetaChip(
                  icon: Icons.trending_up_rounded, label: job.seniority),
          ],
        ),
        if (afterMeta != null) ...[
          const SizedBox(height: AppSpacing.lg),
          afterMeta!,
        ],
        const SizedBox(height: AppSpacing.lg),
        if (job.description.isNotEmpty) ...[
          _SectionTitle(l10n.jobsDescription),
          const SizedBox(height: AppSpacing.sm),
          Text(job.description,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5)),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (job.requiredSkills.isNotEmpty) ...[
          _SectionTitle(l10n.jobsRequiredSkills),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final skill in job.requiredSkills)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                        color: AppColors.teal.withValues(alpha: 0.30)),
                  ),
                  child: Text(skill,
                      style: theme.textTheme.labelLarge?.copyWith(
                          color: AppColors.emeraldDark,
                          fontWeight: FontWeight.w600)),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.w800),
      );
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 15,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
          const SizedBox(width: 6),
          Text(label,
              style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.85))),
        ],
      ),
    );
  }
}
