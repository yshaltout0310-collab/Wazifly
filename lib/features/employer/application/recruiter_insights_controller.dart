import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/locale_controller.dart';
import '../../../core/services/ai/ai_exception.dart';
import '../../../core/services/recruiter_insights_store/in_memory_recruiter_insights_store.dart';
import '../data/recruiter_insights_repository_impl.dart';
import '../domain/analytics/employer_analytics.dart';
import '../domain/analytics/recruiter_insights.dart';
import '../domain/analytics/recruiter_insights_context.dart';
import '../domain/analytics/recruiter_insights_exception.dart';
import 'company_providers.dart';
import 'employer_analytics_providers.dart';

/// Insights lifecycle. Unlike the always-on "For You" flow, insights are
/// generated **on demand** (a card inside an already-instant analytics
/// dashboard) — so we start [idle] rather than auto-calling the model, then move
/// to [loading]/[ready]/[error]. The rest of the pattern (context → signature →
/// repository → store → refresh guard) mirrors `RecommendationsController`.
enum RecruiterInsightsPhase { idle, loading, ready, error }

/// UI-facing, localizable failure categories.
enum RecruiterInsightsFailure {
  notConfigured,
  network,
  quota,
  invalidResponse,
  empty,
  unknown,
}

class RecruiterInsightsState extends Equatable {
  const RecruiterInsightsState({
    this.phase = RecruiterInsightsPhase.idle,
    this.insights,
    this.failure,
    this.isRefreshing = false,
    this.upToDate = false,
  });

  final RecruiterInsightsPhase phase;
  final RecruiterInsights? insights;
  final RecruiterInsightsFailure? failure;

  /// A regeneration is in flight while existing content stays on screen.
  final bool isRefreshing;

  /// Transient: the last refresh found no data changes (show an "up to date"
  /// hint, then clear).
  final bool upToDate;

  RecruiterInsightsState copyWith({
    RecruiterInsightsPhase? phase,
    RecruiterInsights? insights,
    RecruiterInsightsFailure? failure,
    bool? isRefreshing,
    bool? upToDate,
    bool clearFailure = false,
    bool clearUpToDate = false,
  }) =>
      RecruiterInsightsState(
        phase: phase ?? this.phase,
        insights: insights ?? this.insights,
        failure: clearFailure ? null : (failure ?? this.failure),
        isRefreshing: isRefreshing ?? this.isRefreshing,
        upToDate: clearUpToDate ? false : (upToDate ?? this.upToDate),
      );

  @override
  List<Object?> get props => [phase, insights, failure, isRefreshing, upToDate];
}

