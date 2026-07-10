import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/navigation/route_names.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/search_field.dart';
import '../../../shared/widgets/status_view.dart';
import '../application/internships_controller.dart';
import 'widgets/internship_filter_sheet.dart';
import 'widgets/internship_tile.dart';

/// Browse/search/filter internships. A scoped view over the shared jobs source
/// (internships only); tapping a card opens the shared job detail (`/jobs/:id`).
class InternshipsScreen extends ConsumerWidget {
  const InternshipsScreen({super.key});

  void _openJob(BuildContext context, String id) =>
      context.pushNamed(RouteNames.jobDetail, pathParameters: {'id': id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(internshipsControllerProvider);
    final controller = ref.read(internshipsControllerProvider.notifier);
    final facetCount = state.filter.funding.length +
        state.filter.workModes.length +
        state.filter.categories.length +
        state.filter.levels.length;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.internshipsTitle)),
      body: SafeArea(
        top: false,
        child: ResponsiveCenter(
          maxWidth: 720,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(context.horizontalGutter,
                    AppSpacing.sm, context.horizontalGutter, AppSpacing.sm),
                child: Row(
                  children: [
                    Expanded(
                      child: SearchField(
                        hintText: l10n.internshipsSearchHint,
                        onChanged: controller.updateText,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _FilterButton(
                      count: facetCount,
                      onTap: () => InternshipFilterSheet.show(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: switch (state.status) {
                  InternshipsStatus.loading => const StatusView.loading(),
                  InternshipsStatus.error => StatusView.error(
                      message: l10n.internshipsError,
                      onRetry: controller.retry,
                    ),
                  InternshipsStatus.ready => state.results.isEmpty
                      ? (state.hasActiveFilters
                          ? StatusView.empty(
                              icon: Icons.search_off_rounded,
                              title: l10n.internshipsNoResultsTitle,
                              message: l10n.internshipsNoResultsBody,
                            )
                          : StatusView.empty(
                              icon: Icons.school_outlined,
                              title: l10n.internshipsEmptyTitle,
                              message: l10n.internshipsEmptyBody,
                            ))
                      : _List(
                          onOpen: (id) => _openJob(context, id),
                          count: state.results.length,
                          controller: controller,
                        ),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _List extends ConsumerWidget {
  const _List({
    required this.onOpen,
    required this.count,
    required this.controller,
  });

  final ValueChanged<String> onOpen;
  final int count;
  final InternshipsController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final jobs = ref.watch(internshipsControllerProvider).results;

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(context.horizontalGutter, 0,
          context.horizontalGutter, AppSpacing.xl),
      itemCount: jobs.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) {
          return Padding(
            padding:
                const EdgeInsets.only(top: AppSpacing.xs, bottom: AppSpacing.sm),
            child: Text(
              l10n.internshipsCount(count),
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }
        final job = jobs[i - 1];
        return InternshipTile(job: job, onTap: () => onOpen(job.id));
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
