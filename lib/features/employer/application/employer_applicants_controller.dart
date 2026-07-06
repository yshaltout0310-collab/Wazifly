import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/activity/employer_activity_repository.dart';
import '../../../core/services/applications/employer_applicants_repository.dart';
import '../../../shared/models/application.dart';
import '../../../shared/models/employer_activity.dart';
import '../../auth/application/auth_providers.dart';
import '../domain/applicant_status_flow.dart';

/// UI-facing failure categories for applicant actions.
enum ApplicantsActionFailure { permission, network, unknown }

/// Optimistic overlay for applicant status actions: per-id status overrides +
/// in-flight [pending] ids. On success the entry is cleared (the stream is
/// authoritative); on failure it is cleared too (rollback) and [failure] set.
class ApplicantsActionState extends Equatable {
  const ApplicantsActionState({
    this.overrides = const {},
    this.pending = const {},
    this.failure,
  });

  final Map<String, Application> overrides;
  final Set<String> pending;
  final ApplicantsActionFailure? failure;

  bool isPending(String id) => pending.contains(id);

  ApplicantsActionState copyWith({
    Map<String, Application>? overrides,
    Set<String>? pending,
    ApplicantsActionFailure? failure,
    bool clearFailure = false,
  }) =>
      ApplicantsActionState(
        overrides: overrides ?? this.overrides,
        pending: pending ?? this.pending,
        failure: clearFailure ? null : (failure ?? this.failure),
      );

  @override
  List<Object?> get props => [overrides, pending, failure];
}

/// Drives applicant lifecycle actions (Move to Review / Interview / Accept /
/// Reject / Reopen) with **optimistic UI + rollback**, mirroring
/// `EmployerJobsController`. Transitions are computed by the pure model
/// ([Application.withStatus] appends history) and gated by [ApplicantStatusFlow].
/// Significant actions are also recorded to the employer activity log
/// (fire-and-forget; a logging failure never breaks the action).
class EmployerApplicantsController extends StateNotifier<ApplicantsActionState> {
  EmployerApplicantsController(this._ref, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now,
        super(const ApplicantsActionState());

  final Ref _ref;
  final DateTime Function() _clock;
  int _seq = 0;

  String? get _uid => _ref.read(authRepositoryProvider).currentUser?.uid;
  EmployerApplicantsRepository get _repo =>
      _ref.read(employerApplicantsRepositoryProvider);
  EmployerActivityRepository get _activity =>
      _ref.read(employerActivityRepositoryProvider);

  Future<void> moveToReview(Application a) =>
      _transition(a, ApplicationStatus.reviewed, EmployerActivityType.statusReview);
  Future<void> moveToInterview(Application a) => _transition(
      a, ApplicationStatus.interview, EmployerActivityType.statusInterview);
  Future<void> accept(Application a) =>
      _transition(a, ApplicationStatus.accepted, EmployerActivityType.statusAccept);
  Future<void> reject(Application a, {String? reason}) => _transition(
      a, ApplicationStatus.rejected, EmployerActivityType.statusReject,
      note: reason);
  Future<void> reopen(Application a) =>
      _transition(a, ApplicationStatus.reviewed, EmployerActivityType.statusReopen);

  Future<void> _transition(
    Application app,
    ApplicationStatus next,
    EmployerActivityType activityType, {
    String? note,
  }) async {
    if (!app.status.canMoveTo(next)) return;
    final from = app.status;
    final updated = app.withStatus(next, _clock(),
        by: _uid, note: (note ?? '').trim().isEmpty ? null : note!.trim());
    await _optimistic(app.id, updated, () => _repo.updateApplication(updated));
    if (state.failure == null) {
      _record(activityType, app.id, from: from.name, to: next.name);
    }
  }

  Future<void> _optimistic(
    String id,
    Application override,
    Future<void> Function() call,
  ) async {
    state = state.copyWith(
      pending: {...state.pending, id},
      overrides: {...state.overrides, id: override},
      clearFailure: true,
    );
    try {
      await call();
      state = _withCleared(id);
    } catch (e) {
      debugPrint('[Applicants] action failed for $id: $e');
      state = _withCleared(id).copyWith(failure: _mapFailure(e));
    }
  }

  ApplicantsActionState _withCleared(String id) => state.copyWith(
        pending: {...state.pending}..remove(id),
        overrides: {...state.overrides}..remove(id),
      );

  void clearFailure() => state = state.copyWith(clearFailure: true);

  /// Fire-and-forget activity record — never throws into the caller.
  void _record(EmployerActivityType type, String applicationId,
      {String? from, String? to, String? targetId}) {
    final uid = _uid;
    if (uid == null) return;
    final activity = EmployerActivity(
      id: 'act_${_clock().microsecondsSinceEpoch}_${_seq++}',
      ownerUid: uid,
      actorUid: uid,
      type: type,
      applicationId: applicationId,
      at: _clock(),
      from: from,
      to: to,
      targetId: targetId,
    );
    unawaited(_activity.log(activity).catchError((_) {}));
  }

  ApplicantsActionFailure _mapFailure(Object e) {
    final m = e.toString().toLowerCase();
    if (m.contains('permission')) return ApplicantsActionFailure.permission;
    if (m.contains('network') ||
        m.contains('unavailable') ||
        m.contains('timeout')) {
      return ApplicantsActionFailure.network;
    }
    return ApplicantsActionFailure.unknown;
  }
}

final employerApplicantsControllerProvider =
    StateNotifierProvider<EmployerApplicantsController, ApplicantsActionState>(
  EmployerApplicantsController.new,
);
