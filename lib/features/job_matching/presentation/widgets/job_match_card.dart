import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/localization/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../shared/models/job_l10n.dart';
import '../../domain/job_match.dart';

/// A single ranked job result: header (title/company + score ring), meta chips
/// (location, type, seniority), the "why it matches" reason, and matching /
/// missing skill chips.
class JobMatchCard extends StatelessWidget {
  const JobMatchCard({required this.match, super.key});

  final JobMatch match;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final lang = Localizations.localeOf(context).languageCode;
    final job = match.job;
    final band = _band(l10n, match.matchScore);

    return Container(
      width: double.infinity,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.titleFor(lang),
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      job.company,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.65),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _ScoreRing(score: match.matchScore, color: band.color),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              _MetaChip(
                icon: job.remote
                    ? Icons.public_rounded
                    : Icons.place_outlined,
                label: job.locationFor(lang),
              ),
              if (job.employmentType.isNotEmpty)
                _MetaChip(
                    icon: Icons.work_outline_rounded,
                    label: localizedEmploymentType(l10n, job.employmentType)),
              if (job.seniority.isNotEmpty)
                _MetaChip(
                    icon: Icons.trending_up_rounded,
                    label: localizedSeniority(l10n, job.seniority)),
            ],
          ),
          Container(
            margin: const EdgeInsets.only(top: AppSpacing.sm),
            padding: const EdgeInsets.symmetric(
                horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: band.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              band.label,
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: band.color, fontWeight: FontWeight.w700),
            ),
          ),
          if (match.reason.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              match.reason,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
            ),
          ],
          if (match.matchingSkills.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _SkillGroup(
              label: l10n.jobMatchMatchingSkills,
              skills: match.matchingSkills,
              color: AppColors.emerald,
              icon: Icons.check_rounded,
            ),
          ],
          if (match.missingSkills.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _SkillGroup(
              label: l10n.jobMatchMissingSkills,
              skills: match.missingSkills,
              color: AppColors.warning,
              icon: Icons.add_rounded,
            ),
          ],
        ],
      ),
    );
  }
}

/// Compact circular match-score badge (0–100 rendered as a percentage).
class _ScoreRing extends StatelessWidget {
  const _ScoreRing({required this.score, required this.color});

  final int score;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 56,
      height: 56,
      child: CustomPaint(
        painter: _RingPainter(
          progress: score / 100,
          color: color,
          trackColor: theme.colorScheme.outline.withValues(alpha: 0.25),
        ),
        child: Center(
          child: Text(
            '$score%',
            style: theme.textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  final double progress;
  final Color color;
  final Color trackColor;

  static const double _stroke = 5;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - _stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round
      ..color = trackColor;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round
      ..color = color;

    canvas.drawArc(rect, 0, 2 * math.pi, false, track);
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress.clamp(0.0, 1.0),
        false, arc);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 14,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
          const SizedBox(width: 5),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

/// A labelled row of skill chips (matching or missing).
class _SkillGroup extends StatelessWidget {
  const _SkillGroup({
    required this.label,
    required this.skills,
    required this.color,
    required this.icon,
  });

  final String label;
  final List<String> skills;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final skill in skills)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: color.withValues(alpha: 0.30)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 13, color: color),
                    const SizedBox(width: 4),
                    Text(
                      skill,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.emeraldDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

({Color color, String label}) _band(AppLocalizations l10n, int score) {
  if (score >= 80) {
    return (color: AppColors.emerald, label: l10n.jobMatchStrong);
  }
  if (score >= 60) {
    return (color: AppColors.teal, label: l10n.jobMatchGood);
  }
  if (score >= 40) {
    return (color: AppColors.warning, label: l10n.jobMatchFair);
  }
  return (color: AppColors.error, label: l10n.jobMatchWeak);
}
