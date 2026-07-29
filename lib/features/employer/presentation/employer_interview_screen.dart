import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/status_view.dart';
import '../application/interview_kit_controller.dart';
import '../domain/interview_kit.dart';

/// Employer AI tool: generates a role-specific interview kit — questions with
/// model answers, an overall readiness score, and what to look for / probe.
/// Reuses the shared `AiService` seam via [InterviewKitController].
class EmployerInterviewScreen extends ConsumerStatefulWidget {
  const EmployerInterviewScreen({super.key});

  @override
  ConsumerState<EmployerInterviewScreen> createState() =>
      _EmployerInterviewScreenState();
}

class _EmployerInterviewScreenState
    extends ConsumerState<EmployerInterviewScreen> {
  final _role = TextEditingController();
  final _focus = TextEditingController();
  bool _roleError = false;

  @override
  void dispose() {
    _role.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _generate() {
    final role = _role.text.trim();
    if (role.isEmpty) {
      setState(() => _roleError = true);
      return;
    }
    setState(() => _roleError = false);
    FocusScope.of(context).unfocus();
    ref
        .read(interviewKitControllerProvider.notifier)
        .generate(role, focus: _focus.text);
  }

  String _failureText(AppLocalizations l10n, InterviewKitFailure f) =>
      switch (f) {
        InterviewKitFailure.notConfigured =>
          l10n.employerInterviewErrNotConfigured,
        InterviewKitFailure.network => l10n.employerInterviewErrNetwork,
        InterviewKitFailure.quota => l10n.employerInterviewErrQuota,
        InterviewKitFailure.empty => l10n.employerInterviewErrEmpty,
        InterviewKitFailure.invalidResponse ||
        InterviewKitFailure.unknown =>
          l10n.employerInterviewErrGeneric,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(interviewKitControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.employerInterviewTitle)),
      body: SafeArea(
        child: ResponsiveCenter(
          maxWidth: 720,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(context.horizontalGutter,
                    AppSpacing.md, context.horizontalGutter, AppSpacing.sm),
                child: _InputForm(
                  role: _role,
                  focus: _focus,
                  roleError: _roleError,
                  loading: state.isLoading,
                  hasResult: state.kit != null,
                  onGenerate: _generate,
                ),
              ),
              Expanded(
                child: switch (state.phase) {
                  InterviewKitPhase.loading => StatusView.loading(
                      title: l10n.employerInterviewLoading),
                  InterviewKitPhase.error => StatusView.error(
                      message: _failureText(l10n, state.failure!),
                      onRetry: _generate,
                    ),
                  InterviewKitPhase.ready when state.kit != null =>
                    _Results(kit: state.kit!),
                  _ => StatusView.empty(
                      icon: Icons.event_available_outlined,
                      title: l10n.employerInterviewEmptyTitle,
                      message: l10n.employerInterviewEmptyBody,
                    ),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InputForm extends StatelessWidget {
  const _InputForm({
    required this.role,
    required this.focus,
    required this.roleError,
    required this.loading,
    required this.hasResult,
    required this.onGenerate,
  });

  final TextEditingController role;
  final TextEditingController focus;
  final bool roleError;
  final bool loading;
  final bool hasResult;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.employerInterviewSubtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.65)),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: role,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: l10n.employerInterviewRoleLabel,
            hintText: l10n.employerInterviewRoleHint,
            prefixIcon: const Icon(Icons.work_outline_rounded),
            errorText: roleError ? l10n.employerInterviewRoleRequired : null,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: focus,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => loading ? null : onGenerate(),
          decoration: InputDecoration(
            labelText: l10n.employerInterviewFocusLabel,
            hintText: l10n.employerInterviewFocusHint,
            prefixIcon: const Icon(Icons.center_focus_strong_outlined),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        PrimaryButton(
          label: hasResult
              ? l10n.employerInterviewRegenerate
              : l10n.employerInterviewGenerate,
          icon: Icons.auto_awesome_rounded,
          loading: loading,
          onPressed: loading ? null : onGenerate,
        ),
      ],
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({required this.kit});
  final InterviewKit kit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: EdgeInsets.fromLTRB(context.horizontalGutter, AppSpacing.md,
          context.horizontalGutter, AppSpacing.xxl),
      children: [
        _ScoreCard(score: kit.score, summary: kit.summary)
            .animate()
            .fadeIn()
            .moveY(begin: 10, end: 0),
        if (kit.questions.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          _SectionTitle(l10n.employerInterviewQuestionsTitle),
          const SizedBox(height: AppSpacing.sm),
          for (var i = 0; i < kit.questions.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _QuestionCard(index: i + 1, question: kit.questions[i])
                  .animate(delay: (60 * i).ms)
                  .fadeIn()
                  .moveY(begin: 10, end: 0),
            ),
        ],
        if (kit.strengths.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          _BulletCard(
            title: l10n.employerInterviewStrengthsTitle,
            icon: Icons.check_circle_outline_rounded,
            color: AppColors.teal,
            items: kit.strengths,
          ),
        ],
        if (kit.improvements.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _BulletCard(
            title: l10n.employerInterviewImprovementsTitle,
            icon: Icons.search_rounded,
            color: AppColors.royalBlue,
            items: kit.improvements,
          ),
        ],
      ],
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.score, required this.summary});
  final int score;
  final String summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppColors.ctaGradient,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.brandGlow,
      ),
      child: Row(
        children: [
          Container(
            width: 68,
            height: 68,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$score',
              style: theme.textTheme.headlineSmall?.copyWith(
                  color: AppColors.white, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.employerInterviewScoreLabel,
                  style: theme.textTheme.labelLarge?.copyWith(
                      color: AppColors.white.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w700),
                ),
                if (summary.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    summary,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: AppColors.white),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.index, required this.question});
  final int index;
  final InterviewKitQuestion question;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
        boxShadow: AppShadows.card(dark: dark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 13,
                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                child: Text('$index',
                    style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(question.question,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700, height: 1.3)),
              ),
            ],
          ),
          if (question.focus.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 34),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(question.focus,
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ],
          if (question.suggestedAnswer.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.employerInterviewSuggestedAnswer,
                      style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(question.suggestedAnswer,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.4)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BulletCard extends StatelessWidget {
  const _BulletCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
        boxShadow: AppShadows.card(dark: dark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.sm),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 18, color: color),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                      child: Text(item,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(height: 1.35))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(text,
        style: theme.textTheme.titleMedium
            ?.copyWith(fontWeight: FontWeight.w800));
  }
}
