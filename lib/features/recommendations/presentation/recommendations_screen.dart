import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/navigation/route_names.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../auth/presentation/widgets/auth_error.dart';
import '../application/recommendations_controller.dart';
import '../domain/recommendation_models.dart';
import 'recommendations_l10n.dart';
import 'widgets/recommendation_sections.dart';

/// The personalized "For You" hub: one holistic AI pass over the user's profile,
/// resume, CV, applications, and interview history → recommended jobs, skills,
/// certifications, courses, a career roadmap, and next best actions.
class RecommendationsScreen extends ConsumerWidget {
  const RecommendationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(recommendationsControllerProvider);

    // Transient hints: "up to date" after a no-op refresh, and non-fatal
    // failures that happen while existing content stays on screen.
    ref.listen(recommendationsControllerProvider.select((s) => s.upToDate),
        (prev, next) {
      if (next) {
        showAuthSnack(context, l10n.recUpToDate);
        ref.read(recommendationsControllerProvider.notifier).clearUpToDate();
      }
    });
    ref.listen(recommendationsControllerProvider.select((s) => s.failure),
        (prev, next) {
      if (next != null &&
          ref.read(recommendationsControllerProvider).recommendations != null) {
        showAuthSnack(context, recFailureMessage(l10n, next), isError: true);
        ref.read(recommendationsControllerProvider.notifier).clearFailure();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.recTitle),
        actions: [
          if (state.phase == RecommendationsPhase.ready)
            IconButton(
              tooltip: l10n.recRefresh,
              icon: const Icon(Icons.refresh_rounded),
              onPressed: state.isRefreshing
                  ? null
                  : () =>
                      ref.read(recommendationsControllerProvider.notifier).refresh(),
            ),
        ],
        bottom: state.isRefreshing
            ? const PreferredSize(
                preferredSize: Size.fromHeight(3),
                child: LinearProgressIndicator(minHeight: 3),
              )
            : null,
      ),
      body: SafeArea(
        child: ResponsiveCenter(
          child: AnimatedSwitcher(
            duration: AppDurations.medium,
            child: KeyedSubtree(
              key: ValueKey(state.phase),
              child: switch (state.phase) {
                RecommendationsPhase.loading => _Busy(message: l10n.recLoading),
                RecommendationsPhase.error => _Error(
                    message: recFailureMessage(
                        l10n, state.failure ?? RecommendationFailure.unknown),
                    onRetry: () => ref
                        .read(recommendationsControllerProvider.notifier)
                        .retry(),
                  ),
                RecommendationsPhase.ready => _Ready(state: state),
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _Ready extends ConsumerWidget {
  const _Ready({required this.state});
  final RecommendationsState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final recs = state.recommendations;
    if (recs == null) return const SizedBox.shrink();

    return ListView(
      padding: EdgeInsets.fromLTRB(context.horizontalGutter, AppSpacing.lg,
          context.horizontalGutter, AppSpacing.xxl),
      children: [
        _HeaderCard(recs: recs, personalized: state.personalized),
        if (recs.recommendedJobs.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          RecSection(
            icon: Icons.work_outline_rounded,
            title: l10n.recJobsTitle,
            child: Column(
              children: [
                for (final j in recs.recommendedJobs) ...[
                  RecJobCard(
                    job: j,
                    onTap: () => context.pushNamed(
                      RouteNames.jobDetail,
                      pathParameters: {'id': j.jobId},
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ],
            ),
          ),
        ],
        if (recs.skillsToLearn.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          RecSection(
            icon: Icons.trending_up_rounded,
            title: l10n.recSkillsTitle,
            child: Column(
              children: [
                for (final s in recs.skillsToLearn) ...[
                  RecSkillTile(skill: s),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ],
            ),
          ),
        ],
        if (recs.certifications.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          RecSection(
            icon: Icons.verified_outlined,
            title: l10n.recCertsTitle,
            child: Column(
              children: [
                for (final c in recs.certifications) ...[
                  RecCertTile(cert: c),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ],
            ),
          ),
        ],
        if (recs.courses.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          RecSection(
            icon: Icons.school_outlined,
            title: l10n.recCoursesTitle,
            child: Column(
              children: [
                for (final c in recs.courses) ...[
                  RecCourseTile(course: c),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ],
            ),
          ),
        ],
        if (recs.careerRoadmap.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          RecSection(
            icon: Icons.route_rounded,
            title: l10n.recRoadmapTitle,
            child: RecCard(child: RecRoadmap(steps: recs.careerRoadmap)),
          ),
        ],
        if (recs.nextBestActions.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          RecSection(
            icon: Icons.checklist_rounded,
            title: l10n.recActionsTitle,
            child: Column(
              children: [
                for (final a in recs.nextBestActions) ...[
                  RecActionCard(
                    action: a,
                    onTap: _actionTap(context, a),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// Maps a next-best-action to an in-app destination (navigation only — no
  /// dependency on the target features). `null` → the card isn't tappable.
  VoidCallback? _actionTap(BuildContext context, NextAction a) {
    switch (a.type) {
      case NextActionType.analyzeResume:
        return () => context.pushNamed(RouteNames.resumeAnalyzer);
      case NextActionType.buildCv:
        return () => context.pushNamed(RouteNames.cvBuilder);
      case NextActionType.practiceInterview:
        return () => context.pushNamed(RouteNames.interviewPrep);
      case NextActionType.browseJobs:
        return () => context.pushNamed(RouteNames.jobs);
      case NextActionType.reviewApplications:
        return () => context.pushNamed(RouteNames.applications);
      case NextActionType.completeProfile:
        return () => context.pushNamed(RouteNames.editProfile);
      case NextActionType.applyToJob:
        return a.targetId.isEmpty
            ? () => context.pushNamed(RouteNames.jobs)
            : () => context.pushNamed(RouteNames.jobDetail,
                pathParameters: {'id': a.targetId});
      case NextActionType.learnSkill:
      case NextActionType.none:
        return null;
    }
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.recs, required this.personalized});
  final Recommendations recs;
  final bool personalized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final updated = recs.generatedAt == null
        ? null
        : DateFormat.yMMMd(locale).add_jm().format(recs.generatedAt!);

    return RecCard(
      accent: theme.colorScheme.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            recs.headline.isEmpty ? l10n.recTitle : recs.headline,
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          if (recs.summary.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(recs.summary,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.5)),
          ] else ...[
            const SizedBox(height: AppSpacing.sm),
            Text(l10n.recSubtitle,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.5)),
          ],
          if (!personalized) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.tips_and_updates_outlined,
                    size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(l10n.recNudge,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.7))),
                ),
              ],
            ),
          ],
          if (updated != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(l10n.recUpdated(updated),
                style: theme.textTheme.labelSmall?.copyWith(
                    color:
                        theme.colorScheme.onSurface.withValues(alpha: 0.5))),
          ],
        ],
      ),
    );
  }
}

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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Text(message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium),
          ),
        ],
      ),
    );
  }
}

class _Error extends StatelessWidget {
  const _Error({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded,
              size: 56, color: theme.colorScheme.error),
          const SizedBox(height: AppSpacing.lg),
          Text(message,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: l10n.recRetry,
            icon: Icons.refresh_rounded,
            expanded: false,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}
