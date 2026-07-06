import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/jobs/employer_jobs_repository.dart';
import '../../../shared/models/job_posting.dart';
import '../../auth/application/auth_providers.dart';
import '../domain/job_status.dart';

/// UI-facing failure categories for lifecycle actions.
enum JobsActionFailure { permission, network, unknown }

/// The optimistic overlay applied on top of the authoritative `employerJobsProvider`
/// stream: status overrides, optimistically-removed (soft-deleted) ids, and
/// optimistically-added (duplicated) drafts, plus in-flight [pending] ids.
///
/// On a successful repository write the overlay entry is cleared (the stream is
/// now authoritative); on failure it is cleared too — reverting to the stream's
/// last value (rollback) — and [failure] is surfaced.
class EmployerJobsActionState extends Equatable {
  const EmployerJobsActionState({
    this.overrides = const {},
    this.removedIds = const {},
    this.added = const [],
    this.pending = const {},
    this.failure,
  });

  final Map<String, JobPosting> overrides;
  final Set<String> removedIds;
  final List<JobPosting> added;
  final Set<String> pending;
  final JobsActionFailure? failure;

  bool isPending(String id) => pending.contains(id);

  EmployerJobsActionState copyWith({
    Map<String, JobPosting>? overrides,
    Set<String>? removedIds,
    List<JobPosting>? added,
    Set<String>? pending,
    JobsActionFailure? failure,
    bool clearFailure = false,
  }) =>
      EmployerJobsActionState(
        overrides: overrides ?? this.overrides,
        removedIds: removedIds ?? this.removedIds,
        added: added ?? this.added,
        pending: pending ?? this.pending,
        failure: clearFailure ? null : (failure ?? this.failure),
      );

  @override
  List<Object?> get props => [overrides, removedIds, added, pending, failure];
}

/// Drives the job lifecycle actions (publish / archive / close / reopen /
/// duplicate / soft-delete) with **optimistic UI + rollback**, staying fully
/// repository-driven. Status transitions are computed by the pure [JobPosting]
/// model, then persisted via the [EmployerJobsRepository].
class EmployerJobsController extends StateNotifier<EmployerJobsActionState> {
  EmployerJobsController(this._ref, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now,
        super(const EmployerJobsActionState());

  final Ref _ref;
  final DateTime Function() _clock;
  int _seq = 0;

  String? get _uid => _ref.read(authRepositoryProvider).currentUser?.uid;
  EmployerJobsRepository get _repo =>
      _ref.read(employerJobsRepositoryProvider);

  Future<void> publish(JobPosting job) =>
      _transition(job, JobStatus.published);
  Future<void> close(JobPosting job) => _transition(job, JobStatus.closed);
  Future<void> reopen(JobPosting job) => _transition(job, JobStatus.published);
  Future<void> archive(JobPosting job, {String? reason}) =>
      _transition(job, JobStatus.archived, reason: reason);

  Future<void> _transition(JobPosting job, JobStatus next, {String? reason}) {
    if (!job.status.canTransitionTo(next)) return Future.value();
    final updated =
        job.withStatus(next, at: _clock(), by: _uid, reason: reason);
    return _optimistic(job.id,
        override: updated, call: () => _repo.updateJob(updated));
  }

  /// Soft-deletes: retains the document (applications/analytics/audit intact),
  /// optimistically removes it from the list.
  Future<void> softDelete(JobPosting job) {
    final updated = job.softDeleted(at: _clock(), by: _uid);
    return _optimistic(job.id,
        remove: true, call: () => _repo.updateJob(updated));
  }

  /// Duplicates into a fresh draft, optimistically prepended to the list.
  Future<JobPosting> duplicate(JobPosting job) async {
    final id = 'job_${_clock().microsecondsSinceEpoch}_${_seq++}';
    final copy = job.duplicated(id: id, now: _clock(), by: _uid);
    await _optimistic(id, add: copy, call: () => _repo.createJob(copy));
    return copy;
  }

  Future<void> _optimistic(
    String id, {
    JobPosting? override,
    bool remove = false,
    JobPosting? add,
    required Future<void> Function() call,
  }) async {
    state = state.copyWith(
      pending: {...state.pending, id},
      overrides:
          override != null ? {...state.overrides, id: override} : state.overrides,
      removedIds: remove ? {...state.removedIds, id} : state.removedIds,
      added: add != null ? [add, ...state.added] : state.added,
      clearFailure: true,
    );
    try {
      await call();
      state = _withCleared(id);
    } catch (e) {
      debugPrint('[EmployerJobs] action failed for $id: $e');
      state = _withCleared(id).copyWith(failure: _mapFailure(e));
    }
  }

  /// Clears the overlay entry for [id] (the stream is now authoritative, or we
  /// are rolling back on failure).
  EmployerJobsActionState _withCleared(String id) => state.copyWith(
        pending: {...state.pending}..remove(id),
        overrides: {...state.overrides}..remove(id),
        removedIds: {...state.removedIds}..remove(id),
        added: state.added.where((j) => j.id != id).toList(),
      );

  void clearFailure() => state = state.copyWith(clearFailure: true);

  JobsActionFailure _mapFailure(Object e) {
    final m = e.toString().toLowerCase();
    if (m.contains('permission')) return JobsActionFailure.permission;
    if (m.contains('network') ||
        m.contains('unavailable') ||
        m.contains('timeout')) {
      return JobsActionFailure.network;
    }
    return JobsActionFailure.unknown;
  }
}

final employerJobsControllerProvider =
    StateNotifierProvider<EmployerJobsController, EmployerJobsActionState>(
  EmployerJobsController.new,
);
