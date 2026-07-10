import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/applications/in_memory_applications_repository.dart';
import '../../../core/services/jobs/saved_jobs_store.dart';
import '../../../core/services/jobs/seed_jobs_repository.dart';
import '../../../shared/models/application.dart';
import '../../../shared/models/job.dart';

/// Search + status filter for the My Applications list.
class ApplicationsFilter extends Equatable {
  const ApplicationsFilter({
    this.text = '',
    this.statuses = const {},
    this.internshipsOnly = false,
  });

  final String text;
  final Set<ApplicationStatus> statuses;

  /// When true, show only internship applications.
  final bool internshipsOnly;

  bool get isActive =>
      text.trim().isNotEmpty || statuses.isNotEmpty || internshipsOnly;

  ApplicationsFilter copyWith({
    String? text,
    Set<ApplicationStatus>? statuses,
    bool? internshipsOnly,
  }) =>
      ApplicationsFilter(
        text: text ?? this.text,
        statuses: statuses ?? this.statuses,
        internshipsOnly: internshipsOnly ?? this.internshipsOnly,
      );

  @override
  List<Object?> get props => [text, statuses, internshipsOnly];
}

class ApplicationsFilterController extends StateNotifier<ApplicationsFilter> {
  ApplicationsFilterController() : super(const ApplicationsFilter());

  void updateText(String text) => state = state.copyWith(text: text);

  void toggleStatus(ApplicationStatus status) {
    final next = {...state.statuses};
    next.contains(status) ? next.remove(status) : next.add(status);
    state = state.copyWith(statuses: next);
  }

  void toggleInternshipsOnly() =>
      state = state.copyWith(internshipsOnly: !state.internshipsOnly);

  void clear() => state = const ApplicationsFilter();
}

final applicationsFilterProvider =
    StateNotifierProvider<ApplicationsFilterController, ApplicationsFilter>(
  (ref) => ApplicationsFilterController(),
);

/// Applications after applying the current [ApplicationsFilter], newest-first.
final filteredApplicationsProvider = Provider<List<Application>>((ref) {
  final all = ref.watch(applicationsProvider).valueOrNull ?? const [];
  final filter = ref.watch(applicationsFilterProvider);
  final text = filter.text.trim().toLowerCase();

  final list = all.where((a) {
    if (filter.internshipsOnly && !a.isInternship) return false;
    if (filter.statuses.isNotEmpty && !filter.statuses.contains(a.status)) {
      return false;
    }
    if (text.isNotEmpty &&
        !a.jobTitle.toLowerCase().contains(text) &&
        !a.company.toLowerCase().contains(text)) {
      return false;
    }
    return true;
  }).toList();

  list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  return List.unmodifiable(list);
});

/// Aggregate stats for the Applications Center header.
class ApplicationStats extends Equatable {
  const ApplicationStats({
    required this.applied,
    required this.saved,
    required this.interviews,
    required this.offers,
  });

  /// Total applications submitted.
  final int applied;

  /// Bookmarked (saved) jobs.
  final int saved;

  /// Applications that reached the interview stage (by history).
  final int interviews;

  /// Applications currently accepted (offers).
  final int offers;

  @override
  List<Object?> get props => [applied, saved, interviews, offers];
}

/// A single application by id (null if not found / withdrawn), derived from the
/// reactive applications list so the detail screen updates live.
final applicationByIdProvider = Provider.family<Application?, String>((ref, id) {
  final apps = ref.watch(applicationsProvider).valueOrNull ?? const [];
  for (final a in apps) {
    if (a.id == id) return a;
  }
  return null;
});

/// The user's saved (bookmarked) jobs, resolved from saved ids via the shared
/// jobs repository (a core service — no dependency on the Jobs feature).
final savedJobsListProvider = FutureProvider<List<Job>>((ref) async {
  final ids = ref.watch(savedJobsProvider);
  if (ids.isEmpty) return const [];
  final all = await ref.watch(jobsRepositoryProvider).fetchJobs();
  return all.where((j) => ids.contains(j.id)).toList(growable: false);
});

final applicationStatsProvider = Provider<ApplicationStats>((ref) {
  final apps = ref.watch(applicationsProvider).valueOrNull ?? const [];
  final saved = ref.watch(savedJobsProvider);

  final interviews = apps
      .where((a) => a.history.any((e) => e.status == ApplicationStatus.interview))
      .length;
  final offers =
      apps.where((a) => a.status == ApplicationStatus.accepted).length;

  return ApplicationStats(
    applied: apps.length,
    saved: saved.length,
    interviews: interviews,
    offers: offers,
  );
});
