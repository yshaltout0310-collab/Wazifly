import 'package:equatable/equatable.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/locale_controller.dart';
import '../../../core/services/ai/ai_exception.dart';
import '../../../core/services/resume_store/resume_analysis_store.dart';
import '../../resume_analyzer/domain/resume_analysis.dart';
import '../../resume_analyzer/domain/resume_analyzer_exception.dart';
import '../../resume_analyzer/data/resume_analyzer_repository_impl.dart';
import '../data/job_matching_repository_impl.dart';
import '../domain/job_match.dart';
import '../domain/job_matching_exception.dart';

/// Where job matching is in its lifecycle.
enum JobMatchStatus {
  /// No analyzed resume is available — prompt the user to upload one.
  needsResume,

  /// Analyzing a freshly uploaded resume before matching.
  analyzingResume,

  /// Ranking jobs against the resume analysis.
  matching,

  /// Ranked matches are ready.
  success,

  /// Something failed.
  error,
}

/// UI-facing, localizable failure categories (unifies resume-upload + AI +
/// matching errors).
enum JobMatchFailure {
  noJobs,
  notConfigured,
  network,
  quota,
  invalidResponse,
  blocked,
  resumeNoText,
  resumeExtraction,
  unknown,
}

/// Immutable state for the job matching screen.
class JobMatchingState extends Equatable {
  const JobMatchingState({
    this.status = JobMatchStatus.needsResume,
    this.matches = const [],
    this.failure,
  });

  final JobMatchStatus status;
  final List<JobMatch> matches;
  final JobMatchFailure? failure;

  bool get isBusy =>
      status == JobMatchStatus.matching ||
      status == JobMatchStatus.analyzingResume;

  @override
  List<Object?> get props => [status, matches, failure];
}

/// Drives job matching. At construction it uses a cached [ResumeAnalysis] when
/// one exists (matching immediately, no re-upload); otherwise it starts on the
/// upload prompt, then analyzes the chosen resume (reusing the Resume Analyzer
/// pipeline), caches it, and matches automatically.
class JobMatchingController extends StateNotifier<JobMatchingState> {
  JobMatchingController(Ref ref)
      : _ref = ref,
        super(_initialState(ref)) {
    // If a resume was already analyzed this session, match against it right
    // away. Reading the cached analysis in the constructor mirrors how
    // LocaleController hydrates from storage on creation.
    final analysis = ref.read(lastResumeAnalysisProvider);
    if (analysis != null) {
      Future.microtask(() => _match(analysis));
    }
  }

  /// Test-only: start in a specific state so views can be rendered without
  /// running the AI or the file picker.
  @visibleForTesting
  JobMatchingController.seeded(this._ref, JobMatchingState initial)
      : super(initial);

  final Ref _ref;

  /// Picks the initial view: match (a resume is cached) or prompt for a resume.
  static JobMatchingState _initialState(Ref ref) {
    final hasResume = ref.read(lastResumeAnalysisProvider) != null;
    return JobMatchingState(
      status:
          hasResume ? JobMatchStatus.matching : JobMatchStatus.needsResume,
    );
  }

  /// Opens the file picker, analyzes the chosen PDF (reusing the Resume
  /// Analyzer pipeline), caches the result, then matches jobs.
  ///
  /// A cancelled pick leaves the current state untouched.
  Future<void> pickAnalyzeAndMatch() async {
    if (state.isBusy) return;

    final XFile? file;
    try {
      file = await openFile(
        acceptedTypeGroups: const [
          XTypeGroup(
            label: 'PDF',
            extensions: ['pdf'],
            mimeTypes: ['application/pdf'],
            uniformTypeIdentifiers: ['com.adobe.pdf'],
          ),
        ],
      );
    } catch (e) {
      debugPrint('[JobMatching] pick failed: $e');
      state = const JobMatchingState(
          status: JobMatchStatus.error, failure: JobMatchFailure.unknown);
      return;
    }
    if (file == null) return; // cancelled

    final Uint8List bytes;
    try {
      bytes = await file.readAsBytes();
    } catch (e) {
      debugPrint('[JobMatching] read failed: $e');
      state = const JobMatchingState(
          status: JobMatchStatus.error,
          failure: JobMatchFailure.resumeExtraction);
      return;
    }

    state = const JobMatchingState(status: JobMatchStatus.analyzingResume);
    final ResumeAnalysis analysis;
    try {
      final languageCode =
          _ref.read(localeControllerProvider)?.languageCode ?? 'en';
      analysis = await _ref.read(resumeAnalyzerRepositoryProvider).analyze(
            pdfBytes: bytes,
            languageCode: languageCode,
            fileName: file.name,
          );
      await _ref.read(lastResumeAnalysisProvider.notifier).set(analysis);
    } catch (e) {
      if (!mounted) return;
      state = JobMatchingState(
          status: JobMatchStatus.error, failure: _mapFailure(e));
      return;
    }
    if (!mounted) return;
    await _match(analysis);
  }

  /// Re-runs whatever the current situation calls for (used by the error view).
  Future<void> retry() async {
    final analysis = _ref.read(lastResumeAnalysisProvider);
    if (analysis == null) {
      await pickAnalyzeAndMatch();
    } else {
      await _match(analysis);
    }
  }

  /// Discards the cached resume and returns to the upload prompt so the user
  /// can match against a different resume.
  void useAnotherResume() {
    _ref.read(lastResumeAnalysisProvider.notifier).clearAnalysis();
    state = const JobMatchingState(status: JobMatchStatus.needsResume);
  }

  Future<void> _match(ResumeAnalysis analysis) async {
    state = const JobMatchingState(status: JobMatchStatus.matching);
    try {
      final languageCode =
          _ref.read(localeControllerProvider)?.languageCode ?? 'en';
      final matches = await _ref.read(jobMatchingRepositoryProvider).matchJobs(
            analysis: analysis,
            languageCode: languageCode,
          );
      if (!mounted) return;
      state =
          JobMatchingState(status: JobMatchStatus.success, matches: matches);
    } catch (e) {
      if (!mounted) return;
      state = JobMatchingState(
          status: JobMatchStatus.error, failure: _mapFailure(e));
    }
  }

  JobMatchFailure _mapFailure(Object e) {
    if (e is JobMatchingException) {
      return switch (e.code) {
        JobMatchErrorCode.noJobs => JobMatchFailure.noJobs,
      };
    }
    if (e is ResumeAnalyzerException) {
      return switch (e.code) {
        ResumeErrorCode.noText => JobMatchFailure.resumeNoText,
        ResumeErrorCode.extractionFailed ||
        ResumeErrorCode.tooLarge =>
          JobMatchFailure.resumeExtraction,
      };
    }
    if (e is AiException) {
      return switch (e.code) {
        AiErrorCode.notConfigured => JobMatchFailure.notConfigured,
        AiErrorCode.network => JobMatchFailure.network,
        AiErrorCode.quota => JobMatchFailure.quota,
        AiErrorCode.emptyResponse ||
        AiErrorCode.invalidResponse =>
          JobMatchFailure.invalidResponse,
        AiErrorCode.blocked => JobMatchFailure.blocked,
        AiErrorCode.unknown => JobMatchFailure.unknown,
      };
    }
    debugPrint('[JobMatching] unmapped error: $e');
    return JobMatchFailure.unknown;
  }
}

final jobMatchingControllerProvider =
    StateNotifierProvider<JobMatchingController, JobMatchingState>(
  JobMatchingController.new,
);
