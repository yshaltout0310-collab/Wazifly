import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/navigation/route_names.dart';
import '../../../core/services/analytics/analytics_events.dart';
import '../../../core/services/analytics/firebase_analytics_service.dart';
import '../../../core/services/applications/in_memory_applications_repository.dart';
import '../../../core/services/cv_repository/cv_document.dart';
import '../../../core/services/cv_repository/cv_repository.dart';
import '../../../core/services/cv_repository/last_selected_cv.dart';
import '../../../core/services/jobs/saved_jobs_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/models/job.dart';
import '../../../shared/widgets/cv_picker_sheet.dart';
import '../../../shared/widgets/job_detail_view.dart';
import '../../job_matching/domain/job_match.dart';
import '../application/job_detail_controller.dart';

/// Full job detail: description, skills, an on-demand resume match, and actions
/// (save, mock apply, ask the Career Coach about this job).
class JobDetailScreen extends ConsumerWidget {
  const JobDetailScreen({required this.jobId, super.key});

  final String jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(jobDetailControllerProvider(jobId));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.jobsDetailTitle),
        actions: [
          if (state.status == JobDetailStatus.ready) ...[
            IconButton(
              tooltip: l10n.interviewPracticeForJob,
              icon: const Icon(Icons.record_voice_over_outlined),
              // Tailors the interview to this job via the route `extra`.
              onPressed: () => context.pushNamed(
                RouteNames.interviewPrep,
                extra: state.job,
              ),
            ),
            Consumer(builder: (context, ref, _) {
              final saved = ref.watch(savedJobsProvider).contains(jobId);
              return IconButton(
                tooltip: saved ? l10n.jobsUnsave : l10n.jobsSave,
                onPressed: () =>
                    ref.read(savedJobsProvider.notifier).toggle(jobId),
                icon: Icon(saved
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded),
              );
            }),
          ],
        ],
      ),
      body: SafeArea(
        top: false,
        child: switch (state.status) {
          JobDetailStatus.loading =>
            const Center(child: CircularProgressIndicator()),
          JobDetailStatus.notFound => Center(
              child: Text(l10n.jobsNotFound,
                  style: Theme.of(context).textTheme.bodyLarge),
            ),
          JobDetailStatus.ready => _Content(jobId: jobId, job: state.job!),
        },
      ),
      // Fixed action bar lives in the Scaffold slot (bounded width) rather than
      // a Column+Expanded, which would give the buttons an unbounded width.
      bottomNavigationBar: state.status == JobDetailStatus.ready
          ? _ActionBar(jobId: jobId, job: state.job!)
          : null,
    );
  }
}

class _Content extends ConsumerWidget {
  const _Content({required this.jobId, required this.job});
  final String jobId;
  final Job job;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The public job body is the shared JobDetailView (also used by the employer
    // preview); the seeker injects its resume-match panel via `afterMeta`.
    return ResponsiveCenter(
      maxWidth: 640,
      child: JobDetailView(
        job: job,
        afterMeta: _MatchSection(jobId: jobId),
      ),
    );
  }
}

/// On-demand resume-match panel (integrates the Resume Analyzer + Job Matching).
class _MatchSection extends ConsumerWidget {
  const _MatchSection({required this.jobId});
  final String jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(jobDetailControllerProvider(jobId));
    final controller = ref.read(jobDetailControllerProvider(jobId).notifier);

    Widget shell(Widget child) => Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.emerald.withValues(alpha: 0.10),
                AppColors.emerald.withValues(alpha: 0.03),
              ],
            ),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.emerald.withValues(alpha: 0.25)),
          ),
          child: child,
        );

    if (!state.hasResume) {
      return shell(Row(children: [
        const Icon(Icons.insights_rounded, color: AppColors.emerald),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
            child: Text(l10n.jobsMatchNoResume,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.35))),
        TextButton(
          onPressed: () => context.pushNamed(RouteNames.resumeAnalyzer),
          child: Text(l10n.jobsAnalyzeResume),
        ),
      ]));
    }

    return switch (state.matchStatus) {
      MatchStatus.idle => shell(Row(children: [
          const Icon(Icons.insights_rounded, color: AppColors.emerald),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
              child: Text(l10n.jobsMatchPrompt,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.35))),
          FilledButton.tonal(
            onPressed: controller.computeMatch,
            child: Text(l10n.jobsSeeMatch),
          ),
        ])),
      MatchStatus.loading => shell(Row(children: [
          const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2.4)),
          const SizedBox(width: AppSpacing.md),
          Text(l10n.jobsMatchLoading,
              style: theme.textTheme.bodyMedium),
        ])),
      MatchStatus.error => shell(Row(children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.warning),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(l10n.jobMatchErrUnknown)),
          TextButton(
              onPressed: controller.computeMatch, child: Text(l10n.jobMatchRetry)),
        ])),
      MatchStatus.ready => shell(_MatchResult(match: state.match!)),
    };
  }
}

