import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Soft "aurora" gradient backdrop used on hero screens (splash, welcome,
/// onboarding). Blurred color blobs over a tinted base add premium depth.
///
/// The blobs are STATIC (rasterized once inside a [RepaintBoundary]) rather
/// than animated — animating large Gaussian blurs every frame is very
/// expensive on low-end GPUs / emulators and can jank the UI thread. The look
/// is identical; only the per-frame cost is removed.
class AuroraBackground extends StatelessWidget {
  const AuroraBackground({required this.child, this.intensity = 1.0, super.key});

  final Widget child;

  /// Scales blob opacity (0–1). Lower it on content-dense screens.
  final double intensity;

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final Color base =
        dark ? AppColors.darkBackground : AppColors.lightBackground;

    return Stack(
      children: [
        Positioned.fill(child: ColoredBox(color: base)),
        RepaintBoundary(
          child: Stack(
            children: [
              _Blob(
                color: (dark ? AppColors.auroraDarkA : AppColors.auroraLightA)
                    .withValues(alpha: intensity),
                size: 320,
                alignment: const Alignment(-1.1, -0.9),
              ),
              _Blob(
                color: (dark ? AppColors.auroraDarkB : AppColors.auroraLightB)
                    .withValues(alpha: intensity),
                size: 360,
                alignment: const Alignment(1.2, -0.2),
              ),
              _Blob(
                color: (dark ? AppColors.auroraDarkA : AppColors.auroraLightC)
                    .withValues(alpha: intensity),
                size: 300,
                alignment: const Alignment(-0.6, 1.1),
              ),
            ],
          ),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({
    required this.color,
    required this.size,
    required this.alignment,
  });

  final Color color;
  final double size;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 34, sigmaY: 34),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color, color.withValues(alpha: 0)],
            ),
          ),
        ),
      ),
    );
  }
}
