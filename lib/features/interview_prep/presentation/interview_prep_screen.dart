import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/navigation/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/models/job.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../auth/presentation/widgets/auth_error.dart';
import '../application/interview_controller.dart';
import '../domain/interview_models.dart';
import 'interview_l10n.dart';
import 'widgets/score_display.dart';

/// The AI Interview Prep flow: pick a type → answer AI questions with scored
/// feedback → get a streamed overall debrief. Optionally tailored to a [job].
class InterviewPrepScreen extends ConsumerStatefulWidget {
  const InterviewPrepScreen({this.job, super.key});

  final Job? job;

  @override
  ConsumerState<InterviewPrepScreen> createState() =>
      _InterviewPrepScreenState();
}

class _InterviewPrepScreenState extends ConsumerState<InterviewPrepScreen> {
  final _answer = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(interviewControllerProvider.notifier).prepare(job: widget.job);
      }
    });
  }

  @override
  void dispose() {
    _answer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(interviewControllerProvider);

    // Snackbar for per-answer evaluation failures (the phase stays inProgress).
    ref.listen(interviewControllerProvider.select((s) => s.failure),
        (prev, next) {
      if (next != null &&
          ref.read(interviewControllerProvider).phase ==
              InterviewPhase.inProgress) {
        showAuthSnack(context, interviewFailureMessage(l10n, next),
            isError: true);
        ref.read(interviewControllerProvider.notifier).clearFailure();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.interviewTitle),
        actions: [
          IconButton(
            tooltip: l10n.interviewHistoryAction,
            icon: const Icon(Icons.history_rounded),
            onPressed: () => context.pushNamed(RouteNames.interviewHistory),
          ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveCenter(
          child: AnimatedSwitcher(
            duration: AppDurations.medium,
            child: KeyedSubtree(
              key: ValueKey(_phaseKey(state)),
              child: switch (state.phase) {
                InterviewPhase.setup => _Setup(job: widget.job),
                InterviewPhase.generating =>
                  _Busy(message: l10n.interviewGenerating),
                InterviewPhase.inProgress => _inProgress(l10n, state),
                InterviewPhase.summarizing ||
                InterviewPhase.summary =>
                  _summary(l10n, state),
                InterviewPhase.error => _error(l10n, state),
              },
            ),
          ),
        ),
      ),
    );
  }

  // Distinct key per rendered phase (so answering the next question animates).
  String _phaseKey(InterviewState s) => switch (s.phase) {
        InterviewPhase.inProgress =>
          'q${s.currentIndex}_${s.hasAnsweredCurrent}',
        InterviewPhase.summarizing || InterviewPhase.summary => 'summary',
        _ => s.phase.name,
      };

  // --- In-progress: one question at a time ---

  Widget _inProgress(AppLocalizations l10n, InterviewState state) {
    final theme = Theme.of(context);
    final q = state.currentQuestion;
    if (q == null) return const SizedBox.shrink();
    final total = state.questions.length;
    final feedback = state.currentFeedback;

    return ListView(
      padding: EdgeInsets.fromLTRB(context.horizontalGutter, AppSpacing.lg,
          context.horizontalGutter, AppSpacing.xxl),
      children: [
        Text(l10n.interviewQuestionOf(state.currentIndex + 1, total),
            style: theme.textTheme.labelLarge
                ?.copyWith(color: theme.colorScheme.primary)),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: LinearProgressIndicator(
            value: (state.currentIndex + 1) / total,
            minHeight: 6,
            backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.25),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (q.focus.isNotEmpty) ...[
                _Chip(label: '${l10n.interviewFocusLabel}: ${q.focus}'),
                const SizedBox(height: AppSpacing.sm),
              ],
              Text(q.text,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700, height: 1.4)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (feedback == null) ...[
          TextField(
            controller: _answer,
            maxLines: 6,
            minLines: 4,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              labelText: l10n.interviewYourAnswer,
              hintText: l10n.interviewAnswerHint,
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: state.isEvaluating
                ? l10n.interviewEvaluating
                : l10n.interviewSubmit,
            icon: Icons.check_rounded,
            loading: state.isEvaluating,
            onPressed: state.isEvaluating
                ? null
                : () => ref
                    .read(interviewControllerProvider.notifier)
                    .submitAnswer(_answer.text),
          ),
        ] else ...[
          _FeedbackCard(feedback: feedback, l10n: l10n),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: state.isLastQuestion
                ? l10n.interviewFinish
                : l10n.interviewNext,
            icon: state.isLastQuestion
                ? Icons.flag_rounded
                : Icons.arrow_forward_rounded,
            onPressed: () {
              final notifier = ref.read(interviewControllerProvider.notifier);
              if (state.isLastQuestion) {
                notifier.finish();
              } else {
                _answer.clear();
                notifier.nextQuestion();
              }
            },
          ),
        ],
      ],
    );
  }

  // --- Summary (also renders the streaming debrief while summarizing) ---

  Widget _summary(AppLocalizations l10n, InterviewState state) {
    final theme = Theme.of(context);
    final session = state.session;
    final summary = session?.summary;
    final streaming = state.phase == InterviewPhase.summarizing;

    return ListView(
      padding: EdgeInsets.fromLTRB(context.horizontalGutter, AppSpacing.lg,
          context.horizontalGutter, AppSpacing.xxl),
      children: [
        if (!streaming && summary != null) ...[
          Center(child: OverallScoreGauge(score: summary.scores.overall)),
          const SizedBox(height: AppSpacing.md),
          Text(l10n.interviewSummaryTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: AppSpacing.lg),
          _Card(
            child: ScoreBars(rows: interviewScoreBars(l10n, summary.scores)),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        _Section(
          title: l10n.interviewOverallFeedback,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  state.debrief.isEmpty && streaming
                      ? l10n.interviewSummarizing
                      : state.debrief,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                ),
              ),
              if (streaming) ...[
                const SizedBox(width: AppSpacing.sm),
                const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ],
          ),
        ),
        if (!streaming && summary != null) ...[
          if (summary.keyStrengths.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            _Section(
              title: l10n.interviewKeyStrengths,
              child: _Bullets(items: summary.keyStrengths, icon: Icons.check_circle_outline_rounded, color: AppColors.emerald),
            ),
          ],
          if (summary.improvementSuggestions.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            _Section(
              title: l10n.interviewImprovementSuggestions,
              child: _Bullets(items: summary.improvementSuggestions, icon: Icons.trending_up_rounded, color: AppColors.warning),
            ),
          ],
          if (summary.improvementPlan.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            _Section(
              title: l10n.interviewImprovementPlan,
              child: _NumberedPlan(items: summary.improvementPlan),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: l10n.interviewDiscussCoach,
            icon: Icons.psychology_outlined,
            onPressed: () {
              final seed = l10n.interviewCoachSeed(
                interviewTypeName(l10n, session!.type),
                session.role.isEmpty ? l10n.interviewNoRole : session.role,
              );
              context.pushNamed(RouteNames.careerCoach, extra: seed);
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          _OutlinedAction(
            label: l10n.interviewPracticeAgain,
            icon: Icons.refresh_rounded,
            onPressed: () =>
                ref.read(interviewControllerProvider.notifier).reset(),
          ),
        ],
      ],
    );
  }

  // --- Error ---

  Widget _error(AppLocalizations l10n, InterviewState state) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded,
              size: 56, color: theme.colorScheme.error),
          const SizedBox(height: AppSpacing.lg),
          Text(
            interviewFailureMessage(
                l10n, state.failure ?? InterviewFailure.unknown),
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: l10n.interviewRetry,
            icon: Icons.refresh_rounded,
            expanded: false,
            onPressed: () =>
                ref.read(interviewControllerProvider.notifier).retry(),
          ),
        ],
      ),
    );
  }
}

