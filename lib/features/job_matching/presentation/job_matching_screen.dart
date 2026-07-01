import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/primary_button.dart';
import '../application/job_matching_controller.dart';
import '../domain/job_match.dart';
import 'widgets/job_match_card.dart';

/// AI Job Matching — ranks bundled jobs against the user's analyzed resume.
/// Reuses a cached resume analysis when available; otherwise prompts the user to
/// upload one, analyzes it, and matches automatically.
class JobMatchingScreen extends ConsumerWidget {
  const JobMatchingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(jobMatchingControllerProvider);
    final controller = ref.read(jobMatchingControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.jobMatchTitle),
        actions: [
          if (state.status == JobMatchStatus.success)
            IconButton(
              tooltip: l10n.jobMatchUseAnother,
              onPressed: controller.useAnotherResume,
              icon: const Icon(Icons.file_upload_outlined),
            ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveCenter(
          maxWidth: 640,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: context.horizontalGutter),
            child: AnimatedSwitcher(
              duration: AppDurations.medium,
              switchInCurve: AppCurves.emphasized,
              child: switch (state.status) {
                JobMatchStatus.needsResume => _NeedsResumeView(
                    key: const ValueKey('needsResume'),
                    onUpload: controller.pickAnalyzeAndMatch,
                  ),
                JobMatchStatus.analyzingResume => _LoadingView(
                    key: const ValueKey('analyzingResume'),
                    title: l10n.jobMatchAnalyzingResume,
                    hint: l10n.jobMatchAnalyzingResumeHint,
                  ),
                JobMatchStatus.matching => _LoadingView(
                    key: const ValueKey('matching'),
                    title: l10n.jobMatchMatching,
                    hint: l10n.jobMatchMatchingHint,
                  ),
                JobMatchStatus.error => _ErrorView(
                    key: const ValueKey('error'),
                    message: _failureMessage(l10n, state.failure),
                    onRetry: controller.retry,
                  ),
                JobMatchStatus.success => _ResultsView(
                    key: const ValueKey('success'),
                    matches: state.matches,
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
// Needs resume (upload prompt)
// ---------------------------------------------------------------------------
class _NeedsResumeView extends StatelessWidget {
  const _NeedsResumeView({required this.onUpload, super.key});
  final VoidCallback onUpload;

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
              child: const Icon(Icons.bolt_outlined,
                  color: AppColors.white, size: 46),
            ).animate().scale(duration: 400.ms, curve: AppCurves.spring),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.jobMatchNeedsResumeTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ).animate(delay: 100.ms).fadeIn().moveY(begin: 10, end: 0),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.jobMatchNeedsResumeBody,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                height: 1.4,
              ),
            ).animate(delay: 160.ms).fadeIn(),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: l10n.jobMatchUploadResume,
              icon: Icons.upload_file_rounded,
              onPressed: onUpload,
            ).animate(delay: 220.ms).fadeIn().moveY(begin: 12, end: 0),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Loading (matching / analyzing resume)
// ---------------------------------------------------------------------------
class _LoadingView extends StatelessWidget {
  const _LoadingView({required this.title, required this.hint, super.key});
  final String title;
  final String hint;

  @override
  Widget build(BuildContext context) {
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
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            hint,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
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
              label: l10n.jobMatchRetry,
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
// Results (ranked list)
// ---------------------------------------------------------------------------
class _ResultsView extends StatelessWidget {
  const _ResultsView({required this.matches, super.key});
  final List<JobMatch> matches;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return ListView.builder(
      padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.xl),
      itemCount: matches.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Text(
              l10n.jobMatchResultsHeader(matches.length),
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
          );
        }
        final match = matches[i - 1];
        return JobMatchCard(match: match)
            .animate(delay: (40 * i).ms)
            .fadeIn()
            .moveY(begin: 12, end: 0);
      },
    );
  }
}

String _failureMessage(AppLocalizations l10n, JobMatchFailure? failure) {
  return switch (failure) {
    JobMatchFailure.noJobs => l10n.jobMatchErrNoJobs,
    JobMatchFailure.notConfigured => l10n.jobMatchErrNotConfigured,
    JobMatchFailure.network => l10n.jobMatchErrNetwork,
    JobMatchFailure.quota => l10n.jobMatchErrQuota,
    JobMatchFailure.invalidResponse => l10n.jobMatchErrInvalid,
    JobMatchFailure.blocked => l10n.jobMatchErrBlocked,
    JobMatchFailure.resumeNoText => l10n.resumeErrNoText,
    JobMatchFailure.resumeExtraction => l10n.resumeErrExtraction,
    JobMatchFailure.unknown || null => l10n.jobMatchErrUnknown,
  };
}
