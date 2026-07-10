import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/locale_controller.dart';
import '../../../core/services/ai/ai_exception.dart';
import '../../../core/services/cv_repository/cv_document.dart';
import '../../../core/services/cv_repository/cv_repository.dart';
import '../../../core/services/recommendations_store/in_memory_recommendations_store.dart';
import '../../../core/services/resume_store/resume_analysis_store.dart';
import '../../job_matching/data/job_matching_repository_impl.dart';

/// Wires the existing AI features to a specific CV **without modifying them**:
/// it reads the shared core seams (`lastResumeAnalysisProvider`,
/// `recommendationsStoreProvider`) and the Job-Matching repository, then persists
/// each CV's own results back onto its [CvDocument]. The AI features stay unaware
/// of CVs (the "integrate via core seams" rule).
class CvAiController extends StateNotifier<CvAiState> {
  CvAiController(this._ref) : super(const CvAiState());

  final Ref _ref;

  CvRepository get _repo => _ref.read(cvRepositoryProvider);
  DateTime _now() => DateTime.now();

  void clearFailure() => state = state.copyWith(clearFailure: true);

  /// Whether the user has a cached analysis to attach to a CV.
  bool get hasCachedAnalysis => _ref.read(lastResumeAnalysisProvider) != null;

  /// Attaches the most recent Resume Analyzer result to [cv] (its own analysis
  /// + ATS score). Returns false if there's nothing cached.
  Future<bool> attachLastAnalysis(CvDocument cv) async {
    final analysis = _ref.read(lastResumeAnalysisProvider);
    if (analysis == null) return false;
    await _repo.updateCv(cv.withAnalysis(analysis, _now()));
    return true;
  }

  /// Runs Job Matching for [cv] using its own analysis and stores a compact,
  /// owned snapshot of the top results. Requires the CV to have an analysis.
  Future<bool> runMatching(CvDocument cv) async {
    final analysis = cv.analysis;
    if (analysis == null) {
      state = state.copyWith(failure: CvAiFailure.needsAnalysis);
      return false;
    }
    state = state.copyWith(running: true, clearFailure: true);
    try {
      final lang = _ref.read(localeControllerProvider)?.languageCode ?? 'en';
      final matches = await _ref
          .read(jobMatchingRepositoryProvider)
          .matchJobs(analysis: analysis, languageCode: lang);
      final compact = matches
          .take(5)
          .map((m) => CvMatchResult(
                jobId: m.job.id,
                jobTitle: m.job.title,
                company: m.job.company,
                score: m.matchScore,
                reason: m.reason,
              ))
          .toList();
      await _repo.updateCv(cv.withMatches(compact, _now()));
      state = state.copyWith(running: false);
      return true;
    } catch (e) {
      debugPrint('[CvAi] matching failed: $e');
      state = state.copyWith(running: false, failure: _mapFailure(e));
      return false;
    }
  }

  /// Whether the user has cached "For You" recommendations to attach.
  bool get hasCachedRecommendations =>
      _ref.read(recommendationsStoreProvider).read() != null;

  /// Snapshots the latest "For You" recommendations onto [cv] (compact, owned).
  Future<bool> attachLastRecommendations(CvDocument cv) async {
    final rec = _ref.read(recommendationsStoreProvider).read();
    if (rec == null) return false;
    final summary = CvRecommendationSummary(
      headline: rec.headline,
      focusAreas:
          rec.skillsToLearn.take(4).map((s) => s.skill).toList(growable: false),
      generatedAt: _now(),
    );
    await _repo.updateCv(cv.withRecommendations(summary, _now()));
    return true;
  }

  CvAiFailure _mapFailure(Object e) {
    if (e is AiException) {
      return switch (e.code) {
        AiErrorCode.notConfigured => CvAiFailure.notConfigured,
        AiErrorCode.network => CvAiFailure.network,
        AiErrorCode.quota => CvAiFailure.quota,
        AiErrorCode.emptyResponse ||
        AiErrorCode.invalidResponse =>
          CvAiFailure.invalidResponse,
        _ => CvAiFailure.unknown,
      };
    }
    return CvAiFailure.unknown;
  }
}

/// AI-action failures on a CV (localized by the detail screen).
enum CvAiFailure {
  needsAnalysis,
  notConfigured,
  network,
  quota,
  invalidResponse,
  unknown,
}

class CvAiState extends Equatable {
  const CvAiState({this.running = false, this.failure});

  final bool running;
  final CvAiFailure? failure;

  CvAiState copyWith({bool? running, CvAiFailure? failure, bool clearFailure = false}) =>
      CvAiState(
        running: running ?? this.running,
        failure: clearFailure ? null : (failure ?? this.failure),
      );

  @override
  List<Object?> get props => [running, failure];
}

final cvAiControllerProvider =
    StateNotifierProvider<CvAiController, CvAiState>(CvAiController.new);
