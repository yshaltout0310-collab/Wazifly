import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/navigation/route_names.dart';
import '../../../core/services/jobs/employer_jobs_repository.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/models/job_posting.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/search_field.dart';
import '../../../shared/widgets/status_view.dart';
import '../application/employer_jobs_controller.dart';
import '../application/employer_jobs_providers.dart';
import '../domain/job_status.dart';
import 'employer_jobs_l10n.dart';
import 'job_action_handler.dart';
import 'widgets/employer_job_tile.dart';

/// The employer "My jobs" list: search + status filter chips + sort, a card per
/// posting with a lifecycle overflow menu, and a FAB to post a new job. Reads the
/// optimistic `filteredEmployerJobsProvider`; lifecycle failures surface via a
/// snackbar from the controller.
class EmployerJobsScreen extends ConsumerWidget {
  const EmployerJobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    // Surface optimistic-action failures (rollbacks) as a snackbar.
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

    final async = ref.watch(employerJobsProvider);
    final filter = ref.watch(employerJobsFilterProvider);
    final jobs = ref.watch(filteredEmployerJobsProvider);
    final anyJobs = ref.watch(visibleEmployerJobsProvider).isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.employerJobsTitle),
        actions: [
          PopupMenuButton<JobSort>(
            tooltip: l10n.employerJobsSort,
            icon: const Icon(Icons.sort_rounded),
            initialValue: filter.sort,
            onSelected:
                ref.read(employerJobsFilterProvider.notifier).setSort,
            itemBuilder: (context) => [
              for (final s in JobSort.values)
                PopupMenuItem(value: s, child: Text(s.label(l10n))),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed(RouteNames.createJob),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.createJobTitle),
      ),
      body: SafeArea(
        top: false,
        child: ResponsiveCenter(
          maxWidth: 720,
          child: async.isLoading && !anyJobs
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(context.horizontalGutter,
                          AppSpacing.sm, context.horizontalGutter, AppSpacing.xs),
                      child: SearchField(
                        hintText: l10n.employerJobsSearchHint,
                        onChanged: ref
                            .read(employerJobsFilterProvider.notifier)
                            .updateText,
                      ),
                    ),
                    _StatusFilterBar(filter: filter),
                    Expanded(
                      child: !anyJobs
                          ? StatusView.empty(
                              icon: Icons.work_outline_rounded,
                              title: l10n.employerJobsEmpty,
                              action: PrimaryButton(
                                label: l10n.employerJobsEmptyCta,
                                expanded: false,
                                onPressed: () =>
                                    context.pushNamed(RouteNames.createJob),
                              ),
                            )
                          : jobs.isEmpty
                              ? _NoResults()
                              : _JobsList(jobs: jobs),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _StatusFilterBar extends ConsumerWidget {
  const _StatusFilterBar({required this.filter});
  final EmployerJobsFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final notifier = ref.read(employerJobsFilterProvider.notifier);

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding:
            EdgeInsets.symmetric(horizontal: context.horizontalGutter),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: FilterChip(
              label: Text(l10n.employerJobsFilterAll),
              selected: filter.statuses.isEmpty,
              onSelected: (_) => notifier.clear(),
            ),
          ),
          for (final status in JobStatus.values)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: FilterChip(
                label: Text(status.label(l10n)),
                selected: filter.statuses.contains(status),
                onSelected: (_) => notifier.toggleStatus(status),
              ),
            ),
        ],
      ),
    );
  }
}

class _JobsList extends ConsumerWidget {
  const _JobsList({required this.jobs});
  final List<JobPosting> jobs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final action = ref.watch(employerJobsControllerProvider);
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(context.horizontalGutter, AppSpacing.sm,
          context.horizontalGutter, AppSpacing.xxl),
      itemCount: jobs.length,
      itemBuilder: (context, i) {
        final job = jobs[i];
        return EmployerJobTile(
          job: job,
          pending: action.isPending(job.id),
          onTap: () => context.pushNamed(RouteNames.employerJobDetail,
              pathParameters: {'id': job.id}),
          onAction: (a) => runJobAction(context, ref, job, a),
        );
      },
    );
  }
}

class _NoResults extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded,
                size: 56,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.35)),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.employerJobsNoResults,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
            ),
          ],
        ),
      ),
    );
  }
}
