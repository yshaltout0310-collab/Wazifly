import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/navigation/route_names.dart';
import '../../../core/services/applications/in_memory_applications_repository.dart';
import '../../../core/services/jobs/saved_jobs_store.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/models/job.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/search_field.dart';
import '../../job_matching/application/job_matching_controller.dart';
import '../../job_matching/presentation/widgets/job_match_card.dart';
import '../application/jobs_browse_controller.dart';
import 'widgets/job_filter_sheet.dart';
import 'widgets/job_list_tile.dart';

/// The Jobs platform: browse/search all jobs, view AI "Best matches", and see
/// Saved jobs. Segmented (not TabBarView) so the Best-matches AI ranking only
/// runs when that segment is opened.
class JobsScreen extends ConsumerStatefulWidget {
  const JobsScreen({super.key});

  @override
  ConsumerState<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends ConsumerState<JobsScreen> {
  int _segment = 0; // 0 = All, 1 = Best matches, 2 = Saved

  void _openJob(String id) =>
      context.pushNamed(RouteNames.jobDetail, pathParameters: {'id': id});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.jobsTitle),
        actions: [
          IconButton(
            tooltip: l10n.jobsMyApplications,
            onPressed: () => context.pushNamed(RouteNames.applications),
            icon: const Icon(Icons.assignment_turned_in_outlined),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ResponsiveCenter(
          maxWidth: 720,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(context.horizontalGutter,
                    AppSpacing.sm, context.horizontalGutter, AppSpacing.sm),
                child: SegmentedButton<int>(
                  segments: [
                    ButtonSegment(value: 0, label: Text(l10n.jobsTabAll)),
                    ButtonSegment(value: 1, label: Text(l10n.jobsTabMatches)),
                    ButtonSegment(value: 2, label: Text(l10n.jobsTabSaved)),
                  ],
                  selected: {_segment},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) => setState(() => _segment = s.first),
                ),
              ),
              Expanded(
                child: switch (_segment) {
                  1 => _BestMatchesView(onOpen: _openJob),
                  2 => _SavedView(onOpen: _openJob),
                  _ => _AllView(onOpen: _openJob),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// All — search + filter + results
// ---------------------------------------------------------------------------
class _AllView extends ConsumerWidget {
  const _AllView({required this.onOpen});
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(jobsBrowseControllerProvider);
    final controller = ref.read(jobsBrowseControllerProvider.notifier);
    final activeFilterCount = state.query.employmentTypes.length +
        state.query.seniorities.length +
        (state.query.remoteOnly ? 1 : 0);

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.horizontalGutter),
          child: Row(
            children: [
              Expanded(
                child: SearchField(
                  hintText: l10n.jobsSearchHint,
                  onChanged: controller.updateText,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _FilterButton(
                count: activeFilterCount,
                onTap: () => JobFilterSheet.show(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: switch (state.status) {
            JobsStatus.loading =>
              const Center(child: CircularProgressIndicator()),
            JobsStatus.error => _Message(
                icon: Icons.error_outline_rounded,
                text: l10n.jobsLoadError,
              ),
            JobsStatus.ready => state.results.isEmpty
                ? _Message(
                    icon: Icons.search_off_rounded, text: l10n.jobsNoResults)
                : _JobList(
                    jobs: state.results,
                    onOpen: onOpen,
                    countLabel: l10n.jobsCount(state.results.length),
                  ),
          },
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Best matches — reuses the Job Matching controller/repository
// ---------------------------------------------------------------------------
class _BestMatchesView extends ConsumerWidget {
  const _BestMatchesView({required this.onOpen});
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(jobMatchingControllerProvider);

    return switch (state.status) {
      JobMatchStatus.needsResume => _Message(
          icon: Icons.description_outlined,
          text: l10n.jobsMatchesNeedResume,
          action: (
            label: l10n.jobsAnalyzeResume,
            onTap: () => context.pushNamed(RouteNames.resumeAnalyzer),
          ),
        ),
      JobMatchStatus.analyzingResume || JobMatchStatus.matching => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: AppSpacing.md),
              Text(l10n.jobMatchMatching),
            ],
          ),
        ),
      JobMatchStatus.error => _Message(
          icon: Icons.error_outline_rounded,
          text: l10n.jobMatchErrUnknown,
          action: (
            label: l10n.jobMatchRetry,
            onTap: ref.read(jobMatchingControllerProvider.notifier).retry,
          ),
        ),
      JobMatchStatus.success => ListView.builder(
          padding: EdgeInsets.fromLTRB(context.horizontalGutter, AppSpacing.sm,
              context.horizontalGutter, AppSpacing.xl),
          itemCount: state.matches.length,
          itemBuilder: (context, i) {
            final match = state.matches[i];
            return GestureDetector(
              onTap: () => onOpen(match.job.id),
              child: JobMatchCard(match: match),
            );
          },
        ),
    };
  }
}

// ---------------------------------------------------------------------------
// Saved — derived from the interactions store + the loaded list
// ---------------------------------------------------------------------------
class _SavedView extends ConsumerWidget {
  const _SavedView({required this.onOpen});
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final savedIds = ref.watch(savedJobsProvider);
    final all = ref.watch(jobsBrowseControllerProvider).allJobs;
    final saved =
        all.where((j) => savedIds.contains(j.id)).toList(growable: false);

    if (saved.isEmpty) {
      return _Message(
          icon: Icons.bookmark_border_rounded, text: l10n.jobsNoSaved);
    }
    return _JobList(
      jobs: saved,
      onOpen: onOpen,
      countLabel: l10n.jobsCount(saved.length),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared list + helpers
// ---------------------------------------------------------------------------
class _JobList extends ConsumerWidget {
  const _JobList({
    required this.jobs,
    required this.onOpen,
    required this.countLabel,
  });

  final List<Job> jobs;
  final ValueChanged<String> onOpen;
  final String countLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final saved = ref.watch(savedJobsProvider);
    final applied = ref.watch(appliedJobIdsProvider);
    final controller = ref.read(savedJobsProvider.notifier);

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(context.horizontalGutter, 0,
          context.horizontalGutter, AppSpacing.xl),
      itemCount: jobs.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(
                top: AppSpacing.xs, bottom: AppSpacing.sm),
            child: Text(
              countLabel,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }
        final job = jobs[i - 1];
        return JobListTile(
          job: job,
          saved: saved.contains(job.id),
          applied: applied.contains(job.id),
          onTap: () => onOpen(job.id),
          onToggleSave: () => controller.toggle(job.id),
        );
      },
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.count, required this.onTap});
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Badge(
      isLabelVisible: count > 0,
      label: Text('$count'),
      child: IconButton.filledTonal(
        onPressed: onTap,
        icon: const Icon(Icons.tune_rounded),
        tooltip: AppLocalizations.of(context).jobsFilters,
        style: IconButton.styleFrom(
          backgroundColor:
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text, this.action});
  final IconData icon;
  final String text;
  final ({String label, VoidCallback onTap})? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 56,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.35)),
            const SizedBox(height: AppSpacing.md),
            Text(
              text,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                height: 1.4,
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                  label: action!.label,
                  onPressed: action!.onTap,
                  expanded: false),
            ],
          ],
        ),
      ),
    );
  }
}
