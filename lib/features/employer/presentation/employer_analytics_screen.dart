import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/navigation/route_names.dart';
import '../../../core/services/applications/employer_applicants_repository.dart';
import '../../../core/services/jobs/employer_jobs_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../auth/presentation/widgets/auth_error.dart';
import '../application/employer_analytics_providers.dart';
import '../application/recruiter_insights_controller.dart';
import '../domain/analytics/employer_analytics.dart';
import '../domain/analytics/recruiter_insights.dart';
import 'analytics_l10n.dart';
import 'widgets/analytics_widgets.dart';
import 'widgets/job_status_chip.dart';

/// A read-only hiring analytics dashboard for the employer: KPI overview, an
/// application status funnel, top jobs, time-to-hire, applicant-quality
/// distribution, an applications trend, and an on-demand AI "Recruiter Insights"
/// card. Everything is computed from the employer's own jobs/applicants/activity
/// streams (zero feature-to-feature deps).
class EmployerAnalyticsScreen extends ConsumerWidget {
  const EmployerAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final analytics = ref.watch(employerAnalyticsProvider);

    // Surface transient insights hints (up-to-date / failed refresh) as snackbars.
    ref.listen(recruiterInsightsControllerProvider.select((s) => s.upToDate),
        (prev, next) {
      if (next) {
        showAuthSnack(context, l10n.insightsUpToDate);
        ref.read(recruiterInsightsControllerProvider.notifier).clearUpToDate();
      }
    });
    ref.listen(recruiterInsightsControllerProvider.select((s) => s.failure),
        (prev, next) {
      if (next != null &&
          ref.read(recruiterInsightsControllerProvider).insights != null) {
        showAuthSnack(context, insightsFailureMessage(l10n, next),
            isError: true);
        ref.read(recruiterInsightsControllerProvider.notifier).clearFailure();
      }
    });

    // Distinguish "still loading the streams" from "genuinely empty".
    final jobsAsync = ref.watch(employerJobsProvider);
    final appsAsync = ref.watch(employerApplicantsProvider);
    final loading = (jobsAsync.isLoading && !jobsAsync.hasValue) ||
        (appsAsync.isLoading && !appsAsync.hasValue);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.analyticsTitle)),
      body: SafeArea(
        child: ResponsiveCenter(
          maxWidth: 760,
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : (!analytics.hasApplicants && !analytics.hasJobs)
                  ? _Empty(l10n: l10n)
                  : _Dashboard(analytics: analytics),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.insights_rounded,
              size: 64, color: theme.colorScheme.primary.withValues(alpha: 0.7)),
          const SizedBox(height: AppSpacing.lg),
          Text(l10n.analyticsEmptyTitle,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: AppSpacing.sm),
          Text(l10n.analyticsEmptyBody,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: l10n.analyticsPostJob,
            icon: Icons.post_add_rounded,
            expanded: false,
            onPressed: () => context.pushNamed(RouteNames.createJob),
          ),
        ],
      ),
    );
  }
}

class _Dashboard extends StatelessWidget {
  const _Dashboard({required this.analytics});
  final EmployerAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: EdgeInsets.fromLTRB(context.horizontalGutter, AppSpacing.lg,
          context.horizontalGutter, AppSpacing.xxl),
      children: [
        _Overview(analytics: analytics),
        const SizedBox(height: AppSpacing.xl),
        const _InsightsCard(),
        const SizedBox(height: AppSpacing.xl),
        _FunnelSection(analytics: analytics),
        const SizedBox(height: AppSpacing.xl),
        _TopJobsSection(analytics: analytics),
        const SizedBox(height: AppSpacing.xl),
        _TimeToHireSection(analytics: analytics),
        const SizedBox(height: AppSpacing.xl),
        _QualitySection(analytics: analytics),
        const SizedBox(height: AppSpacing.xl),
        _TrendSection(analytics: analytics),
        const SizedBox(height: AppSpacing.lg),
        Text(l10n.analyticsMetricsNote,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5))),
      ],
    );
  }
}

// --- Overview ---