class _MatchResult extends StatelessWidget {
  const _MatchResult({required this.match});
  final JobMatch match;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final band = _band(l10n, match.matchScore);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('${match.matchScore}%',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(color: band.color, fontWeight: FontWeight.w800)),
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: band.color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(band.label,
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: band.color, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        if (match.reason.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(match.reason,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.4)),
        ],
        if (match.missingSkills.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(l10n.jobMatchMissingSkills,
              style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
          const SizedBox(height: 4),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final s in match.missingSkills)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.30)),
                  ),
                  child: Text(s,
                      style: theme.textTheme.labelMedium?.copyWith(
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

class _ActionBar extends ConsumerWidget {
  const _ActionBar({required this.jobId, required this.job});
  final String jobId;
  final Job job;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final applied = ref.watch(appliedJobIdsProvider).contains(jobId);

    return Container(
      padding: EdgeInsets.fromLTRB(context.horizontalGutter, AppSpacing.sm,
          context.horizontalGutter, AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
            top: BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.4))),
      ),
      child: SafeArea(
        top: false,
        // Both buttons are Expanded so the theme's full-width (Size.fromHeight,
        // i.e. infinite-width) button style resolves to a bounded width in this
        // Row rather than asserting (the §7.14 bug #2 pattern, now that the
        // internships flow surfaces this seeker detail screen live).
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.pushNamed(
                  RouteNames.careerCoach,
                  extra: l10n.jobsCoachSeed(job.title, job.company),
                ),
                icon: const Icon(Icons.psychology_outlined, size: 20),
                label: Text(l10n.jobsAskCoach),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: FilledButton.icon(
                onPressed: applied ? null : () => _apply(context, ref, l10n),
                icon: Icon(
                    applied
                        ? Icons.check_circle_rounded
                        : Icons.send_rounded,
                    size: 20),
                label: Text(applied ? l10n.jobsApplied : l10n.jobsApply),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Applies to [job]. If the user keeps ≥ 2 active CVs, first asks which CV to
  /// submit (preselecting the last-used / default one and remembering the
  /// choice). The chosen CV's "last used" info is updated automatically.
  Future<void> _apply(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final activeCvs = ref.read(activeCvsProvider);
    CvDocument? chosen;
    if (activeCvs.length >= 2) {
      final preselected = ref.read(lastSelectedCvProvider) ??
          ref.read(defaultCvProvider)?.id;
      chosen = await showCvPickerSheet(context,
          cvs: activeCvs, preselectedId: preselected);
      if (chosen == null) return; // dismissed → don't apply
    } else if (activeCvs.length == 1) {
      chosen = activeCvs.first;
    }

    final app = await ref.read(applicationsRepositoryProvider).apply(
          job: job,
          cvId: chosen?.id ?? '',
          cvName: chosen?.name ?? '',
        );

    // Remember + stamp the CV's last-used info (auto-update on application).
    if (chosen != null) {
      await ref.read(lastSelectedCvProvider.notifier).set(chosen.id);
      await ref.read(cvRepositoryProvider).updateCv(
            chosen.markUsed(DateTime.now(),
                jobTitle: job.title, company: job.company),
          );
    }

    ref.read(analyticsServiceProvider).logEvent(
      AnalyticsEvents.jobApply,
      parameters: {AnalyticsParams.jobId: job.id},
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(chosen != null
            ? l10n.jobsAppliedWithCv(chosen.name)
            : l10n.jobsApplyConfirm),
        action: SnackBarAction(
          label: l10n.jobsViewApplication,
          onPressed: () => context.pushNamed(
            RouteNames.applicationDetail,
            pathParameters: {'id': app.id},
          ),
        ),
      ));
  }
}

({Color color, String label}) _band(AppLocalizations l10n, int score) {
  if (score >= 80) return (color: AppColors.emerald, label: l10n.jobMatchStrong);
  if (score >= 60) return (color: AppColors.teal, label: l10n.jobMatchGood);
  if (score >= 40) return (color: AppColors.warning, label: l10n.jobMatchFair);
  return (color: AppColors.error, label: l10n.jobMatchWeak);
}
