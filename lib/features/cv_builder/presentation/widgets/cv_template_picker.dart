import 'package:flutter/material.dart';

import '../../../../core/localization/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../domain/cv_template.dart';
import '../cv_l10n.dart';

/// Horizontal template picker driven by [cvTemplateCatalog]. Implemented
/// templates are selectable; the rest show a "Coming soon" badge. Adding a
/// template later needs no change here — it just appears from the catalog.
class CvTemplatePicker extends StatelessWidget {
  const CvTemplatePicker({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final CvTemplateId selected;
  final ValueChanged<CvTemplateId> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      height: 104,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        itemCount: cvTemplateCatalog.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) {
          final meta = cvTemplateCatalog[i];
          return _TemplateCard(
            name: cvTemplateName(l10n, meta.id),
            desc: cvTemplateDesc(l10n, meta.id),
            available: meta.available,
            selected: meta.id == selected,
            comingSoon: l10n.comingSoonBadge,
            onTap: meta.available ? () => onSelected(meta.id) : null,
          );
        },
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.name,
    required this.desc,
    required this.available,
    required this.selected,
    required this.comingSoon,
    required this.onTap,
  });

  final String name;
  final String desc;
  final bool available;
  final bool selected;
  final String comingSoon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Opacity(
      opacity: available ? 1 : 0.6,
      child: Material(
        color: selected
            ? scheme.primary.withValues(alpha: 0.10)
            : scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: onTap,
          child: Container(
            width: 150,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: selected
                    ? scheme.primary
                    : scheme.outline.withValues(alpha: 0.4),
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.description_outlined,
                        size: 18, color: scheme.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (selected)
                      Icon(Icons.check_circle_rounded,
                          size: 16, color: scheme.primary),
                  ],
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: Text(
                    desc,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                if (!available)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      comingSoon,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
