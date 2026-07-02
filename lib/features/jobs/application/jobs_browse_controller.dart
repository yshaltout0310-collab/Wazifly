import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/jobs/jobs_repository.dart';
import '../../../core/services/jobs/seed_jobs_repository.dart';
import '../../../shared/models/job.dart';

enum JobsStatus { loading, ready, error }

/// State for the jobs browse/search screen.
class JobsBrowseState extends Equatable {
  const JobsBrowseState({
    this.status = JobsStatus.loading,
    this.allJobs = const [],
    this.results = const [],
    this.query = const JobQuery(),
    this.typeOptions = const [],
    this.seniorityOptions = const [],
  });

  final JobsStatus status;

  /// The full dataset (used by derived views like Saved).
  final List<Job> allJobs;

  /// The current filtered/searched results.
  final List<Job> results;
  final JobQuery query;

  /// Distinct filter options derived from the dataset.
  final List<String> typeOptions;
  final List<String> seniorityOptions;

  bool get hasActiveFilters => query.hasFilters;

  JobsBrowseState copyWith({
    JobsStatus? status,
    List<Job>? allJobs,
    List<Job>? results,
    JobQuery? query,
    List<String>? typeOptions,
    List<String>? seniorityOptions,
  }) =>
      JobsBrowseState(
        status: status ?? this.status,
        allJobs: allJobs ?? this.allJobs,
        results: results ?? this.results,
        query: query ?? this.query,
        typeOptions: typeOptions ?? this.typeOptions,
        seniorityOptions: seniorityOptions ?? this.seniorityOptions,
      );

  @override
  List<Object?> get props =>
      [status, allJobs, results, query, typeOptions, seniorityOptions];
}

/// Loads the jobs list and applies live text + filter queries via the
/// [JobsRepository] (`searchJobs`), so the same code works against a real API.
class JobsBrowseController extends StateNotifier<JobsBrowseState> {
  JobsBrowseController(this._ref) : super(const JobsBrowseState()) {
    _load();
  }

  /// Test-only: start from a specific state without hitting the repository.
  @visibleForTesting
  JobsBrowseController.seeded(this._ref, JobsBrowseState initial)
      : super(initial);

  final Ref _ref;

  JobsRepository get _repo => _ref.read(jobsRepositoryProvider);

  Future<void> _load() async {
    try {
      final all = await _repo.fetchJobs();
      state = state.copyWith(
        status: JobsStatus.ready,
        allJobs: all,
        results: all,
        typeOptions: _distinct(all.map((j) => j.employmentType)),
        seniorityOptions: _distinct(all.map((j) => j.seniority)),
      );
    } catch (e) {
      debugPrint('[Jobs] load failed: $e');
      state = state.copyWith(status: JobsStatus.error);
    }
  }

  void updateText(String text) => _apply(state.query.copyWith(text: text));

  void toggleType(String type) =>
      _apply(state.query.copyWith(employmentTypes: _toggle(state.query.employmentTypes, type)));

  void toggleSeniority(String seniority) =>
      _apply(state.query.copyWith(seniorities: _toggle(state.query.seniorities, seniority)));

  void toggleRemote() =>
      _apply(state.query.copyWith(remoteOnly: !state.query.remoteOnly));

  void clearFilters() =>
      _apply(JobQuery(text: state.query.text)); // keep the text, drop filters

  Future<void> _apply(JobQuery query) async {
    final results = await _repo.searchJobs(query);
    if (!mounted) return;
    state = state.copyWith(query: query, results: results);
  }

  Set<String> _toggle(Set<String> set, String value) {
    final next = {...set};
    next.contains(value) ? next.remove(value) : next.add(value);
    return next;
  }

  static List<String> _distinct(Iterable<String> values) {
    final seen = <String>{};
    final out = <String>[];
    for (final v in values) {
      if (v.isNotEmpty && seen.add(v)) out.add(v);
    }
    return out;
  }
}

final jobsBrowseControllerProvider =
    StateNotifierProvider<JobsBrowseController, JobsBrowseState>(
  JobsBrowseController.new,
);
