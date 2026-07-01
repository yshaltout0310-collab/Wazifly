import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/primary_button.dart';
import '../application/resume_analyzer_controller.dart';
import '../domain/resume_analysis.dart';
import 'widgets/analysis_section.dart';
import 'widgets/ats_score_gauge.dart';

/// AI Resume Analyzer — upload a PDF, extract its text, analyze with the AI
/// service, and present the structured feedback.
class ResumeAnalyzerScreen extends ConsumerWidget {
  const ResumeAnalyzerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(resumeAnalyzerControllerProvider);
    final controller = ref.read(resumeAnalyzerControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.resumeAnalyzerTitle)),
      body: SafeArea(
        child: ResponsiveCenter(
          maxWidth: 640,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: context.horizontalGutter),
            child: AnimatedSwitcher(
              duration: AppDurations.medium,
              switchInCurve: AppCurves.emphasized,
              child: switch (state.status) {
                ResumeStatus.idle => _UploadView(
                    key: const ValueKey('idle'),
                    onPick: controller.pickAndAnalyze,
                  ),
                ResumeStatus.analyzing => _AnalyzingView(
                    key: const ValueKey('analyzing'),
                    fileName: state.fileName,
                  ),
                ResumeStatus.error => _ErrorView(
                    key: const ValueKey('error'),
                    message: _failureMessage(l10n, state.failure),
                    onRetry: controller.pickAndAnalyze,
                  ),
                ResumeStatus.success => _ResultsView(
                    key: const ValueKey('success'),
                    analysis: state.analysis!,
                    onAnother: controller.pickAndAnalyze,
                  ),
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Upload (idle)
// ---------------------------------------------------------------------------
class _UploadView extends StatelessWidget {
  const _UploadView({required this.onPick, super.key});
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                gradient: AppColors.ctaGradient,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: AppShadows.brandGlow,
              ),
              child: const Icon(Icons.description_outlined,
                  color: AppColors.white, size: 46),
            ).animate().scale(duration: 400.ms, curve: AppCurves.spring),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.resumeUploadTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ).animate(delay: 100.ms).fadeIn().moveY(begin: 10, end: 0),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.resumeAnalyzerIntro,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                height: 1.4,
              ),
            ).animate(delay: 160.ms).fadeIn(),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: l10n.resumeChoosePdf,
              icon: Icons.upload_file_rounded,
              onPressed: onPick,
            ).animate(delay: 220.ms).fadeIn().moveY(begin: 12, end: 0),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.resumeUploadHint,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Analyzing
// ---------------------------------------------------------------------------
class _AnalyzingView extends StatelessWidget {
  const _AnalyzingView({required this.fileName, super.key});
  final String? fileName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 52,
            height: 52,
            child: CircularProgressIndicator(strokeWidth: 4),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.resumeAnalyzing,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.resumeAnalyzingHint,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          if (fileName != null) ...[
            const SizedBox(height: AppSpacing.md),
            _FileChip(fileName: fileName!),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error
// ---------------------------------------------------------------------------
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry, super.key});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded,
                  color: AppColors.error, size: 42),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.4),
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: l10n.resumeRetry,
              icon: Icons.refresh_rounded,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Results
// ---------------------------------------------------------------------------
class _ResultsView extends StatelessWidget {
  const _ResultsView({required this.analysis, required this.onAnother, super.key});

  final ResumeAnalysis analysis;
  final VoidCallback onAnother;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final band = _scoreBand(l10n, analysis.atsScore);

