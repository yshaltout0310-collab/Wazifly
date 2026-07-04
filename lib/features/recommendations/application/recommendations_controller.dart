import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/locale_controller.dart';
import '../../../core/services/ai/ai_exception.dart';
import '../../../core/services/applications/in_memory_applications_repository.dart';
import '../../../core/services/cv_store/cv_draft_store.dart';
import '../../../core/services/interview_store/in_memory_interview_history_repository.dart';
import '../../../core/services/jobs/saved_jobs_store.dart';
import '../../../core/services/jobs/seed_jobs_repository.dart';
import '../../../core/services/recommendations_store/in_memory_recommendations_store.dart';
import '../../../core/services/resume_store/resume_analysis_store.dart';
import '../../../shared/models/application.dart';
import '../../profile/application/profile_completion_provider.dart';
import '../data/recommendations_repository_impl.dart';
import '../domain/recommendation_context.dart';
import '../domain/recommendation_models.dart';
import '../domain/recommendations_exception.dart';

enum RecommendationsPhase { loading, ready, error }

/// UI-facing, localizable failure categories.
enum RecommendationFailure {
  notConfigured,
  network,
  quota,
  invalidResponse,
  empty,
  unknown,
}

class RecommendationsState extends Equatable {
  const RecommendationsState({
    this.phase = RecommendationsPhase.loading,
    this.recommendations,
    this.failure,
    this.isRefreshing = false,
    this.upToDate = false,
    this.personalized = true,
  });

  final RecommendationsPhase phase;
  final Recommendations? recommendations;
  final RecommendationFailure? failure;

  /// A regeneration is in flight while existing content stays on screen.
  final bool isRefreshing;

  /// Transient: the last refresh found no data changes (show an "up to date"
  /// hint, then clear).
  final bool upToDate;

  /// False when the candidate has shared almost nothing (drives a gentle nudge).
  final bool personalized;

  RecommendationsState copyWith({
    RecommendationsPhase? phase,
    Recommendations? recommendations,
    RecommendationFailure? failure,
    bool? isRefreshing,
    bool? upToDate,
    bool? personalized,
    bool clearFailure = false,
    bool clearUpToDate = false,
  }) =>
      RecommendationsState(
        phase: phase ?? this.phase,
        recommendations: recommendations ?? this.recommendations,
        failure: clearFailure ? null : (failure ?? this.failure),
        isRefreshing: isRefreshing ?? this.isRefreshing,
        upToDate: clearUpToDate ? false : (upToDate ?? this.upToDate),
        personalized: personalized ?? this.personalized,
      );

  @override
  List<Object?> get props =>
      [phase, recommendations, failure, isRefreshing, upToDate, personalized];
}

