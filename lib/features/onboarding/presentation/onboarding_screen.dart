import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/navigation/route_names.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../shared/widgets/aurora_background.dart';
import '../../../shared/widgets/primary_button.dart';
import '../application/onboarding_controller.dart';
import '../domain/onboarding_page.dart';
import 'widgets/onboarding_page_view.dart';

/// Three-page onboarding carousel ending in "Get Started".
///
/// Completing (or skipping) records the onboarding flag and routes to the
/// welcome / authentication flow.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({this.replay = false, super.key});

  /// Query-param key used to launch onboarding as a re-watchable tour from
  /// Settings (pops back instead of advancing the welcome flow).
  static const String replayParam = 'replay';

  /// When true, finishing returns to the previous screen (Settings) rather
  /// than completing onboarding and routing to Welcome.
  final bool replay;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<OnboardingPage> _pages(AppLocalizations l10n) => [
        OnboardingPage(
          icon: Icons.work_outline_rounded,
          title: l10n.onboardingTitle1,
          body: l10n.onboardingBody1,
        ),
        OnboardingPage(
          icon: Icons.auto_awesome_rounded,
          title: l10n.onboardingTitle2,
          body: l10n.onboardingBody2,
          features: [
            (icon: Icons.description_rounded, label: l10n.onboardingFeatureResume),
            (icon: Icons.psychology_rounded, label: l10n.onboardingFeatureCoach),
            (icon: Icons.record_voice_over_rounded, label: l10n.onboardingFeatureInterview),
            (icon: Icons.bolt_rounded, label: l10n.onboardingFeatureMatching),
          ],
        ),
        OnboardingPage(
          icon: Icons.public_rounded,
          title: l10n.onboardingTitle3,
          body: l10n.onboardingBody3,
        ),
      ];

  Future<void> _finish() async {
    // Replay mode (from Settings): just return where we came from.
    if (widget.replay) {
      if (mounted) context.pop();
      return;
    }
    await ref.read(onboardingControllerProvider.notifier).complete();
    if (!mounted) return;
    // pushReplacement (not go) so the back stack — language → country → welcome
    // — is preserved: system Back steps back through the flow instead of
    // exiting the app. The completed onboarding is dropped from the stack so
    // Back doesn't re-enter the one-time tour.
    context.pushReplacementNamed(RouteNames.welcome);
  }

  void _next(int lastIndex) {
    if (_index >= lastIndex) {
      _finish();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pages = _pages(l10n);
    final lastIndex = pages.length - 1;
    final isLast = _index == lastIndex;

    return PopScope(
      // System Back goes to the previous page first; only pops the route
      // (to the previous screen) when already on the first page.
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _index > 0) {
          _controller.previousPage(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
          );
        }
      },
      child: Scaffold(
        body: AuroraBackground(
          intensity: 0.7,
          child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: AnimatedOpacity(
                    opacity: isLast ? 0 : 1,
                    duration: AppDurations.fast,
                    child: TextButton(
                      onPressed: isLast ? null : _finish,
                      child: Text(l10n.skip),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: pages.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) =>
                      OnboardingPageView(page: pages[i]),
                ),
              ),
              _Dots(count: pages.length, index: _index),
              const SizedBox(height: AppSpacing.lg),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: PrimaryButton(
                  label: isLast ? l10n.getStarted : l10n.next,
                  icon: isLast ? Icons.arrow_forward_rounded : null,
                  onPressed: () => _next(lastIndex),
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

/// Animated page indicator dots.
class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 8,
            width: i == index ? 26 : 8,
            decoration: BoxDecoration(
              color: i == index
                  ? scheme.primary
                  : scheme.primary.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
      ],
    );
  }
}
