import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/countries_data.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/services/jobs/seed_jobs_repository.dart';
import '../../../core/services/resume_store/resume_analysis_store.dart';
import '../../../shared/models/job.dart';
import '../../job_matching/data/job_matching_repository_impl.dart';
import '../../job_matching/domain/job_match.dart';

enum JobDetailStatus { loading, ready, notFound }

/// State of the on-demand "why it matches" computation.
enum MatchStatus { idle, loading, ready, error }

class JobDetailState extends Equatable {
  const JobDetailState({
    this.status = JobDetailStatus.loading,
    this.job,
    this.hasResume = false,
    this.matchStatus = MatchStatus.idle,
    this.match,
  });

  final JobDetailStatus status;
  final Job? job;

  /// Whether a cached resume analysis exists (drives the match affordance).
  final bool hasResume;

  final MatchStatus matchStatus;
  final JobMatch? match;

  JobDetailState copyWith({
    JobDetailStatus? status,
    Job? job,
    bool? hasResume,
    MatchStatus? matchStatus,
    JobMatch? match,
  }) =>
      JobDetailState(
        status: status ?? this.status,
        job: job ?? this.job,
        hasResume: hasResume ?? this.hasResume,
        matchStatus: matchStatus ?? this.matchStatus,
        match: match ?? this.match,
      );

  @override
  List<Object?> get props => [status, job, hasResume, matchStatus, match];
}

/// Loads one job by id and, on demand, scores it against the cached resume
/// analysis (reusing the shared `JobMatchingRepository.matchJob`).
class JobDetailController extends StateNotifier<JobDetailState> {
  JobDetailController(this._ref, this.jobId) : super(const JobDetailState()) {
    _load();
  }

  /// Test-only: start from a specific state without hitting the repository.
  @visibleForTesting
  JobDetailController.seeded(this._ref, this.jobId, JobDetailState initial)
      : super(initial);

  final Ref _ref;
  final String jobId;

  Future<void> _load() async {
    final job = await _ref.read(jobsRepositoryProvider).fetchJobById(jobId);
    if (!mounted) return;
    if (job == null) {
      state = state.copyWith(status: JobDetailStatus.notFound);
      return;
    }
    state = state.copyWith(
      status: JobDetailStatus.ready,
      job: job,
      hasResume: _ref.read(lastResumeAnalysisProvider) != null,
    );
  }

  /// Scores this job against the cached resume analysis. No-op without a resume.
  Future<void> computeMatch() async {
    final analysis = _ref.read(lastResumeAnalysisProvider);
    final job = state.job;
    if (analysis == null || job == null || state.matchStatus == MatchStatus.loading) {
      return;
    }
    state = state.copyWith(matchStatus: MatchStatus.loading);
    try {
      final languageCode =
          _ref.read(localeControllerProvider)?.languageCode ?? 'en';
      // Qatar market default (consistent with Browse / Matching / Coach / Interview).
      final country = CountriesData.defaultCountry.name;
      final match = await _ref.read(jobMatchingRepositoryProvider).matchJob(
            analysis: analysis,
            job: job,
            languageCode: languageCode,
            country: country,
          );
      if (!mounted) return;
      state = state.copyWith(matchStatus: MatchStatus.ready, match: match);
    } catch (e) {
      debugPrint('[JobDetail] match failed: $e');
      if (!mounted) return;
      state = state.copyWith(matchStatus: MatchStatus.error);
    }
  }
}

final jobDetailControllerProvider = StateNotifierProvider.family<
    JobDetailController, JobDetailState, String>(
  (ref, jobId) => JobDetailController(ref, jobId),
);
