import 'package:flutter/material.dart';

import '../../../../core/localization/generated/app_localizations.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../shared/models/learning_profile.dart';
import '../learning_l10n.dart';

/// One learning category as a card: a titled header with an add button and the
/// category's interests as removable/editable chips.
class InterestCategoryCard extends StatelessWidget {
  const InterestCategoryCard({
    required this.category,
    required this.items,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final LearningCategory category;
  final List<LearningInterest> items;
  final VoidCallback onAdd;
  final ValueChanged<LearningInterest> onEdit;
  final ValueChanged<LearningInterest> onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border:
            Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
        boxShadow: AppShadows.card(dark: dark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  category.label(l10n),
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                l10n.learningItemsCount(items.length),
                style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55)),
              ),
              const SizedBox(width: 4),
              IconButton(
                tooltip: l10n.learningAdd,
                visualDensity: VisualDensity.compact,
                onPressed: onAdd,
                icon: Icon(Icons.add_circle_outline_rounded,
                    color: theme.colorScheme.primary),
              ),
            ],
          ),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text(
                l10n.learningEmptyCategory,
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final item in items)
                    InputChip(
                      label: Text(item.label),
                      onPressed: () => onEdit(item),
                      onDeleted: () => onDelete(item),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
