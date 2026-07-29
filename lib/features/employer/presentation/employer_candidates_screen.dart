import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/status_view.dart';
import '../application/candidate_match_controller.dart';
import '../domain/candidate_match.dart';
import 'widgets/match_score_badge.dart';

/// Employer AI tool: ranks the applicant pool against a target role and shows
/// top candidate recommendations (match score, matching skills, experience
/// summary, and an AI recommendation). Reuses the shared `AiService` seam.
class EmployerCandidatesScreen extends ConsumerStatefulWidget {
  const EmployerCandidatesScreen({super.key});

  @override
  ConsumerState<EmployerCandidatesScreen> createState() =>
      _EmployerCandidatesScreenState();
}

class _EmployerCandidatesScreenState
    extends ConsumerState<EmployerCandidatesScreen> {
  final _role = TextEditingController();
  bool _roleError = false;

  @override
  void dispose() {
    _role.dispose();
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
    ref.read(candidateMatchControllerProvider.notifier).generate(role);
  }

  String _failureText(AppLocalizations l10n, CandidateMatchFailure f) =>
      switch (f) {
        CandidateMatchFailure.notConfigured =>
          l10n.employerCandidatesErrNotConfigured,
        CandidateMatchFailure.network => l10n.employerCandidatesErrNetwork,
        CandidateMatchFailure.quota => l10n.employerCandidatesErrQuota,
        CandidateMatchFailure.empty => l10n.employerCandidatesErrEmpty,
        CandidateMatchFailure.invalidResponse ||
        CandidateMatchFailure.unknown =>
          l10n.employerCandidatesErrGeneric,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pool = ref.watch(employerCandidatePoolProvider);
    final state = ref.watch(candidateMatchControllerProvider);

    // No applicants at all → a single honest empty state (nothing to rank yet).
    if (pool.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.employerCandidatesTitle)),
        body: SafeArea(
          child: StatusView.empty(
            icon: Icons.groups_outlined,
            title: l10n.employerCandidatesEmptyTitle,
            message: l10n.employerCandidatesEmptyBody,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.employerCandidatesTitle)),
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
                  roleError: _roleError,
                  loading: state.isLoading,
                  hasResult: state.shortlist != null,
                  poolCount: pool.length,
                  onGenerate: _generate,
                ),
              ),
              Expanded(
                child: switch (state.phase) {
                  CandidateMatchPhase.loading =>
                    StatusView.loading(title: l10n.employerCandidatesLoading),
                  CandidateMatchPhase.error => StatusView.error(
                      message: _failureText(l10n, state.failure!),
                      onRetry: _generate,
                    ),
                  CandidateMatchPhase.ready when state.shortlist != null =>
                    _Results(shortlist: state.shortlist!),
                  _ => StatusView.empty(
                      icon: Icons.groups_2_outlined,
                      title: l10n.employerCandidatesStartTitle,
                      message: l10n.employerCandidatesStartBody,
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
    required this.roleError,
    required this.loading,
    required this.hasResult,
    required this.poolCount,
    required this.onGenerate,
  });

  final TextEditingController role;
  final bool roleError;
  final bool loading;
  final bool hasResult;
  final int poolCount;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.employerCandidatesPoolCount(poolCount),
          style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.65)),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: role,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => loading ? null : onGenerate(),
          decoration: InputDecoration(
            labelText: l10n.employerCandidatesRoleLabel,
            hintText: l10n.employerCandidatesRoleHint,
            prefixIcon: const Icon(Icons.work_outline_rounded),
            errorText: roleError ? l10n.employerCandidatesRoleRequired : null,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        PrimaryButton(
          label: hasResult
              ? l10n.employerCandidatesRegenerate
              : l10n.employerCandidatesGenerate,
          icon: Icons.auto_awesome_rounded,
          loading: loading,
          onPressed: loading ? null : onGenerate,
        ),
      ],
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({required this.shortlist});
  final CandidateShortlist shortlist;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return ListView(
      padding: EdgeInsets.fromLTRB(context.horizontalGutter, AppSpacing.md,
          context.horizontalGutter, AppSpacing.xxl),
      children: [
        if (shortlist.summary.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Row(
              children: [
                Icon(Icons.insights_rounded, color: theme.colorScheme.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(shortlist.summary,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.35)),
                ),
              ],
            ),
          ).animate().fadeIn().moveY(begin: 10, end: 0),
          const SizedBox(height: AppSpacing.lg),
        ],
        Text(l10n.employerCandidatesResultsTitle,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: AppSpacing.sm),
        for (var i = 0; i < shortlist.candidates.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _CandidateCard(rank: i + 1, match: shortlist.candidates[i])
                .animate(delay: (70 * i).ms)
                .fadeIn()
                .moveY(begin: 10, end: 0),
          ),
      ],
    );
  }
}

class _CandidateCard extends StatelessWidget {
  const _CandidateCard({required this.rank, required this.match});
  final int rank;
  final CandidateMatch match;

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
                radius: 18,
                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                child: Text(
                  match.name.isNotEmpty ? match.name.characters.first.toUpperCase() : '?',
                  style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(match.name,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    if (match.headline.isNotEmpty)
                      Text(match.headline,
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.65))),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              MatchScoreBadge(score: match.matchScore),
            ],
          ),
          if (match.matchingSkills.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _Label(l10n.employerCandidatesMatchingSkills),
            const SizedBox(height: 6),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: 6,
              children: [
                for (final s in match.matchingSkills)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.teal.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(s,
                        style: theme.textTheme.labelMedium?.copyWith(
                            color: AppColors.teal, fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
          ],
          if (match.experienceSummary.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _Label(l10n.employerCandidatesExperience),
            const SizedBox(height: 2),
            Text(match.experienceSummary,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.35)),
          ],
          if (match.recommendation.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
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
                  Row(
                    children: [
                      Icon(Icons.auto_awesome_rounded,
                          size: 15, color: theme.colorScheme.primary),
                      const SizedBox(width: 6),
                      Text(l10n.employerCandidatesRecommendation,
                          style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(match.recommendation,
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

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(text,
        style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4));
  }
}