class _Overview extends StatelessWidget {
  const _Overview({required this.analytics});
  final EmployerAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final o = analytics.overview;
    final tiles = <({IconData icon, String label, String value})>[
      (icon: Icons.work_outline_rounded, label: l10n.analyticsKpiActiveJobs, value: '${o.activeJobs}'),
      (icon: Icons.people_alt_outlined, label: l10n.analyticsKpiApplicants, value: '${o.totalApplicants}'),
      (icon: Icons.event_available_outlined, label: l10n.analyticsKpiInterviews, value: '${o.interviews}'),
      (icon: Icons.emoji_events_outlined, label: l10n.analyticsKpiHires, value: '${o.hires}'),
      (icon: Icons.percent_rounded, label: l10n.analyticsKpiHireRate, value: '${(o.hireRate * 100).round()}%'),
      (icon: Icons.auto_awesome_outlined, label: l10n.analyticsKpiAvgMatch, value: o.avgMatchScore > 0 ? '${o.avgMatchScore}' : '—'),
    ];
    return AnalyticsSection(
      icon: Icons.dashboard_outlined,
      title: l10n.analyticsOverviewTitle,
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.sm,
        childAspectRatio: 0.86,
        children: [
          for (final t in tiles)
            KpiTile(icon: t.icon, label: t.label, value: t.value),
        ],
      ),
    );
  }
}

// --- Funnel ---

