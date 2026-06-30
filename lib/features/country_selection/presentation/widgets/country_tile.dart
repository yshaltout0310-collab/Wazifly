import 'package:flutter/material.dart';

import '../../../../core/theme/app_dimensions.dart';
import '../../../../shared/models/country_model.dart';

/// A single country row: flag, name, and dialing code.
class CountryTile extends StatelessWidget {
  const CountryTile({
    required this.country,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final CountryModel country;
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
            vertical: 14,
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
              Text(country.flag, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  country.name,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                country.dialCode,
                // Dial codes are written "+974" (plus first) in every locale;
                // force LTR so the leading "+" isn't bidi-reordered to "974+"
                // when the app is in RTL (Arabic).
                textDirection: TextDirection.ltr,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.6),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              if (selected) ...[
                const SizedBox(width: AppSpacing.sm),
                Icon(Icons.check_circle_rounded, color: scheme.primary),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
