import 'package:flutter/material.dart';

import '../../../../core/theme/app_dimensions.dart';
import '../../../../shared/models/language_model.dart';

/// A single selectable language row inside a rounded card.
class LanguageTile extends StatelessWidget {
  const LanguageTile({
    required this.language,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final LanguageModel language;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: selected
          ? scheme.primary.withValues(alpha: 0.10)
          : scheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: selected
                  ? scheme.primary
                  : scheme.outline.withValues(alpha: 0.6),
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: scheme.primary.withValues(alpha: 0.12),
                child: Text(
                  language.code.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      language.nativeName,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      language.englishName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              if (!language.isSupported)
                Icon(
                  Icons.schedule_rounded,
                  size: 18,
                  color: scheme.onSurface.withValues(alpha: 0.4),
                )
              else if (selected)
                Icon(Icons.check_circle_rounded, color: scheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}
