import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/generated/app_localizations.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../shared/models/internship_details.dart';
import '../../../../shared/models/internship_details_l10n.dart';
import '../../application/internships_controller.dart';

/// Bottom sheet of internship facet filters (funding / work-mode / category /
/// level). Reads + toggles the [internshipsControllerProvider] live.
class InternshipFilterSheet extends ConsumerWidget {
  const InternshipFilterSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => const InternshipFilterSheet(),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final filter = ref.watch(internshipsControllerProvider).filter;
    final c = ref.read(internshipsControllerProvider.notifier);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(l10n.internshipFilterTitle,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800)),
                ),
                if (filter.hasFacetFilters)
                  TextButton(
                    onPressed: c.clearFilters,
                    child: Text(l10n.jobsClearFilters),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _Group(
              title: l10n.internshipFunding,
              children: [
                for (final v in InternshipFunding.values)
                  FilterChip(
                    label: Text(v.label(l10n)),
                    selected: filter.funding.contains(v),
                    onSelected: (_) => c.toggleFunding(v),
                  ),
              ],
            ),
            _Group(
              title: l10n.internshipWorkMode,
              children: [
                for (final v in WorkMode.values)
                  FilterChip(
                    label: Text(v.label(l10n)),
                    selected: filter.workModes.contains(v),
                    onSelected: (_) => c.toggleWorkMode(v),
                  ),
              ],
            ),
            _Group(
              title: l10n.internshipCategory,
              children: [
                for (final v in InternshipCategory.values)
                  FilterChip(
                    label: Text(v.label(l10n)),
                    selected: filter.categories.contains(v),
                    onSelected: (_) => c.toggleCategory(v),
                  ),
              ],
            ),
            _Group(
              title: l10n.internshipLevel,
              children: [
                for (final v in InternshipLevel.values)
                  FilterChip(
                    label: Text(v.label(l10n)),
                    selected: filter.levels.contains(v),
                    onSelected: (_) => c.toggleLevel(v),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.xs),
          Wrap(spacing: AppSpacing.xs, runSpacing: AppSpacing.xs, children: children),
        ],
      ),
    );
  }
}
