import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/countries_data.dart';
import '../../../../core/localization/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../shared/models/job_l10n.dart';
import '../../application/jobs_browse_controller.dart';

/// Bottom sheet to filter jobs by remote, employment type, and seniority.
/// Reads/writes the browse controller's [JobQuery] live.
class JobFilterSheet extends ConsumerWidget {
  const JobFilterSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => const JobFilterSheet(),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(jobsBrowseControllerProvider);
    final controller = ref.read(jobsBrowseControllerProvider.notifier);
    final query = state.query;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          bottom: AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  l10n.jobsFilters,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                if (state.hasActiveFilters)
                  TextButton(
                    onPressed: controller.clearFilters,
                    child: Text(l10n.jobsClearFilters),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _GroupLabel(l10n.jobsCountry),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.6)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.place_outlined, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: DropdownButton<String?>(
                      value: query.location,
                      isExpanded: true,
                      underline: const SizedBox.shrink(),
                      items: [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text(l10n.jobsAllCountries),
                        ),
                        for (final c in CountriesData.all)
                          DropdownMenuItem<String?>(
                            value: c.name,
                            child: Text('${c.flag}  ${c.name}',
                                overflow: TextOverflow.ellipsis),
                          ),
                      ],
                      onChanged: controller.setCountry,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: query.remoteOnly,
              onChanged: (_) => controller.toggleRemote(),
              title: Text(l10n.jobsRemoteOnly),
              secondary: const Icon(Icons.public_rounded),
            ),
            if (state.typeOptions.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              _GroupLabel(l10n.jobsEmploymentType),
              _ChipWrap(
                options: state.typeOptions,
                selected: query.employmentTypes,
                onToggle: controller.toggleType,
                labelBuilder: (o) => localizedEmploymentType(l10n, o),
              ),
            ],
            if (state.seniorityOptions.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              _GroupLabel(l10n.jobsSeniority),
              _ChipWrap(
                options: state.seniorityOptions,
                selected: query.seniorities,
                onToggle: controller.toggleSeniority,
                labelBuilder: (o) => localizedSeniority(l10n, o),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.jobsShowResults(state.results.length)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _ChipWrap extends StatelessWidget {
  const _ChipWrap({
    required this.options,
    required this.selected,
    required this.onToggle,
    this.labelBuilder,
  });

  final List<String> options;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  /// Maps a raw option value to its localized display label (identity if null).
  final String Function(String)? labelBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final option in options)
          FilterChip(
            label: Text(labelBuilder?.call(option) ?? option),
            selected: selected.contains(option),
            onSelected: (_) => onToggle(option),
            selectedColor: AppColors.emerald.withValues(alpha: 0.18),
            checkmarkColor: AppColors.emeraldDark,
            labelStyle: TextStyle(
              fontWeight: FontWeight.w600,
              color: selected.contains(option)
                  ? AppColors.emeraldDark
                  : theme.colorScheme.onSurface,
            ),
          ),
      ],
    );
  }
}
