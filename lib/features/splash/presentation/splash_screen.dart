import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/navigation/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../features/auth/application/auth_providers.dart';
import '../../../features/onboarding/application/onboarding_controller.dart';
import '../../../features/security/application/biometric_settings_controller.dart';
import '../../../features/user_type/application/user_type_controller.dart';
import '../../../features/user_type/domain/user_type.dart';

/// Premium branded splash. A Wazifly navy-to-royal-blue gradient (seamless with
/// the native splash) with a glowing, pulsing logo and a choreographed wordmark
/// reveal.
/// Routes onward once persisted state is read.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future<void>.delayed(AppDurations.splash);
    if (!mounted) return;

    final onboardingDone = ref.read(onboardingControllerProvider);
    if (!onboardingDone) {
      context.goNamed(RouteNames.language);
      return;
    }

    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) {
      context.goNamed(RouteNames.welcome);
      return;
    }

    // Email-verification gate: a persisted but unverified session can't enter the
    // app. Sits before the biometric gate (nothing to unlock until verified).
    if (!user.emailVerified) {
      context.goNamed(RouteNames.verifyEmail);
      return;
    }

    // Biometric app-lock gate: only when a session exists AND the user enabled
    // biometric login AND the device can currently satisfy it. Otherwise the
    // flow is byte-for-byte identical to before (existing users are unaffected).
    final biometric = await ref
        .read(biometricSettingsControllerProvider.notifier)
        .ensureLoaded();
    if (!mounted) return;
    if (biometric.gateActive) {
      context.goNamed(RouteNames.appLock);
      return;
    }

    final type = ref.read(userTypeControllerProvider);
    context.goNamed(switch (type) {
      null => RouteNames.userType,
      UserType.employer => RouteNames.employerHome,
      UserType.jobSeeker => RouteNames.home,
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.deepSea, AppColors.emeraldDark, AppColors.emerald],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Soft depth blobs.
            const _SplashBlob(
              alignment: Alignment(-1.2, -1.0),
              color: AppColors.emerald,
              size: 360,
            ),
            const _SplashBlob(
              alignment: Alignment(1.3, 1.1),
              color: AppColors.mint,
              size: 320,
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _GlowLogo(),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    l10n.appName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  )
                      .animate(delay: 450.ms)
                      .fadeIn(duration: 600.ms)
                      .moveY(begin: 18, end: 0, curve: AppCurves.emphasized),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.splashTagline,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.white.withValues(alpha: 0.85),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                    ),
                  ).animate(delay: 650.ms).fadeIn(duration: 600.ms),
                ],
              ),
            ),
            Align(
              alignment: const Alignment(0, 0.78),
              child: const _LoadingDots()
                  .animate(delay: 1000.ms)
                  .fadeIn(duration: 500.ms),
            ),
          ],
        ),
      ),
    );
  }
}

/// The Wazifly W mark with a soft halo glow and a pulsing ring.
class _GlowLogo extends StatelessWidget {
  const _GlowLogo();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Halo glow.
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.white.withValues(alpha: 0.30),
              ),
            ),
          ),
          // Expanding pulse rings.
          for (var i = 0; i < 2; i++)
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.white.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
            )
                .animate(
                  onPlay: (c) => c.repeat(),
                  delay: (i * 1100).ms,
                )
                .scaleXY(begin: 0.7, end: 1.6, duration: 2200.ms)
                .fadeOut(duration: 2200.ms, curve: Curves.easeOut),
          // The Wazifly W mark (generated from assets/brand/wazifly_logo.svg).
          Image.asset(
            'assets/images/wazifly_mark.png',
            width: 96,
            height: 96,
            filterQuality: FilterQuality.high,
          )
              .animate()
              .scale(
                duration: 700.ms,
                curve: AppCurves.spring,
                begin: const Offset(0.4, 0.4),
                end: const Offset(1, 1),
              )
              .fadeIn(duration: 450.ms)
              .then()
              .shimmer(
                duration: 1500.ms,
                color: AppColors.skyBlue.withValues(alpha: 0.8),
              ),
        ],
      ),
    );
  }
}

class _SplashBlob extends StatelessWidget {
  const _SplashBlob({
    required this.alignment,
    required this.color,
    required this.size,
  });

  final Alignment alignment;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: RepaintBoundary(
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 44, sigmaY: 44),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  color.withValues(alpha: 0.45),
                  color.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Three white dots pulsing in sequence.
class _LoadingDots extends StatelessWidget {
  const _LoadingDots();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.9),
            shape: BoxShape.circle,
          ),
        )
            .animate(
              onPlay: (c) => c.repeat(reverse: true),
              delay: (i * 180).ms,
            )
            .fadeIn(duration: 500.ms)
            .scaleXY(begin: 0.5, end: 1.0, duration: 500.ms);
      }),
    );
  }
}
