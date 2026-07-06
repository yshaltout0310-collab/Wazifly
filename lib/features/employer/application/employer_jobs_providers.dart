import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/jobs/employer_jobs_repository.dart';
import '../../../shared/models/job_posting.dart';
import '../domain/job_status.dart';
import 'employer_jobs_controller.dart';

/// Sort orders for the My Jobs list.
enum JobSort { updated, created, title, status }

/// Search + status filter + sort for the My Jobs list.
class EmployerJobsFilter extends Equatable {
  const EmployerJobsFilter({
    this.text = '',
    this.statuses = const {},
    this.sort = JobSort.updated,
  });

  final String text;
  final Set<JobStatus> statuses;
  final JobSort sort;

  bool get isActive => text.trim().isNotEmpty || statuses.isNotEmpty;

  EmployerJobsFilter copyWith({
    String? text,
    Set<JobStatus>? statuses,
    JobSort? sort,
  }) =>
      EmployerJobsFilter(
        text: text ?? this.text,
        statuses: statuses ?? this.statuses,
        sort: sort ?? this.sort,
      );

  @override
  List<Object?> get props => [text, statuses, sort];
}

class EmployerJobsFilterController extends StateNotifier<EmployerJobsFilter> {
  EmployerJobsFilterController() : super(const EmployerJobsFilter());

  void updateText(String text) => state = state.copyWith(text: text);

  void toggleStatus(JobStatus status) {
    final next = {...state.statuses};
    next.contains(status) ? next.remove(status) : next.add(status);
    state = state.copyWith(statuses: next);
  }

  void setSort(JobSort sort) => state = state.copyWith(sort: sort);

  void clear() => state = const EmployerJobsFilter();
}

final employerJobsFilterProvider =
    StateNotifierProvider<EmployerJobsFilterController, EmployerJobsFilter>(
  (ref) => EmployerJobsFilterController(),
);

/// The authoritative employer-jobs stream with the controller's optimistic
/// overlay merged in (status overrides, optimistic removals + additions), so the
/// UI reflects lifecycle actions instantly.
final visibleEmployerJobsProvider = Provider<List<JobPosting>>((ref) {
  final base = ref.watch(employerJobsProvider).valueOrNull ?? const [];
  final action = ref.watch(employerJobsControllerProvider);

  final seen = <String>{};
  final out = <JobPosting>[];
  for (final j in [...action.added, ...base]) {
    if (action.removedIds.contains(j.id)) continue;
    if (!seen.add(j.id)) continue; // dedupe (added may overlap base briefly)
    out.add(action.overrides[j.id] ?? j);
  }
  return out;
});

/// The visible jobs after applying the current [EmployerJobsFilter] (search +
/// status filter + sort). Mirrors `filteredApplicationsProvider`.
final filteredEmployerJobsProvider = Provider<List<JobPosting>>((ref) {
  final jobs = ref.watch(visibleEmployerJobsProvider);
  final filter = ref.watch(employerJobsFilterProvider);
  final text = filter.text.trim().toLowerCase();

  final list = jobs.where((j) {
    if (filter.statuses.isNotEmpty && !filter.statuses.contains(j.status)) {
      return false;
    }
    if (text.isNotEmpty && !_matchesText(j, text)) return false;
    return true;
  }).toList();

  list.sort(_comparator(filter.sort));
  return List.unmodifiable(list);
});

/// A single posting by id, derived from the visible list so optimistic overrides
/// are reflected (null when not found / removed).
final employerJobByIdProvider = Provider.family<JobPosting?, String>((ref, id) {
  for (final j in ref.watch(visibleEmployerJobsProvider)) {
    if (j.id == id) return j;
  }
  return null;
});

/// Per-status counts for the My Jobs header.
class EmployerJobsStats extends Equatable {
  const EmployerJobsStats({
    this.total = 0,
    this.drafts = 0,
    this.published = 0,
    this.archived = 0,
    this.closed = 0,
  });

  final int total, drafts, published, archived, closed;

  @override
  List<Object?> get props => [total, drafts, published, archived, closed];
}

final employerJobsStatsProvider = Provider<EmployerJobsStats>((ref) {
  final jobs = ref.watch(visibleEmployerJobsProvider);
  int by(JobStatus s) => jobs.where((j) => j.status == s).length;
  return EmployerJobsStats(
    total: jobs.length,
    drafts: by(JobStatus.draft),
    published: by(JobStatus.published),
    archived: by(JobStatus.archived),
    closed: by(JobStatus.closed),
  );
});

bool _matchesText(JobPosting j, String text) {
  if (j.title.toLowerCase().contains(text)) return true;
  if (j.location.toLowerCase().contains(text)) return true;
  for (final s in j.requiredSkills) {
    if (s.toLowerCase().contains(text)) return true;
  }
  return false;
}

int Function(JobPosting, JobPosting) _comparator(JobSort sort) {
  final epoch = DateTime.fromMillisecondsSinceEpoch(0);
  return switch (sort) {
    JobSort.updated => (a, b) =>
        (b.updatedAt ?? epoch).compareTo(a.updatedAt ?? epoch),
    JobSort.created => (a, b) =>
        (b.createdAt ?? epoch).compareTo(a.createdAt ?? epoch),
    JobSort.title => (a, b) =>
        a.title.toLowerCase().compareTo(b.title.toLowerCase()),
    JobSort.status => (a, b) => a.status.index.compareTo(b.status.index),
  };
}