    return ListView(
      padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.xl),
      children: [
        AtsScoreGauge(
          score: analysis.atsScore,
          color: band.color,
          label: band.label,
          caption: l10n.resumeAtsScore,
        ).animate().fadeIn().scaleXY(begin: 0.96, end: 1, curve: AppCurves.spring),
        const SizedBox(height: AppSpacing.lg),

        if (analysis.summary.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.emerald.withValues(alpha: 0.10),
                  AppColors.emerald.withValues(alpha: 0.03),
                ],
              ),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                  color: AppColors.emerald.withValues(alpha: 0.25)),
            ),
            child: Text(
              analysis.summary,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
            ),
          ).animate(delay: 80.ms).fadeIn().moveY(begin: 10, end: 0),
          const SizedBox(height: AppSpacing.md),
        ],

        if (analysis.strengths.isNotEmpty)
          AnalysisSection(
            title: l10n.resumeSectionStrengths,
            icon: Icons.check_circle_outline_rounded,
            accent: AppColors.emerald,
            count: analysis.strengths.length,
            child: BulletItems(
              items: analysis.strengths,
              accent: AppColors.emerald,
              icon: Icons.check_rounded,
            ),
          ),

        if (analysis.weaknesses.isNotEmpty)
          AnalysisSection(
            title: l10n.resumeSectionWeaknesses,
            icon: Icons.report_gmailerrorred_rounded,
            accent: AppColors.warning,
            count: analysis.weaknesses.length,
            child: BulletItems(
              items: analysis.weaknesses,
              accent: AppColors.warning,
              icon: Icons.remove_rounded,
            ),
          ),

        if (analysis.missingSkills.isNotEmpty)
          AnalysisSection(
            title: l10n.resumeSectionMissingSkills,
            icon: Icons.workspace_premium_outlined,
            accent: AppColors.teal,
            count: analysis.missingSkills.length,
            child: _SkillChips(skills: analysis.missingSkills),
          ),

        if (analysis.grammarIssues.isNotEmpty)
          AnalysisSection(
            title: l10n.resumeSectionGrammar,
            icon: Icons.spellcheck_rounded,
            accent: AppColors.error,
            count: analysis.grammarIssues.length,
            child: GrammarIssueList(
              issues: analysis.grammarIssues,
              accent: AppColors.emeraldDark,
              suggestionLabel: l10n.resumeGrammarFix,
            ),
          ),

        if (analysis.improvementSuggestions.isNotEmpty)
          AnalysisSection(
            title: l10n.resumeSectionSuggestions,
            icon: Icons.lightbulb_outline_rounded,
            accent: AppColors.emerald,
            count: analysis.improvementSuggestions.length,
            child: BulletItems(
              items: analysis.improvementSuggestions,
              accent: AppColors.emerald,
              icon: Icons.arrow_forward_rounded,
            ),
          ),

        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: onAnother,
          icon: const Icon(Icons.upload_file_rounded),
          label: Text(l10n.resumeAnalyzeAnother),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          ),
        ),
      ],
    );
  }
}

/// Missing skills rendered as wrap-around chips.
class _SkillChips extends StatelessWidget {
  const _SkillChips({required this.skills});
  final List<String> skills;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final skill in skills)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.teal.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: AppColors.teal.withValues(alpha: 0.30)),
            ),
            child: Text(
              skill,
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppColors.emeraldDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

class _FileChip extends StatelessWidget {
  const _FileChip({required this.fileName});
  final String fileName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.picture_as_pdf_rounded,
              size: 16, color: AppColors.error),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
({Color color, String label}) _scoreBand(AppLocalizations l10n, int score) {
  if (score >= 80) {
    return (color: AppColors.emerald, label: l10n.resumeScoreExcellent);
  }
  if (score >= 65) {
    return (color: AppColors.teal, label: l10n.resumeScoreGood);
  }
  if (score >= 45) {
    return (color: AppColors.warning, label: l10n.resumeScoreFair);
  }
  return (color: AppColors.error, label: l10n.resumeScoreNeedsWork);
}

String _failureMessage(AppLocalizations l10n, ResumeFailure? failure) {
  return switch (failure) {
    ResumeFailure.noText => l10n.resumeErrNoText,
    ResumeFailure.extractionFailed => l10n.resumeErrExtraction,
    ResumeFailure.tooLarge => l10n.resumeErrTooLarge,
    ResumeFailure.notConfigured => l10n.resumeErrNotConfigured,
    ResumeFailure.network => l10n.resumeErrNetwork,
    ResumeFailure.quota => l10n.resumeErrQuota,
    ResumeFailure.invalidResponse => l10n.resumeErrInvalid,
    ResumeFailure.blocked => l10n.resumeErrBlocked,
    ResumeFailure.unknown || null => l10n.resumeErrUnknown,
  };
}
