import 'package:flutter/material.dart';

import '../../../../core/localization/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../domain/recommendation_models.dart';
import '../recommendations_l10n.dart';

/// Colour for a 0–100 strength score (green → amber → red).
Color recScoreColor(int score) {
  if (score >= 75) return AppColors.emerald;
  if (score >= 50) return AppColors.warning;
  return AppColors.error;
}

/// A titled section card wrapping one recommendation group.
class RecSection extends StatelessWidget {
  const RecSection({
    required this.icon,
    required this.title,
    required this.child,
    super.key,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(title,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        child,
      ],
    );
  }
}

/// A soft rounded card used for each recommendation item.
class RecCard extends StatelessWidget {
  const RecCard({required this.child, this.accent, this.onTap, super.key});

  final Widget child;
  final Color? accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final card = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: accent ?? theme.colorScheme.outline.withValues(alpha: 0.4),
          width: accent != null ? 1.4 : 1,
        ),
        boxShadow: AppShadows.card(dark: dark),
      ),
      child: child,
    );
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: card,
      ),
    );
  }
}

/// A small pill label.
class RecChip extends StatelessWidget {
  const RecChip({required this.label, this.icon, this.color, super.key});

  final String label;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = color ?? theme.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: c),
            const SizedBox(width: 4),
          ],
          Text(label,
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: c, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// The "why this fits" reason line shared by every recommendation.
class RecReason extends StatelessWidget {
  const RecReason(this.reason, {super.key});
  final String reason;

  @override
  Widget build(BuildContext context) {
    if (reason.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(Icons.lightbulb_outline_rounded,
                size: 14, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(reason,
                style: theme.textTheme.bodySmall?.copyWith(
                    height: 1.4,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.75))),
          ),
        ],
      ),
    );
  }
}

/// A recommended-job card that deep links to the job detail on tap.
class RecJobCard extends StatelessWidget {
  const RecJobCard({required this.job, required this.onTap, super.key});

  final JobRecommendation job;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final color = recScoreColor(job.confidence);
    return RecCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(job.title,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    if (job.company.isNotEmpty)
                      Text(job.company,
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6))),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              if (job.confidence > 0)
                RecChip(label: l10n.recConfidence(job.confidence), color: color),
            ],
          ),
          RecReason(job.reason),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(l10n.recViewJob,
                  style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700)),
              const SizedBox(width: 2),
              Icon(Icons.arrow_forward_rounded,
                  size: 14, color: theme.colorScheme.primary),
            ],
          ),
        ],
      ),
    );
  }
}

/// Priority badge (High / Medium / Low) with a strength colour.
class RecPriorityBadge extends StatelessWidget {
  const RecPriorityBadge(this.priority, {super.key});
  final RecPriority priority;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = switch (priority) {
      RecPriority.high => AppColors.error,
      RecPriority.medium => AppColors.warning,
      RecPriority.low => AppColors.emerald,
    };
    return RecChip(label: recPriorityLabel(l10n, priority), color: color);
  }
}

/// A skill-to-learn item.
class RecSkillTile extends StatelessWidget {
  const RecSkillTile({required this.skill, super.key});
  final SkillRecommendation skill;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RecCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(skill.skill,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: AppSpacing.sm),
              RecPriorityBadge(skill.priority),
            ],
          ),
          RecReason(skill.reason),
        ],
      ),
    );
  }
}

/// A certification item.
class RecCertTile extends StatelessWidget {
  const RecCertTile({required this.cert, super.key});
  final CertificationRecommendation cert;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RecCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(cert.name,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          if (cert.provider.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(cert.provider,
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.6))),
            ),
          RecReason(cert.reason),
        ],
      ),
    );
  }
}

/// A course item.
class RecCourseTile extends StatelessWidget {
  const RecCourseTile({required this.course, super.key});
  final CourseRecommendation course;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RecCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(course.title,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (course.provider.isNotEmpty)
                  Text(course.provider,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6))),
                if (course.skill.isNotEmpty)
                  RecChip(label: course.skill, icon: Icons.school_outlined),
              ],
            ),
          ),
          RecReason(course.reason),
        ],
      ),
    );
  }
}

/// The career roadmap as a horizon-labelled vertical timeline.
class RecRoadmap extends StatelessWidget {
  const RecRoadmap({required this.steps, super.key});
  final List<RoadmapStep> steps;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    if (i != steps.length - 1)
                      Expanded(
                        child: Container(
                          width: 2,
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.25),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                        bottom: i == steps.length - 1 ? 0 : AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RecChip(
                            label: recHorizonLabel(l10n, steps[i].horizon),
                            icon: Icons.schedule_rounded),
                        const SizedBox(height: 4),
                        if (steps[i].title.isNotEmpty)
                          Text(steps[i].title,
                              style: theme.textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700)),
                        if (steps[i].description.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(steps[i].description,
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(height: 1.4)),
                          ),
                        if (steps[i].focusSkills.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                for (final s in steps[i].focusSkills)
                                  RecChip(label: s),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// A next-best-action card with a CTA that deep links via [onTap].
class RecActionCard extends StatelessWidget {
  const RecActionCard({required this.action, required this.onTap, super.key});

  final NextAction action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final cta = recActionLabel(l10n, action.type);
    return RecCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(action.title,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: AppSpacing.sm),
              RecPriorityBadge(action.priority),
            ],
          ),
          if (action.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(action.description,
                  style: theme.textTheme.bodySmall?.copyWith(height: 1.4)),
            ),
          const SizedBox(height: AppSpacing.sm),
          // Wrap (not Row) so a long estimated-time chip + CTA never overflow —
          // the CTA drops to its own line when they don't fit side by side.
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              if (action.estimatedTime.isNotEmpty)
                RecChip(
                    label: action.estimatedTime,
                    icon: Icons.timer_outlined,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6))
              else
                const SizedBox.shrink(),
              if (cta.isNotEmpty && onTap != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(cta,
                        style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(width: 2),
                    Icon(Icons.arrow_forward_rounded,
                        size: 14, color: theme.colorScheme.primary),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