class _FunnelSection extends StatelessWidget {
  const _FunnelSection({required this.analytics});
  final EmployerAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final f = analytics.funnel;
    if (f.isEmpty) {
      return AnalyticsSection(
        icon: Icons.filter_alt_outlined,
        title: l10n.analyticsFunnelTitle,
        child: AnalyticsCard(child: _MutedText(l10n.analyticsNoJobData)),
      );
    }
    String share(double s) => l10n.analyticsShareOfApplicants((s * 100).round());
    final bars = [
      AnalyticsBar(
          label: l10n.analyticsFunnelApplied,
          count: f.applied,
          fraction: 1,
          color: theme.colorScheme.primary,
          trailing: '100%'),
      AnalyticsBar(
          label: l10n.analyticsFunnelReviewed,
          count: f.reviewed,
          fraction: f.reviewedShare,
          color: AppColors.teal,
          trailing: share(f.reviewedShare)),
      AnalyticsBar(
          label: l10n.analyticsFunnelInterview,
          count: f.interview,
          fraction: f.interviewShare,
          color: AppColors.warning,
          trailing: share(f.interviewShare)),
      AnalyticsBar(
          label: l10n.analyticsFunnelHired,
          count: f.accepted,
          fraction: f.acceptedShare,
          color: AppColors.emerald,
          trailing: share(f.acceptedShare)),
    ];
    return AnalyticsSection(
      icon: Icons.filter_alt_outlined,
      title: l10n.analyticsFunnelTitle,
      child: AnalyticsCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HorizontalBars(bars: bars),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Icon(Icons.block_flipped,
                    size: 15,
                    color: theme.colorScheme.error.withValues(alpha: 0.8)),
                const SizedBox(width: 6),
                Text(l10n.analyticsRejectedCount(f.rejected),
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.6))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// --- Top jobs ---

class _TopJobsSection extends StatelessWidget {
  const _TopJobsSection({required this.analytics});
  final EmployerAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final top =
        analytics.jobPerformance.where((j) => j.applicants > 0).take(5).toList();
    return AnalyticsSection(
      icon: Icons.leaderboard_outlined,
      title: l10n.analyticsTopJobsTitle,
      child: top.isEmpty
          ? AnalyticsCard(child: _MutedText(l10n.analyticsNoJobData))
          : Column(
              children: [
                for (final j in top) ...[
                  _JobRow(job: j),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ],
            ),
    );
  }
}

class _JobRow extends StatelessWidget {
  const _JobRow({required this.job});
  final JobPerformance job;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: job.jobId.isEmpty
          ? null
          : () => context.pushNamed(RouteNames.employerJobApplicants,
              pathParameters: {'id': job.jobId}),
      child: AnalyticsCard(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(job.jobTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (job.status != null) ...[
                        JobStatusChip(status: job.status!, dense: true),
                        const SizedBox(width: AppSpacing.sm),
                      ],
                      Flexible(
                        child: Text(
                          l10n.analyticsJobApplicants(job.applicants),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(l10n.analyticsPercentHired((job.conversion * 100).round()),
                    style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.primary)),
                const SizedBox(height: 2),
                Icon(Icons.arrow_forward_rounded,
                    size: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// --- Time to hire ---

class _TimeToHireSection extends StatelessWidget {
  const _TimeToHireSection({required this.analytics});
  final EmployerAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = analytics.timeToHire;
    return AnalyticsSection(
      icon: Icons.timer_outlined,
      title: l10n.analyticsTimeToHireTitle,
      child: AnalyticsCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (t.hasHires)
              Row(
                children: [
                  Expanded(
                    child: _Metric(
                        label: l10n.analyticsAvgTimeToHire,
                        value: l10n.analyticsDays(t.avgDaysToHire.round())),
                  ),
                  Expanded(
                    child: _Metric(
                        label: l10n.analyticsMedianTimeToHire,
                        value: l10n.analyticsDays(t.medianDaysToHire.round())),
                  ),
                  Expanded(
                    child: _Metric(
                        label: l10n.analyticsFastestHire,
                        value: l10n
                            .analyticsDays((t.fastestDaysToHire ?? 0).round())),
                  ),
                ],
              )
            else
              _MutedText(l10n.analyticsNoHiresYet),
            if (t.hasOpen) ...[
              const Divider(height: AppSpacing.xl),
              _Metric(
                label: l10n.analyticsAvgInPipeline,
                value: l10n.analyticsDays(t.avgDaysInPipeline.round()),
                sub: l10n.analyticsOpenCount(t.openApplicants),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// --- Applicant quality ---

class _QualitySection extends StatelessWidget {
  const _QualitySection({required this.analytics});
  final EmployerAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final q = analytics.quality;
    return AnalyticsSection(
      icon: Icons.workspace_premium_outlined,
      title: l10n.analyticsQualityTitle,
      child: AnalyticsCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (q.hasMatchData) ...[
              Text(l10n.analyticsMatchDistribution,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: AppSpacing.md),
              HorizontalBars(
                bars: [
                  for (final b in q.bands)
                    AnalyticsBar(
                      label: matchBandLabel(l10n, b.band),
                      count: b.count,
                      fraction:
                          q.withMatchCount == 0 ? 0 : b.count / q.withMatchCount,
                      color: _bandColor(b.band),
                    ),
                ],
              ),
            ] else
              _MutedText(l10n.analyticsNoQualityData),
            if (q.hasResumeData) ...[
              const Divider(height: AppSpacing.xl),
              _Metric(
                  label: l10n.analyticsAvgAts, value: '${q.avgAtsScore}/100'),
            ],
            if (q.hasSkills) ...[
              const SizedBox(height: AppSpacing.lg),
              Text(l10n.analyticsTopSkillsTitle,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final s in q.topSkills)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text('${s.skill} · ${s.count}',
                          style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  static Color _bandColor(MatchBand band) => switch (band) {
        MatchBand.strong => AppColors.emerald,
        MatchBand.good => AppColors.teal,
        MatchBand.fair => AppColors.warning,
        MatchBand.weak => AppColors.error,
      };
}

// --- Trend ---

class _TrendSection extends StatelessWidget {
  const _TrendSection({required this.analytics});
  final EmployerAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final t = analytics.trend;
    final df = DateFormat.Md(locale);
    return AnalyticsSection(
      icon: Icons.show_chart_rounded,
      title: l10n.analyticsTrendTitle,
      child: AnalyticsCard(
        child: t.hasActivity
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MiniBarChart(
                    values: [for (final p in t.points) p.count],
                    labels: [for (final p in t.points) df.format(p.weekStart)],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(l10n.analyticsTrendLast7(t.applicationsLast7Days),
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6))),
                ],
              )
            : _MutedText(l10n.analyticsNoTrendData),
      ),
    );
  }
}

// --- AI Recruiter Insights card ---

class _InsightsCard extends ConsumerWidget {
  const _InsightsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(recruiterInsightsControllerProvider);
    final notifier = ref.read(recruiterInsightsControllerProvider.notifier);
    final analytics = ref.watch(employerAnalyticsProvider);

    return AnalyticsCard(
      accent: theme.colorScheme.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded,
                  size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(l10n.insightsTitle,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800)),
              ),
              if (state.phase == RecruiterInsightsPhase.ready)
                IconButton(
                  tooltip: l10n.insightsRefresh,
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed:
                      state.isRefreshing ? null : () => notifier.refresh(),
                ),
            ],
          ),
          if (state.isRefreshing) ...[
            const SizedBox(height: AppSpacing.sm),
            const LinearProgressIndicator(minHeight: 3),
          ],
          const SizedBox(height: AppSpacing.sm),
          _InsightsBody(
            state: state,
            analytics: analytics,
            notifier: notifier,
          ),
        ],
      ),
    );
  }
}

class _InsightsBody extends StatelessWidget {
  const _InsightsBody({
    required this.state,
    required this.analytics,
    required this.notifier,
  });

  final RecruiterInsightsState state;
  final EmployerAnalytics analytics;
  final RecruiterInsightsController notifier;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (state.insights != null) {
      return _InsightsContent(insights: state.insights!);
    }

