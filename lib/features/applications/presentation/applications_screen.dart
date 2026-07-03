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
import '../application/applications_controller.dart';
import 'widgets/application_filter_sheet.dart';
import 'widgets/application_tile.dart';
import 'widgets/stats_card.dart';

/// The Applications Center hub: a stats header + segmented My Applications /
/// Saved. Search + status filter apply to the Applications segment.
class ApplicationsScreen extends ConsumerStatefulWidget {
  const ApplicationsScreen({super.key});

  @override
  ConsumerState<ApplicationsScreen> createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends ConsumerState<ApplicationsScreen> {
  int _segment = 0; // 0 = My Applications, 1 = Saved

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final stats = ref.watch(applicationStatsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appsTitle)),
      body: SafeArea(
        top: false,
        child: ResponsiveCenter(
          maxWidth: 720,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(context.horizontalGutter,
                    AppSpacing.md, context.horizontalGutter, AppSpacing.sm),
                child: StatsCard(stats: stats),
              ),
              Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: context.horizontalGutter),
                child: SegmentedButton<int>(
                  segments: [
                    ButtonSegment(
                        value: 0, label: Text(l10n.appsTabApplications)),
                    ButtonSegment(value: 1, label: Text(l10n.appsTabSaved)),
                  ],
                  selected: {_segment},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) => setState(() => _segment = s.first),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: _segment == 0
                    ? const _ApplicationsView()
                    : const _SavedView(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// My Applications — search + status filter + list
// ---------------------------------------------------------------------------
class _ApplicationsView extends ConsumerWidget {
  const _ApplicationsView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final apps = ref.watch(filteredApplicationsProvider);
    final filter = ref.watch(applicationsFilterProvider);
    final controller = ref.read(applicationsFilterProvider.notifier);
    final total = ref.watch(applicationsProvider).valueOrNull?.length ?? 0;

    // No applications at all (not just filtered out) → onboarding empty state.
    if (total == 0) {
      return _Message(
        icon: Icons.work_history_outlined,
        text: l10n.appsEmpty,
        action: (
          label: l10n.appsBrowseJobs,
          onTap: () => context.pushNamed(RouteNames.jobs),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.horizontalGutter),
          child: Row(
            children: [
              Expanded(
                child: SearchField(
                  hintText: l10n.appsSearchHint,
                  onChanged: controller.updateText,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Badge(
                isLabelVisible: filter.statuses.isNotEmpty,
                label: Text('${filter.statuses.length}'),
                child: IconButton.filledTonal(
                  tooltip: l10n.appsFilterByStatus,
                  onPressed: () => ApplicationFilterSheet.show(context),
                  icon: const Icon(Icons.tune_rounded),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: apps.isEmpty
              ? _Message(
                  icon: Icons.search_off_rounded, text: l10n.appsNoResults)
              : ListView.builder(
                  padding: EdgeInsets.fromLTRB(context.horizontalGutter, 0,
                      context.horizontalGutter, AppSpacing.xl),
                  itemCount: apps.length,
                  itemBuilder: (context, i) => ApplicationTile(
                    application: apps[i],
                    onTap: () => context.pushNamed(
                      RouteNames.applicationDetail,
                      pathParameters: {'id': apps[i].id},
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Saved — resolved from saved ids via the shared jobs repository
// ---------------------------------------------------------------------------
class _SavedView extends ConsumerWidget {
  const _SavedView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final saved = ref.watch(savedJobsListProvider);

    return saved.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) =>
          _Message(icon: Icons.error_outline_rounded, text: l10n.jobsLoadError),
      data: (jobs) => jobs.isEmpty
          ? _Message(icon: Icons.bookmark_border_rounded, text: l10n.jobsNoSaved)
          : ListView.builder(
              padding: EdgeInsets.fromLTRB(context.horizontalGutter,
                  AppSpacing.xs, context.horizontalGutter, AppSpacing.xl),
              itemCount: jobs.length,
              itemBuilder: (context, i) => _SavedJobTile(job: jobs[i]),
            ),
    );
  }
}

class _SavedJobTile extends ConsumerWidget {
  const _SavedJobTile({required this.job});
  final Job job;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border:
            Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
        boxShadow: AppShadows.card(dark: dark),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: () => context.pushNamed(RouteNames.jobDetail,
              pathParameters: {'id': job.id}),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(job.title,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text('${job.company} · ${job.location}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.65),
                          )),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: l10n.jobsUnsave,
                  onPressed: () =>
                      ref.read(savedJobsProvider.notifier).toggle(job.id),
                  icon: Icon(Icons.bookmark_rounded,
                      color: theme.colorScheme.primary),
                ),
              ],
            ),
          ),
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