/// Drives the "For You" flow: assemble a personalized [RecommendationContext]
/// from core providers, generate (or reuse the cached) recommendations, and
/// persist them through the store seam. A refresh skips the AI call when the
/// underlying user data is unchanged since the last generation.
class RecommendationsController extends StateNotifier<RecommendationsState> {
  RecommendationsController(this._ref, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now,
        super(const RecommendationsState()) {
    final cached = _ref.read(recommendationsStoreProvider).read();
    if (cached != null) {
      state = RecommendationsState(
        phase: RecommendationsPhase.ready,
        recommendations: cached,
      );
    } else {
      Future.microtask(() => _generate(refresh: false));
    }
  }

  /// Test-only: start in an explicit state (no auto-generate).
  @visibleForTesting
  RecommendationsController.seeded(this._ref, RecommendationsState initial,
      {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now,
        super(initial);

  final Ref _ref;
  final DateTime Function() _clock;

  String get _languageCode =>
      _ref.read(localeControllerProvider)?.languageCode ?? 'en';

  /// Regenerates keeping any current content on screen; short-circuits to an
  /// "up to date" hint when nothing changed.
  Future<void> refresh() => _generate(refresh: true);

  /// Retries from scratch after an error.
  Future<void> retry() => _generate(refresh: false);

  Future<void> _generate({required bool refresh}) async {
    if (refresh) {
      state = state.copyWith(
          isRefreshing: true, clearFailure: true, clearUpToDate: true);
    } else {
      state = state.copyWith(
          phase: RecommendationsPhase.loading,
          clearFailure: true,
          clearUpToDate: true);
    }

    try {
      final context = await buildContext();
      // Fold the language into the signature so switching language (which
      // changes the AI output language) busts the "up to date" guard.
      final signature = '$_languageCode::${context.signature}';

      // Skip the AI call when a refresh finds the source data unchanged.
      final cached = state.recommendations;
      if (refresh &&
          cached != null &&
          cached.sourceSignature.isNotEmpty &&
          cached.sourceSignature == signature) {
        if (!mounted) return;
        state = state.copyWith(
          isRefreshing: false,
          upToDate: true,
          personalized: context.hasSignal,
        );
        return;
      }

      final result = await _ref
          .read(recommendationsRepositoryProvider)
          .generate(context: context, languageCode: _languageCode);
      final stamped = result.stamp(
        generatedAt: _clock(),
        sourceSignature: signature,
      );
      await _ref.read(recommendationsStoreProvider).save(stamped);
      if (!mounted) return;
      state = RecommendationsState(
        phase: RecommendationsPhase.ready,
        recommendations: stamped,
        personalized: context.hasSignal,
      );
    } catch (e) {
      if (!mounted) return;
      final failure = _mapFailure(e);
      // Keep showing existing content on a failed refresh; else go to error.
      if (state.recommendations != null) {
        state = state.copyWith(isRefreshing: false, failure: failure);
      } else {
        state = state.copyWith(
            phase: RecommendationsPhase.error,
            isRefreshing: false,
            failure: failure);
      }
    }
  }

  /// Flattens the reused signals (profile, resume analysis, CV, applications,
  /// interviews, saved + available jobs) into the primitive context the
  /// repository consumes. Reads **core providers only**.
  Future<RecommendationContext> buildContext() async {
    final profile = _ref.read(currentUserProfileProvider);
    final resume = _ref.read(lastResumeAnalysisProvider);
    final cv = _ref.read(cvDraftStoreProvider).read();
    final saved = _ref.read(savedJobsProvider);

    final apps = await _ref.read(applicationsProvider.future);
    final interviews = await _ref.read(interviewSessionsProvider.future);
    final jobs = await _ref.read(jobsRepositoryProvider).fetchJobs();

    final availableJobs = [
      for (final j in jobs)
        AvailableJob(
          id: j.id,
          title: j.title,
          company: j.company,
          seniority: j.seniority,
          location: j.location,
          remote: j.remote,
          requiredSkills: j.requiredSkills,
        ),
    ];

    final appliedJobIds = {for (final a in apps) a.jobId};
    final appliedTitles = <String>{
      for (final a in apps)
        if (a.jobTitle.trim().isNotEmpty) a.jobTitle,
    }.toList();
    final interviewsReached = apps
        .where((a) =>
            a.history.any((e) => e.status == ApplicationStatus.interview))
        .length;
    final offers =
        apps.where((a) => a.status == ApplicationStatus.accepted).length;

    final savedTitles = <String>[
      for (final id in saved)
        ...availableJobs.where((j) => j.id == id).map((j) => j.title),
    ];

    // Interview performance across completed sessions.
    final completed = interviews.where((s) => s.summary != null).toList();
    final typesPracticed =
        <String>{for (final s in interviews) s.type.name}.toList();
    var avgScore = 0;
    var weakest = '';
    if (completed.isNotEmpty) {
      avgScore = (completed
                  .map((s) => s.overallScore)
                  .fold<int>(0, (a, b) => a + b) /
              completed.length)
          .round();
      var comm = 0, tech = 0, conf = 0, clar = 0;
      for (final s in completed) {
        final sc = s.summary!.scores;
        comm += sc.communication;
        tech += sc.technicalAccuracy;
        conf += sc.confidence;
        clar += sc.clarity;
      }
      final dims = <String, int>{
        'communication': comm,
        'technical accuracy': tech,
        'confidence': conf,
        'clarity': clar,
      };
      weakest = dims.entries.reduce((a, b) => a.value <= b.value ? a : b).key;
    }

    final cvExperiences = <String>[
      for (final e in cv?.experiences ?? const [])
        if (!e.isBlank)
          [e.role, e.company].where((s) => s.isNotEmpty).join(' — '),
    ].where((s) => s.isNotEmpty).toList();

    return RecommendationContext(
      candidateName: profile?.displayName ?? '',
      headline: profile?.headline ?? '',
      location: profile?.location ?? '',
      experienceLevel: profile?.experienceLevel?.name ?? '',
      skills: profile?.skills ?? const [],
      preferredTitles: profile?.preferredJobTitles ?? const [],
      profileCompletion: profile?.completionPercent ?? 0,
      hasLinks: profile?.hasAnyLink ?? false,
      resumeSummary: resume?.summary ?? '',
      resumeStrengths: resume?.strengths ?? const [],
      resumeWeaknesses: resume?.weaknesses ?? const [],
      resumeMissingSkills: resume?.missingSkills ?? const [],
      atsScore: resume?.atsScore ?? 0,
      cvTargetRole: cv?.targetRole ?? '',
      cvExperiences: cvExperiences,
      cvSkills: cv?.skills ?? const [],
      appliedCount: apps.length,
      savedCount: saved.length,
      interviewsReached: interviewsReached,
      offers: offers,
      appliedTitles: appliedTitles,
      savedTitles: savedTitles,
      interviewCount: completed.length,
      avgInterviewScore: avgScore,
      weakestDimension: weakest,
      typesPracticed: typesPracticed,
      availableJobs: availableJobs,
      appliedJobIds: appliedJobIds,
    );
  }

  void clearFailure() => state = state.copyWith(clearFailure: true);
  void clearUpToDate() => state = state.copyWith(clearUpToDate: true);

  RecommendationFailure _mapFailure(Object e) {
    if (e is RecommendationsException) {
      return switch (e.code) {
        RecErrorCode.emptyRecommendations => RecommendationFailure.empty,
      };
    }
    if (e is AiException) {
      return switch (e.code) {
        AiErrorCode.notConfigured => RecommendationFailure.notConfigured,
        AiErrorCode.network => RecommendationFailure.network,
        AiErrorCode.quota => RecommendationFailure.quota,
        AiErrorCode.emptyResponse ||
        AiErrorCode.invalidResponse =>
          RecommendationFailure.invalidResponse,
        _ => RecommendationFailure.unknown,
      };
    }
    debugPrint('[Recommendations] failed: $e');
    return RecommendationFailure.unknown;
  }
}

final recommendationsControllerProvider =
    StateNotifierProvider<RecommendationsController, RecommendationsState>(
  RecommendationsController.new,
);
