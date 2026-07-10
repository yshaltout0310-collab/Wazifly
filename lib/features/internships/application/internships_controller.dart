import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/jobs/jobs_repository.dart';
import '../../../core/services/jobs/seed_jobs_repository.dart';
import '../../../shared/models/internship_details.dart';
import '../../../shared/models/job.dart';

enum InternshipsStatus { loading, ready, error }

/// Filter state for the internship browse screen. All fields optional; an empty
/// filter matches every internship. Facets beyond free text are internship-only,
/// so they're applied in-memory here (a future API can push them down).
class InternshipFilter extends Equatable {
  const InternshipFilter({
    this.text = '',
    this.funding = const {},
    this.workModes = const {},
    this.categories = const {},
    this.levels = const {},
  });

  final String text;
  final Set<InternshipFunding> funding;
  final Set<WorkMode> workModes;
  final Set<InternshipCategory> categories;
  final Set<InternshipLevel> levels;

  bool get hasFilters =>
      text.trim().isNotEmpty ||
      funding.isNotEmpty ||
      workModes.isNotEmpty ||
      categories.isNotEmpty ||
      levels.isNotEmpty;

  bool get hasFacetFilters =>
      funding.isNotEmpty ||
      workModes.isNotEmpty ||
      categories.isNotEmpty ||
      levels.isNotEmpty;

  InternshipFilter copyWith({
    String? text,
    Set<InternshipFunding>? funding,
    Set<WorkMode>? workModes,
    Set<InternshipCategory>? categories,
    Set<InternshipLevel>? levels,
  }) =>
      InternshipFilter(
        text: text ?? this.text,
        funding: funding ?? this.funding,
        workModes: workModes ?? this.workModes,
        categories: categories ?? this.categories,
        levels: levels ?? this.levels,
      );

  @override
  List<Object?> get props => [text, funding, workModes, categories, levels];
}

class InternshipsState extends Equatable {
  const InternshipsState({
    this.status = InternshipsStatus.loading,
    this.all = const [],
    this.results = const [],
    this.filter = const InternshipFilter(),
  });

  final InternshipsStatus status;

  /// All internships in the dataset.
  final List<Job> all;

  /// The current filtered results.
  final List<Job> results;
  final InternshipFilter filter;

  bool get hasActiveFilters => filter.hasFilters;

  InternshipsState copyWith({
    InternshipsStatus? status,
    List<Job>? all,
    List<Job>? results,
    InternshipFilter? filter,
  }) =>
      InternshipsState(
        status: status ?? this.status,
        all: all ?? this.all,
        results: results ?? this.results,
        filter: filter ?? this.filter,
      );

  @override
  List<Object?> get props => [status, all, results, filter];
}

/// Loads the internship subset of the shared jobs source and applies live text +
/// facet filters — a **scoped consumer** of [JobsRepository], not a parallel jobs
/// stack (the milestone's "don't duplicate Jobs" mandate). Mirrors
/// `JobsBrowseController`; a real jobs API drops in by rebinding the repository.
class InternshipsController extends StateNotifier<InternshipsState> {
  InternshipsController(this._ref) : super(const InternshipsState()) {
    _load();
  }

  /// Test-only: start from a specific state without hitting the repository.
  @visibleForTesting
  InternshipsController.seeded(this._ref, InternshipsState initial)
      : super(initial);

  final Ref _ref;

  JobsRepository get _repo => _ref.read(jobsRepositoryProvider);

  Future<void> _load() async {
    try {
      final all = await _repo.fetchJobs();
      final internships =
          all.where((j) => j.isInternship).toList(growable: false);
      state = state.copyWith(
        status: InternshipsStatus.ready,
        all: internships,
        results: _applyFilter(internships, state.filter),
      );
    } catch (e) {
      debugPrint('[Internships] load failed: $e');
      state = state.copyWith(status: InternshipsStatus.error);
    }
  }

  void updateText(String text) => _apply(state.filter.copyWith(text: text));

  void toggleFunding(InternshipFunding v) =>
      _apply(state.filter.copyWith(funding: _toggle(state.filter.funding, v)));

  void toggleWorkMode(WorkMode v) =>
      _apply(state.filter.copyWith(workModes: _toggle(state.filter.workModes, v)));

  void toggleCategory(InternshipCategory v) => _apply(
      state.filter.copyWith(categories: _toggle(state.filter.categories, v)));

  void toggleLevel(InternshipLevel v) =>
      _apply(state.filter.copyWith(levels: _toggle(state.filter.levels, v)));

  void clearFilters() =>
      _apply(InternshipFilter(text: state.filter.text)); // keep text, drop facets

  void retry() {
    state = state.copyWith(status: InternshipsStatus.loading);
    _load();
  }

  void _apply(InternshipFilter filter) {
    state = state.copyWith(
        filter: filter, results: _applyFilter(state.all, filter));
  }

  static List<Job> _applyFilter(List<Job> jobs, InternshipFilter f) {
    final q = f.text.trim().toLowerCase();
    return jobs.where((j) {
      if (q.isNotEmpty) {
        final hay = [
          j.title,
          j.company,
          j.location,
          ...j.requiredSkills,
        ].join(' ').toLowerCase();
        if (!hay.contains(q)) return false;
      }
      final d = j.internship;
      if (f.funding.isNotEmpty && !(d != null && f.funding.contains(d.funding))) {
        return false;
      }
      if (f.workModes.isNotEmpty &&
          !(d != null && f.workModes.contains(d.workMode))) {
        return false;
      }
      if (f.categories.isNotEmpty &&
          !(d != null && f.categories.contains(d.category))) {
        return false;
      }
      if (f.levels.isNotEmpty && !(d != null && f.levels.contains(d.level))) {
        return false;
      }
      return true;
    }).toList(growable: false);
  }

  static Set<T> _toggle<T>(Set<T> set, T value) {
    final next = {...set};
    next.contains(value) ? next.remove(value) : next.add(value);
    return next;
  }
}

final internshipsControllerProvider =
    StateNotifierProvider<InternshipsController, InternshipsState>(
  InternshipsController.new,
);
