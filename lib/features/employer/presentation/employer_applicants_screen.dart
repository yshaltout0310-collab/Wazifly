import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/navigation/route_names.dart';
import '../../../core/services/applications/employer_applicants_repository.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/models/application.dart';
import '../../../shared/widgets/application_status_style.dart';
import '../../../shared/widgets/status_view.dart';
import '../../../shared/widgets/search_field.dart';
import '../application/employer_applicants_controller.dart';
import '../application/employer_applicants_providers.dart';
import '../application/employer_jobs_providers.dart';
import 'employer_applicants_l10n.dart';
import 'widgets/applicant_group_header.dart';
import 'widgets/employer_applicant_tile.dart';

/// The employer applicants surface. With no [jobId] it's the grouped-by-job
/// inbox (reached from Employer Home); with a [jobId] it's one job's applicants
/// (reached from Job Detail). Mirrors `EmployerJobsScreen`.
class EmployerApplicantsScreen extends ConsumerStatefulWidget {
  const EmployerApplicantsScreen({this.jobId, super.key});

  final String? jobId;

  @override
  ConsumerState<EmployerApplicantsScreen> createState() =>
      _EmployerApplicantsScreenState();
}

class _EmployerApplicantsScreenState
    extends ConsumerState<EmployerApplicantsScreen> {
  @override
  void initState() {
    super.initState();
    // Scope the shared filter to this job (or the whole inbox). Each screen
    // entry sets the correct scope in initState, so no dispose reset is needed
    // (using `ref` in dispose is disallowed anyway).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref
            .read(employerApplicantsFilterProvider.notifier)
            .setJob(widget.jobId);
      }
    });
  }

  void _openApplicant(String id) => context.pushNamed(
        RouteNames.employerApplicantDetail,
        pathParameters: {'appId': id},
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    ref.listen(employerApplicantsControllerProvider, (prev, next) {
      final failure = next.failure;
      if (failure != null && failure != prev?.failure) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(applicantsActionFailureMessage(l10n, failure)),
          ));
        ref.read(employerApplicantsControllerProvider.notifier).clearFailure();
      }
    });

    final async = ref.watch(employerApplicantsProvider);
    final filter = ref.watch(employerApplicantsFilterProvider);
    final groups = ref.watch(groupedApplicantsProvider);
    final anyApplicants =
        ref.watch(visibleApplicantsProvider).isNotEmpty;
    final jobTitle = widget.jobId == null
        ? null
        : ref.watch(employerJobByIdProvider(widget.jobId!))?.title;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.jobId == null
            ? l10n.employerApplicantsTitle
            : (jobTitle?.isNotEmpty ?? false
                ? jobTitle!
                : l10n.employerApplicantsTitle)),
        actions: [
          PopupMenuButton<ApplicantSort>(
            tooltip: l10n.employerJobsSort,
            icon: const Icon(Icons.sort_rounded),
            initialValue: filter.sort,
            onSelected:
                ref.read(employerApplicantsFilterProvider.notifier).setSort,
            itemBuilder: (context) => [
              for (final s in ApplicantSort.values)
                PopupMenuItem(value: s, child: Text(s.label(l10n))),
            ],
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ResponsiveCenter(
          maxWidth: 720,
          child: async.isLoading && !anyApplicants
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    if (anyApplicants) const _StatsStrip(),
                    Padding(
                      padding: EdgeInsets.fromLTRB(context.horizontalGutter,
                          AppSpacing.sm, context.horizontalGutter, AppSpacing.xs),
                      child: SearchField(
                        hintText: l10n.employerApplicantsSearchHint,
                        onChanged: ref
                            .read(employerApplicantsFilterProvider.notifier)
                            .updateText,
                      ),
                    ),
                    const _StatusFilterBar(),
                    Expanded(
                      child: !anyApplicants
                          ? StatusView.empty(
                              icon: Icons.groups_outlined,
                              title: l10n.employerApplicantsEmpty,
                              message: l10n.employerApplicantsEmptyHint,
                            )
                          : groups.isEmpty
                              ? _NoResults()
                              : _ApplicantsList(
                                  groups: groups, grouped: widget.jobId == null,
                                  onOpen: _openApplicant),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _StatsStrip extends ConsumerWidget {
  const _StatsStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final stats = ref.watch(employerApplicantsStatsProvider);
    final items = <({String label, int value})>[
      (label: l10n.applicantsStatTotal, value: stats.total),
      (label: l10n.applicantsStatNew, value: stats.pending),
      (label: l10n.statusInterview, value: stats.interview),
      (label: l10n.statusAccepted, value: stats.accepted),
    ];
    return Padding(
      padding: EdgeInsets.fromLTRB(context.horizontalGutter, AppSpacing.sm,
          context.horizontalGutter, 0),
      child: Row(
        children: [
          for (final it in items)
            Expanded(
              child: Column(
                children: [
                  Text('${it.value}',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  Text(it.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
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

class _StatusFilterBar extends ConsumerWidget {
  const _StatusFilterBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final filter = ref.watch(employerApplicantsFilterProvider);
    final notifier = ref.read(employerApplicantsFilterProvider.notifier);
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: context.horizontalGutter),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: FilterChip(
              label: Text(l10n.employerApplicantsFilterAll),
              selected: filter.statuses.isEmpty,
              onSelected: (_) => notifier.clear(),
            ),
          ),
          for (final status in ApplicationStatus.values)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: FilterChip(
                label: Text(applicationStatusLabel(l10n, status)),
                selected: filter.statuses.contains(status),
                onSelected: (_) => notifier.toggleStatus(status),
              ),
            ),
        ],
      ),
    );
  }
}

class _ApplicantsList extends ConsumerWidget {
  const _ApplicantsList({
    required this.groups,
    required this.grouped,
    required this.onOpen,
  });

  final List<ApplicantGroup> groups;
  final bool grouped;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final action = ref.watch(employerApplicantsControllerProvider);
    return ListView(
      padding: EdgeInsets.fromLTRB(context.horizontalGutter, AppSpacing.xs,
          context.horizontalGutter, AppSpacing.xxl),
      children: [
        for (final group in groups) ...[
          if (grouped)
            ApplicantGroupHeader(
                jobTitle: group.jobTitle, count: group.count),
          for (final app in group.applicants)
            EmployerApplicantTile(
              application: app,
              pending: action.isPending(app.id),
              onTap: () => onOpen(app.id),
            ),
        ],
      ],
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
            Text(l10n.employerApplicantsNoResults,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                    color:
                        theme.colorScheme.onSurface.withValues(alpha: 0.7))),
          ],
        ),
      ),
    );
  }
}
