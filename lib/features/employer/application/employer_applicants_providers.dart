import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/applications/employer_applicants_repository.dart';
import '../../../shared/models/application.dart';
import 'employer_applicants_controller.dart';

/// Sort orders for the applicants list.
enum ApplicantSort { recent, matchScore, name, status }

/// Search + status filter + optional job scope + sort for the applicants list.
class ApplicantsFilter extends Equatable {
  const ApplicantsFilter({
    this.text = '',
    this.statuses = const {},
    this.jobId,
    this.sort = ApplicantSort.recent,
  });

  final String text;
  final Set<ApplicationStatus> statuses;

  /// When set, restricts the list to a single job (per-job view).
  final String? jobId;
  final ApplicantSort sort;

  bool get isActive => text.trim().isNotEmpty || statuses.isNotEmpty;

  ApplicantsFilter copyWith({
    String? text,
    Set<ApplicationStatus>? statuses,
    Object? jobId = _sentinel,
    ApplicantSort? sort,
  }) =>
      ApplicantsFilter(
        text: text ?? this.text,
        statuses: statuses ?? this.statuses,
        jobId: jobId == _sentinel ? this.jobId : jobId as String?,
        sort: sort ?? this.sort,
      );

  static const Object _sentinel = Object();

  @override
  List<Object?> get props => [text, statuses, jobId, sort];
}

class ApplicantsFilterController extends StateNotifier<ApplicantsFilter> {
  ApplicantsFilterController() : super(const ApplicantsFilter());

  void updateText(String text) => state = state.copyWith(text: text);

  void toggleStatus(ApplicationStatus status) {
    final next = {...state.statuses};
    next.contains(status) ? next.remove(status) : next.add(status);
    state = state.copyWith(statuses: next);
  }

  void setSort(ApplicantSort sort) => state = state.copyWith(sort: sort);

  /// Restrict to a single job (or clear with null).
  void setJob(String? jobId) => state = state.copyWith(jobId: jobId);

  /// Clears search + status (keeps the job scope + sort).
  void clear() => state =
      ApplicantsFilter(jobId: state.jobId, sort: state.sort);
}

final employerApplicantsFilterProvider =
    StateNotifierProvider<ApplicantsFilterController, ApplicantsFilter>(
  (ref) => ApplicantsFilterController(),
);

/// The authoritative applicants stream with the controller's optimistic status
/// overrides merged in, so lifecycle actions reflect instantly (mirrors
/// `visibleEmployerJobsProvider`).
final visibleApplicantsProvider = Provider<List<Application>>((ref) {
  final base = ref.watch(employerApplicantsProvider).valueOrNull ?? const [];
  final action = ref.watch(employerApplicantsControllerProvider);
  if (action.overrides.isEmpty) return base;
  return [for (final a in base) action.overrides[a.id] ?? a];
});

/// The visible applicants after the current [ApplicantsFilter] (search + status +
/// job scope + sort).
final filteredApplicantsProvider = Provider<List<Application>>((ref) {
  final apps = ref.watch(visibleApplicantsProvider);
  final filter = ref.watch(employerApplicantsFilterProvider);
  final text = filter.text.trim().toLowerCase();

  final list = apps.where((a) {
    if (filter.jobId != null && a.jobId != filter.jobId) return false;
    if (filter.statuses.isNotEmpty && !filter.statuses.contains(a.status)) {
      return false;
    }
    if (text.isNotEmpty && !_matchesText(a, text)) return false;
    return true;
  }).toList();

  list.sort(_comparator(filter.sort));
  return List.unmodifiable(list);
});

/// One job's applicants (per-job view + the job-detail count).
final applicantsForJobProvider =
    Provider.family<List<Application>, String>((ref, jobId) {
  final apps = ref.watch(visibleApplicantsProvider);
  final list = apps.where((a) => a.jobId == jobId).toList();
  list.sort(_comparator(ApplicantSort.recent));
  return List.unmodifiable(list);
});

/// A single applicant by id (reflects optimistic overrides; null when withdrawn).
final applicantByIdProvider =
    Provider.family<Application?, String>((ref, id) {
  for (final a in ref.watch(visibleApplicantsProvider)) {
    if (a.id == id) return a;
  }
  return null;
});

/// A group of applicants for one job (the "grouped by job" list).
class ApplicantGroup extends Equatable {
  const ApplicantGroup({
    required this.jobId,
    required this.jobTitle,
    required this.applicants,
  });

  final String jobId;
  final String jobTitle;
  final List<Application> applicants;

  int get count => applicants.length;

  @override
  List<Object?> get props => [jobId, jobTitle, applicants];
}

/// Filtered applicants grouped by job, jobs ordered by most-recent activity.
final groupedApplicantsProvider = Provider<List<ApplicantGroup>>((ref) {
  final apps = ref.watch(filteredApplicantsProvider);
  final byJob = <String, List<Application>>{};
  for (final a in apps) {
    byJob.putIfAbsent(a.jobId, () => []).add(a);
  }
  final groups = byJob.entries.map((e) {
    final items = e.value;
    return ApplicantGroup(
      jobId: e.key,
      jobTitle: items.first.jobTitle,
      applicants: items,
    );
  }).toList();
  // Most recently active job first.
  groups.sort((a, b) {
    final aLatest = a.applicants
        .map((x) => x.updatedAt)
        .reduce((m, d) => d.isAfter(m) ? d : m);
    final bLatest = b.applicants
        .map((x) => x.updatedAt)
        .reduce((m, d) => d.isAfter(m) ? d : m);
    return bLatest.compareTo(aLatest);
  });
  return List.unmodifiable(groups);
});

/// Per-status counts for the applicants header.
class ApplicantsStats extends Equatable {
  const ApplicantsStats({
    this.total = 0,
    this.pending = 0,
    this.reviewed = 0,
    this.interview = 0,
    this.accepted = 0,
    this.rejected = 0,
  });

  final int total, pending, reviewed, interview, accepted, rejected;

  @override
  List<Object?> get props =>
      [total, pending, reviewed, interview, accepted, rejected];
}

final employerApplicantsStatsProvider = Provider<ApplicantsStats>((ref) {
  final apps = ref.watch(visibleApplicantsProvider);
  int by(ApplicationStatus s) => apps.where((a) => a.status == s).length;
  return ApplicantsStats(
    total: apps.length,
    pending: by(ApplicationStatus.pending),
    reviewed: by(ApplicationStatus.reviewed),
    interview: by(ApplicationStatus.interview),
    accepted: by(ApplicationStatus.accepted),
    rejected: by(ApplicationStatus.rejected),
  );
});

bool _matchesText(Application a, String text) {
  if (a.jobTitle.toLowerCase().contains(text)) return true;
  final snap = a.applicant;
  if (snap != null) {
    if (snap.name.toLowerCase().contains(text)) return true;
    if ((snap.headline ?? '').toLowerCase().contains(text)) return true;
    for (final s in snap.skills) {
      if (s.toLowerCase().contains(text)) return true;
    }
  }
  return false;
}

int Function(Application, Application) _comparator(ApplicantSort sort) {
  return switch (sort) {
    ApplicantSort.recent => (a, b) => b.updatedAt.compareTo(a.updatedAt),
    ApplicantSort.matchScore => (a, b) =>
        (b.applicant?.matchScore ?? -1).compareTo(a.applicant?.matchScore ?? -1),
    ApplicantSort.name => (a, b) => (a.applicant?.name ?? '')
        .toLowerCase()
        .compareTo((b.applicant?.name ?? '').toLowerCase()),
    ApplicantSort.status => (a, b) => a.status.index.compareTo(b.status.index),
  };
}
