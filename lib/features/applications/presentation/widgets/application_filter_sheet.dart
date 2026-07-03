import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../shared/models/application.dart';
import '../../application/applications_controller.dart';
import 'status_chip.dart';

/// Bottom sheet to filter applications by status. Reads/writes the shared
/// [ApplicationsFilter] live.
class ApplicationFilterSheet extends ConsumerWidget {
  const ApplicationFilterSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => const ApplicationFilterSheet(),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final filter = ref.watch(applicationsFilterProvider);
    final controller = ref.read(applicationsFilterProvider.notifier);

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
                  l10n.appsFilterByStatus,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                if (filter.isActive)
                  TextButton(
                    onPressed: controller.clear,
                    child: Text(l10n.jobsClearFilters),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final status in ApplicationStatus.values)
                  FilterChip(
                    label: Text(applicationStatusLabel(l10n, status)),
                    selected: filter.statuses.contains(status),
                    onSelected: (_) => controller.toggleStatus(status),
                    selectedColor:
                        applicationStatusColor(status).withValues(alpha: 0.18),
                    checkmarkColor: applicationStatusColor(status),
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: filter.statuses.contains(status)
                          ? AppColors.emeraldDark
                          : theme.colorScheme.onSurface,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.jobsFilters),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