// --- Setup ---

class _Setup extends ConsumerWidget {
  const _Setup({this.job});
  final Job? job;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(interviewControllerProvider);
    final ctx = state.context;
    final role = ctx.role.isEmpty ? l10n.interviewNoRole : ctx.role;

    return ListView(
      padding: EdgeInsets.fromLTRB(context.horizontalGutter, AppSpacing.lg,
          context.horizontalGutter, AppSpacing.xxl),
      children: [
        Text(l10n.interviewSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
        const SizedBox(height: AppSpacing.lg),
        Text(l10n.interviewChooseType,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: AppSpacing.sm),
        for (final type in InterviewType.values) ...[
          _TypeCard(
            title: interviewTypeName(l10n, type),
            desc: interviewTypeDesc(l10n, type),
            selected: state.type == type,
            onTap: () =>
                ref.read(interviewControllerProvider.notifier).selectType(type),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        const SizedBox(height: AppSpacing.md),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.person_search_rounded,
                      size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Text('${l10n.interviewRoleLabel}: ',
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6))),
                  Expanded(
                    child: Text(role,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                job != null
                    ? l10n.interviewForJob
                    : (ctx.hasPersonalization
                        ? l10n.interviewPersonalized
                        : l10n.interviewGenericHint),
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        PrimaryButton(
          label: l10n.interviewStart,
          icon: Icons.play_arrow_rounded,
          onPressed: () =>
              ref.read(interviewControllerProvider.notifier).start(job: job),
        ),
      ],
    );
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.title,
    required this.desc,
    required this.selected,
    required this.onTap,
  });

  final String title;
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
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(desc,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.6))),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: selected
                    ? scheme.primary
                    : scheme.onSurface.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Feedback card (per answer) ---

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({required this.feedback, required this.l10n});

  final AnswerFeedback feedback;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _Card(
      accent: scoreColor(feedback.scores.overall),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              OverallScoreGauge(score: feedback.scores.overall, size: 56),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(l10n.interviewFeedbackTitle,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          if (feedback.feedback.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(feedback.feedback,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.5)),
          ],
          if (feedback.strengths.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(l10n.interviewStrengthsLabel,
                style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.emerald, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            _Bullets(items: feedback.strengths, icon: Icons.check_rounded, color: AppColors.emerald),
          ],
          if (feedback.improvements.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(l10n.interviewImprovementsLabel,
                style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.warning, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            _Bullets(items: feedback.improvements, icon: Icons.arrow_forward_rounded, color: AppColors.warning),
          ],
          if (feedback.sampleAnswer.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(l10n.interviewSampleAnswer,
                style: theme.textTheme.labelLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(feedback.sampleAnswer,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(height: 1.5, fontStyle: FontStyle.italic)),
            ),
          ],
        ],
      ),
    );
  }
}