    switch (state.phase) {
      case RecruiterInsightsPhase.loading:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Row(
            children: [
              const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2)),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(l10n.insightsLoading)),
            ],
          ),
        );
      case RecruiterInsightsPhase.error:
        return _InsightsError(
          message: insightsFailureMessage(
              l10n, state.failure ?? RecruiterInsightsFailure.unknown),
          onRetry: () => notifier.generate(),
        );
      case RecruiterInsightsPhase.idle:
      case RecruiterInsightsPhase.ready:
        return _InsightsCta(canGenerate: analytics.hasApplicants, notifier: notifier);
    }
  }
}

class _InsightsCta extends StatelessWidget {
  const _InsightsCta({required this.canGenerate, required this.notifier});
  final bool canGenerate;
  final RecruiterInsightsController notifier;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(canGenerate ? l10n.insightsSubtitle : l10n.insightsUnavailable,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.4)),
        if (canGenerate) ...[
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(
            label: l10n.insightsGenerate,
            icon: Icons.auto_awesome_rounded,
            expanded: false,
            onPressed: () => notifier.generate(),
          ),
        ],
      ],
    );
  }
}

class _InsightsError extends StatelessWidget {
  const _InsightsError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.error_outline_rounded,
                size: 18, color: theme.colorScheme.error),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(message)),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        PrimaryButton(
          label: l10n.insightsRetry,
          icon: Icons.refresh_rounded,
          expanded: false,
          onPressed: onRetry,
        ),
      ],
    );
  }
}

class _InsightsContent extends StatelessWidget {
  const _InsightsContent({required this.insights});
  final RecruiterInsights insights;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final updated = insights.generatedAt == null
        ? null
        : DateFormat.yMMMd(locale).add_jm().format(insights.generatedAt!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (insights.headline.isNotEmpty)
          Text(insights.headline,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
        if (insights.summary.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(insights.summary,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5)),
        ],
        if (insights.strengths.isNotEmpty)
          _InsightGroup(
            icon: Icons.check_circle_outline_rounded,
            color: AppColors.emerald,
            title: l10n.insightsStrengthsTitle,
            items: [
              for (final s in insights.strengths)
                (title: s.title, detail: s.detail, priority: null),
            ],
          ),
        if (insights.bottlenecks.isNotEmpty)
          _InsightGroup(
            icon: Icons.warning_amber_rounded,
            color: AppColors.warning,
            title: l10n.insightsBottlenecksTitle,
            items: [
              for (final b in insights.bottlenecks)
                (title: b.title, detail: b.detail, priority: null),
            ],
          ),
        if (insights.suggestedActions.isNotEmpty)
          _InsightGroup(
            icon: Icons.bolt_rounded,
            color: theme.colorScheme.primary,
            title: l10n.insightsActionsTitle,
            items: [
              for (final a in insights.suggestedActions)
                (title: a.title, detail: a.detail, priority: a.priority),
            ],
          ),
        if (updated != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(l10n.insightsUpdated(updated),
              style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
        ],
      ],
    );
  }
}

class _InsightGroup extends StatelessWidget {
  const _InsightGroup({
    required this.icon,
    required this.color,
    required this.title,
    required this.items,
  });

  final IconData icon;
  final Color color;
  final String title;
  final List<({String title, String detail, InsightPriority? priority})> items;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(title,
                  style: theme.textTheme.labelLarge
                      ?.copyWith(fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final it in items)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Container(
                          width: 5,
                          height: 5,
                          decoration:
                              BoxDecoration(color: color, shape: BoxShape.circle),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                if (it.title.isNotEmpty)
                                  Expanded(
                                    child: Text(it.title,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                                fontWeight: FontWeight.w700)),
                                  ),
                                if (it.priority != null) ...[
                                  const SizedBox(width: AppSpacing.sm),
                                  PriorityChip(
                                    label: insightPriorityLabel(
                                        l10n, it.priority!),
                                    color: _priorityColor(theme, it.priority!),
                                  ),
                                ],
                              ],
                            ),
                            if (it.detail.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(it.detail,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                      height: 1.4,
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.7))),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static Color _priorityColor(ThemeData theme, InsightPriority p) => switch (p) {
        InsightPriority.high => AppColors.error,
        InsightPriority.medium => AppColors.warning,
        InsightPriority.low => theme.colorScheme.primary,
      };
}

// --- small shared bits ---

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, this.sub});
  final String label;
  final String value;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label,
            style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
        if (sub != null)
          Text(sub!,
              style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
      ],
    );
  }
}

class _MutedText extends StatelessWidget {
  const _MutedText(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(text,
        style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6)));
  }
}
