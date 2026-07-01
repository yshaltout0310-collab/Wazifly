import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_dimensions.dart';

/// Circular ATS score gauge (0–100) with a colored progress arc, the numeric
/// score, and a qualitative [label] beneath it.
class AtsScoreGauge extends StatelessWidget {
  const AtsScoreGauge({
    required this.score,
    required this.color,
    required this.label,
    required this.caption,
    this.size = 168,
    super.key,
  });

  final int score;
  final Color color;

  /// Qualitative band label (e.g. "Good"), already localized.
  final String label;

  /// Caption above the gauge (e.g. "ATS Score"), already localized.
  final String caption;

  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final track = theme.colorScheme.outline.withValues(alpha: 0.30);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          caption,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: size,
          height: size,
          child: TweenAnimationBuilder<double>(
            duration: AppDurations.slow,
            curve: AppCurves.emphasized,
            tween: Tween(begin: 0, end: score / 100),
            builder: (context, value, _) {
              return CustomPaint(
                painter: _GaugePainter(
                  progress: value,
                  color: color,
                  trackColor: track,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(value * 100).round()}',
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: color,
                          height: 1.0,
                        ),
                      ),
                      Text(
                        '/ 100',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color:
                              theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text(
            label,
            style: theme.textTheme.labelLarge
                ?.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  final double progress;
  final Color color;
  final Color trackColor;

  static const double _stroke = 14;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - _stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round
      ..color = trackColor;

    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round
      ..color = color;

    // Full track ring.
    canvas.drawArc(rect, 0, 2 * math.pi, false, trackPaint);
    // Progress arc, starting at the top (-90°).
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.progress != progress || old.color != color;
}