// --- Small shared building blocks ---

class _Busy extends StatelessWidget {
  const _Busy({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: AppSpacing.md),
          Text(message, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.accent});
  final Widget child;
  final Color? accent;

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
        // Uniform border (a non-uniform border can't have a borderRadius). When
        // an accent is given the whole border is tinted by the score colour.
        border: Border.all(
          color: accent ?? theme.colorScheme.outline.withValues(alpha: 0.5),
          width: accent != null ? 1.5 : 1,
        ),
        boxShadow: AppShadows.card(dark: dark),
      ),
      child: child,
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4)),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}

class _Bullets extends StatelessWidget {
  const _Bullets({required this.items, required this.icon, required this.color});
  final List<String> items;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(icon, size: 16, color: color),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                    child: Text(item,
                        style:
                            theme.textTheme.bodyMedium?.copyWith(height: 1.4))),
              ],
            ),
          ),
      ],
    );
  }
}

class _NumberedPlan extends StatelessWidget {
  const _NumberedPlan({required this.items});
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < items.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Text('${i + 1}',
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                    child: Text(items[i],
                        style:
                            theme.textTheme.bodyMedium?.copyWith(height: 1.5))),
              ],
            ),
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(label,
          style: theme.textTheme.labelSmall
              ?.copyWith(color: theme.colorScheme.primary)),
    );
  }
}

class _OutlinedAction extends StatelessWidget {
  const _OutlinedAction(
      {required this.label, required this.icon, required this.onPressed});
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      ),
    );
  }
}