/// Drives the AI "Recruiter Insights" card: assemble a primitive
/// [RecruiterInsightsContext] from the computed analytics, generate (or reuse the
/// cached) insights, and persist them through the store seam. A refresh skips the
/// AI call when the underlying analytics are unchanged since the last generation.
class RecruiterInsightsController extends StateNotifier<RecruiterInsightsState> {
  RecruiterInsightsController(this._ref, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now,
        super(const RecruiterInsightsState()) {
    // Hydrate from the session cache; never auto-call the model.
    final cached = _ref.read(recruiterInsightsStoreProvider).read();
    if (cached != null) {
      state = RecruiterInsightsState(
        phase: RecruiterInsightsPhase.ready,
        insights: cached,
      );
    }
  }

  /// Test-only: start in an explicit state (no side effects).
  @visibleForTesting
  RecruiterInsightsController.seeded(this._ref, RecruiterInsightsState initial,
      {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now,
        super(initial);

  final Ref _ref;
  final DateTime Function() _clock;

  String get _languageCode =>
      _ref.read(localeControllerProvider)?.languageCode ?? 'en';

  /// First generation from the idle CTA / an error retry.
  Future<void> generate() => _generate(refresh: false);

  /// Regenerates keeping current content on screen; short-circuits to an "up to
  /// date" hint when the analytics haven't changed.
  Future<void> refresh() => _generate(refresh: true);

  Future<void> _generate({required bool refresh}) async {
    if (refresh) {
      state = state.copyWith(
          isRefreshing: true, clearFailure: true, clearUpToDate: true);
    } else {
      state = state.copyWith(
          phase: RecruiterInsightsPhase.loading,
          clearFailure: true,
          clearUpToDate: true);
    }

    try {
      final context = buildContext();
      final signature = '$_languageCode::${context.signature}';

      // Skip the AI call when a refresh finds the analytics unchanged.
      final cached = state.insights;
      if (refresh &&
          cached != null &&
          cached.sourceSignature.isNotEmpty &&
          cached.sourceSignature == signature) {
        if (!mounted) return;
        state = state.copyWith(isRefreshing: false, upToDate: true);
        return;
      }

      final result = await _ref
          .read(recruiterInsightsRepositoryProvider)
          .generate(context: context, languageCode: _languageCode);
      final stamped = result.stamp(
        generatedAt: _clock(),
        sourceSignature: signature,
      );
      await _ref.read(recruiterInsightsStoreProvider).save(stamped);
      if (!mounted) return;
      state = RecruiterInsightsState(
        phase: RecruiterInsightsPhase.ready,
        insights: stamped,
      );
    } catch (e) {
      if (!mounted) return;
      final failure = _mapFailure(e);
      if (state.insights != null) {
        // Keep showing existing content on a failed refresh.
        state = state.copyWith(isRefreshing: false, failure: failure);
      } else {
        state = state.copyWith(
            phase: RecruiterInsightsPhase.error,
            isRefreshing: false,
            failure: failure);
      }
    }
  }

  /// Flattens the computed [EmployerAnalytics] into the primitive context the
  /// repository consumes. Reads feature/core providers only.
  RecruiterInsightsContext buildContext() {
    final a = _ref.read(employerAnalyticsProvider);
    final companyName = _ref.read(currentCompanyProvider)?.name?.trim() ?? '';
    return contextFromAnalytics(a, companyName: companyName);
  }

  RecruiterInsightsFailure _mapFailure(Object e) {
    if (e is RecruiterInsightsException) {
      return switch (e.code) {
        RecruiterInsightsErrorCode.emptyInsights =>
          RecruiterInsightsFailure.empty,
      };
    }
    if (e is AiException) {
      return switch (e.code) {
        AiErrorCode.notConfigured => RecruiterInsightsFailure.notConfigured,
        AiErrorCode.network => RecruiterInsightsFailure.network,
        AiErrorCode.quota => RecruiterInsightsFailure.quota,
        AiErrorCode.emptyResponse ||
        AiErrorCode.invalidResponse =>
          RecruiterInsightsFailure.invalidResponse,
        _ => RecruiterInsightsFailure.unknown,
      };
    }
    debugPrint('[RecruiterInsights] failed: $e');
    return RecruiterInsightsFailure.unknown;
  }

  void clearFailure() => state = state.copyWith(clearFailure: true);
  void clearUpToDate() => state = state.copyWith(clearUpToDate: true);
}

/// Maps computed [EmployerAnalytics] to the primitive insights context (pulled
/// out of the controller so it is directly unit-testable).
RecruiterInsightsContext contextFromAnalytics(
  EmployerAnalytics a, {
  String companyName = '',
  int maxTopJobs = 5,
  int maxTopSkills = 8,
}) {
  final strong = a.quality.bands
      .firstWhere((b) => b.band == MatchBand.strong,
          orElse: () => const MatchBandCount(band: MatchBand.strong, count: 0))
      .count;
  final weak = a.quality.bands
      .firstWhere((b) => b.band == MatchBand.weak,
          orElse: () => const MatchBandCount(band: MatchBand.weak, count: 0))
      .count;

  final topJobs = [
    for (final j in a.jobPerformance.where((j) => j.applicants > 0).take(maxTopJobs))
      InsightJob(
        title: j.jobTitle,
        applicants: j.applicants,
        interviews: j.interviews,
        hires: j.hires,
      ),
  ];

  return RecruiterInsightsContext(
    companyName: companyName,
    totalJobs: a.overview.totalJobs,
    activeJobs: a.overview.activeJobs,
    totalApplicants: a.overview.totalApplicants,
    applied: a.funnel.applied,
    reviewed: a.funnel.reviewed,
    interview: a.funnel.interview,
    accepted: a.funnel.accepted,
    rejected: a.funnel.rejected,
    hireRatePercent: (a.funnel.acceptedShare * 100).round(),
    interviewRatePercent: (a.funnel.interviewShare * 100).round(),
    avgMatchScore: a.quality.avgMatchScore,
    avgAtsScore: a.quality.avgAtsScore,
    strongMatchCount: strong,
    weakMatchCount: weak,
    avgDaysToHire: a.timeToHire.avgDaysToHire.round(),
    openApplicants: a.timeToHire.openApplicants,
    avgDaysInPipeline: a.timeToHire.avgDaysInPipeline.round(),
    applicationsLast7Days: a.trend.applicationsLast7Days,
    topJobs: topJobs,
    topSkills: [for (final s in a.quality.topSkills.take(maxTopSkills)) s.skill],
  );
}

final recruiterInsightsControllerProvider = StateNotifierProvider<
    RecruiterInsightsController, RecruiterInsightsState>(
  RecruiterInsightsController.new,
);
