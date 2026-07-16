import 'package:flutter/material.dart';

import '../../../../core/localization/generated/app_localizations.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../domain/cv_template.dart';
import '../cv_l10n.dart';

/// Horizontal template picker driven by [cvTemplateCatalog]. Every catalogued
/// template is implemented and selectable — adding one needs no change here, it
/// just appears from the catalog.
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
            selected: meta.id == selected,
            onTap: () => onSelected(meta.id),
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
    required this.selected,
    required this.onTap,
  });

  final String name;
  final String desc;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: selected ? scheme.primary.withValues(alpha: 0.10) : scheme.surface,
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
            ],
          ),
        ),
      ),
    );
  }
}
