import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/services/interview_store/in_memory_interview_history_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/responsive.dart';
import '../domain/interview_models.dart';
import 'interview_l10n.dart';
import 'widgets/score_display.dart';

/// Read-only review of a past interview session: scorecard, debrief, plan, and
/// the full question/answer/feedback transcript.
class InterviewSessionDetailScreen extends ConsumerWidget {
  const InterviewSessionDetailScreen({required this.sessionId, super.key});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final sessions = ref.watch(interviewSessionsProvider).valueOrNull ?? const [];
    final session = sessions.where((s) => s.id == sessionId).firstOrNull;

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.interviewDetailTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Text(l10n.interviewNotFound,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium),
          ),
        ),
      );
    }

    final summary = session.summary;
    final locale = Localizations.localeOf(context).languageCode;
    final date = session.createdAt == null
        ? ''
        : DateFormat.yMMMMd(locale).format(session.createdAt!);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.interviewDetailTitle)),
      body: SafeArea(
        child: ResponsiveCenter(
          child: ListView(
            padding: EdgeInsets.fromLTRB(context.horizontalGutter,
                AppSpacing.lg, context.horizontalGutter, AppSpacing.xxl),
            children: [
              // Header
              Center(
                child: Column(
                  children: [
                    if (summary != null)
                      OverallScoreGauge(score: summary.scores.overall),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      session.role.isEmpty
                          ? interviewTypeName(l10n, session.type)
                          : '${interviewTypeName(l10n, session.type)} · ${session.role}',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    if (date.isNotEmpty)
                      Text(date,
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6))),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (summary != null) ...[
                _card(context,
                    child:
                        ScoreBars(rows: interviewScoreBars(l10n, summary.scores))),
                const SizedBox(height: AppSpacing.lg),
                if (summary.overallFeedback.isNotEmpty)
                  _section(context, l10n.interviewOverallFeedback,
                      Text(summary.overallFeedback,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(height: 1.6))),
                if (summary.keyStrengths.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _section(context, l10n.interviewKeyStrengths,
                      _bullets(context, summary.keyStrengths, AppColors.emerald)),
                ],
                if (summary.improvementSuggestions.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _section(context, l10n.interviewImprovementSuggestions,
                      _bullets(context, summary.improvementSuggestions,
                          AppColors.warning)),
                ],
                if (summary.improvementPlan.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _section(context, l10n.interviewImprovementPlan,
                      _bullets(context, summary.improvementPlan,
                          theme.colorScheme.primary)),
                ],
              ],
              const SizedBox(height: AppSpacing.lg),
              // Transcript
              for (var i = 0; i < session.questions.length; i++)
                _qa(context, l10n, session, session.questions[i], i),
            ],
          ),
        ),
      ),
    );
  }

  Widget _qa(BuildContext context, AppLocalizations l10n,
      InterviewSession session, InterviewQuestion q, int i) {
    final theme = Theme.of(context);
    final answer = session.answerFor(q.id);
    final fb = session.feedbackFor(q.id);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: _card(
        context,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${i + 1}. ${q.text}',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700, height: 1.4)),
            if (answer != null && answer.text.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(answer.text,
                  style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.85))),
            ],
            if (fb != null) ...[
              const Divider(height: AppSpacing.lg),
              Row(
                children: [
                  OverallScoreGauge(score: fb.scores.overall, size: 40),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(fb.feedback,
                        style: theme.textTheme.bodySmall?.copyWith(height: 1.4)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _card(BuildContext context, {required Widget child}) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border:
            Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
        boxShadow: AppShadows.card(dark: dark),
      ),
      child: child,
    );
  }

  Widget _section(BuildContext context, String title, Widget child) {
    final theme = Theme.of(context);
    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }

  Widget _bullets(BuildContext context, List<String> items, Color color) {
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
                  padding: const EdgeInsets.only(top: 5),
                  child: Icon(Icons.circle, size: 6, color: color),
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
