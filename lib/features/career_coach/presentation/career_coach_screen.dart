import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/responsive.dart';
import '../application/career_coach_controller.dart';
import 'widgets/chat_bubble.dart';
import 'widgets/chat_input.dart';

/// AI Career Coach — a streaming chat assistant for career guidance, learning
/// roadmaps, interview prep, and skill advice. Personalized with the user's
/// analyzed resume when one is available.
class CareerCoachScreen extends ConsumerStatefulWidget {
  const CareerCoachScreen({this.seedPrompt, super.key});

  /// Optional initial user message to send on open (e.g. deep-linked from a
  /// job's "Ask the coach about this job"). Ignored while a reply is streaming.
  final String? seedPrompt;

  @override
  ConsumerState<CareerCoachScreen> createState() => _CareerCoachScreenState();
}

class _CareerCoachScreenState extends ConsumerState<CareerCoachScreen> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    final seed = widget.seedPrompt?.trim();
    if (seed != null && seed.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(careerCoachControllerProvider.notifier).sendMessage(seed);
      });
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: AppDurations.fast,
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(careerCoachControllerProvider);
    final controller = ref.read(careerCoachControllerProvider.notifier);

    // Auto-scroll as messages grow / stream.
    ref.listen(careerCoachControllerProvider, (prev, next) {
      if (next.messages.isNotEmpty) _scrollToBottom();
      final failure = next.failure;
      if (failure != null && failure != prev?.failure) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(_failureMessage(l10n, failure)),
          ));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.coachTitle),
        actions: [
          if (state.messages.isNotEmpty)
            IconButton(
              tooltip: l10n.coachClear,
              onPressed: controller.clearChat,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ResponsiveCenter(
          maxWidth: 720,
          child: Column(
            children: [
              Expanded(
                child: state.isEmpty
                    ? _EmptyState(onPickPrompt: controller.sendMessage)
                    : ListView.builder(
                        controller: _scroll,
                        padding: EdgeInsets.symmetric(
                          horizontal: context.horizontalGutter,
                          vertical: AppSpacing.md,
                        ),
                        itemCount: state.messages.length,
                        itemBuilder: (context, i) => ChatBubble(
                          message: state.messages[i],
                          onRetry: controller.retryLast,
                        ),
                      ),
              ),
              ChatInput(
                enabled: !state.isStreaming,
                onSend: controller.sendMessage,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shown before the first message: coach intro + tappable starter prompts.
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onPickPrompt});
  final ValueChanged<String> onPickPrompt;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final prompts = [
      l10n.coachPrompt1,
      l10n.coachPrompt2,
      l10n.coachPrompt3,
      l10n.coachPrompt4,
    ];

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: context.horizontalGutter,
          vertical: AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: AppColors.ctaGradient,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: AppShadows.brandGlow,
              ),
              child: const Icon(Icons.psychology_outlined,
                  color: AppColors.white, size: 44),
            ).animate().scale(duration: 400.ms, curve: AppCurves.spring),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.coachIntroTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ).animate(delay: 100.ms).fadeIn().moveY(begin: 10, end: 0),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.coachIntroBody,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                height: 1.4,
              ),
            ).animate(delay: 160.ms).fadeIn(),
            const SizedBox(height: AppSpacing.xl),
            for (var i = 0; i < prompts.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _PromptChip(
                  label: prompts[i],
                  onTap: () => onPickPrompt(prompts[i]),
                ).animate(delay: (220 + i * 60).ms).fadeIn().moveY(begin: 10, end: 0),
              ),
          ],
        ),
      ),
    );
  }
}

class _PromptChip extends StatelessWidget {
  const _PromptChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.md - 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border:
                Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Icon(Icons.auto_awesome_outlined,
                  size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Icon(Icons.arrow_outward_rounded,
                  size: 16,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
            ],
          ),
        ),
      ),
    );
  }
}

String _failureMessage(AppLocalizations l10n, CoachFailure failure) {
  return switch (failure) {
    CoachFailure.notConfigured => l10n.coachErrNotConfigured,
    CoachFailure.network => l10n.coachErrNetwork,
    CoachFailure.quota => l10n.coachErrQuota,
    CoachFailure.blocked => l10n.coachErrBlocked,
    CoachFailure.emptyResponse => l10n.coachErrEmpty,
    CoachFailure.unknown => l10n.coachErrUnknown,
  };
}
