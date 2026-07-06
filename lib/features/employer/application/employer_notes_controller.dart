import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/activity/employer_activity_repository.dart';
import '../../../core/services/notes/employer_notes_repository.dart';
import '../../../shared/models/application_note.dart';
import '../../../shared/models/employer_activity.dart';
import '../../auth/application/auth_providers.dart';

enum NotesActionFailure { permission, network, unknown }

/// Optimistic overlay for note CRUD: optimistically-[added] notes,
/// [overrides] (edits), [removedIds] (deletes), and in-flight [pending] ids.
/// On success the overlay entry is cleared (the stream is authoritative); on
/// failure it is cleared too (rollback) and [failure] set — the same strategy
/// as the applicant status actions and Employer Job Management.
class NotesActionState extends Equatable {
  const NotesActionState({
    this.added = const [],
    this.overrides = const {},
    this.removedIds = const {},
    this.pending = const {},
    this.failure,
  });

  final List<ApplicationNote> added;
  final Map<String, ApplicationNote> overrides;
  final Set<String> removedIds;
  final Set<String> pending;
  final NotesActionFailure? failure;

  bool isPending(String id) => pending.contains(id);

  NotesActionState copyWith({
    List<ApplicationNote>? added,
    Map<String, ApplicationNote>? overrides,
    Set<String>? removedIds,
    Set<String>? pending,
    NotesActionFailure? failure,
    bool clearFailure = false,
  }) =>
      NotesActionState(
        added: added ?? this.added,
        overrides: overrides ?? this.overrides,
        removedIds: removedIds ?? this.removedIds,
        pending: pending ?? this.pending,
        failure: clearFailure ? null : (failure ?? this.failure),
      );

  @override
  List<Object?> get props => [added, overrides, removedIds, pending, failure];
}

class EmployerNotesController extends StateNotifier<NotesActionState> {
  EmployerNotesController(this._ref, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now,
        super(const NotesActionState());

  final Ref _ref;
  final DateTime Function() _clock;
  int _seq = 0;

  String? get _uid => _ref.read(authRepositoryProvider).currentUser?.uid;
  EmployerNotesRepository get _repo =>
      _ref.read(employerNotesRepositoryProvider);
  EmployerActivityRepository get _activity =>
      _ref.read(employerActivityRepositoryProvider);

  Future<void> add(String applicationId, String text) async {
    final uid = _uid;
    final trimmed = text.trim();
    if (uid == null || trimmed.isEmpty) return;
    final now = _clock();
    final note = ApplicationNote(
      id: 'note_${now.microsecondsSinceEpoch}_${_seq++}',
      applicationId: applicationId,
      ownerUid: uid,
      authorUid: uid,
      text: trimmed,
      createdAt: now,
      updatedAt: now,
    );
    await _optimistic(note.id, add: note, call: () => _repo.addNote(note));
    if (state.failure == null) {
      _record(EmployerActivityType.noteAdded, applicationId, note.id);
    }
  }

  Future<void> edit(ApplicationNote note, String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || trimmed == note.text) return;
    final updated = note.copyWith(text: trimmed, updatedAt: _clock());
    await _optimistic(note.id,
        override: updated, call: () => _repo.updateNote(updated));
    if (state.failure == null) {
      _record(EmployerActivityType.noteEdited, note.applicationId, note.id);
    }
  }

  Future<void> delete(ApplicationNote note) async {
    await _optimistic(note.id,
        remove: true, call: () => _repo.deleteNote(note.id));
    if (state.failure == null) {
      _record(EmployerActivityType.noteDeleted, note.applicationId, note.id);
    }
  }

  Future<void> _optimistic(
    String id, {
    ApplicationNote? add,
    ApplicationNote? override,
    bool remove = false,
    required Future<void> Function() call,
  }) async {
    state = state.copyWith(
      pending: {...state.pending, id},
      added: add != null ? [...state.added, add] : state.added,
      overrides:
          override != null ? {...state.overrides, id: override} : state.overrides,
      removedIds: remove ? {...state.removedIds, id} : state.removedIds,
      clearFailure: true,
    );
    try {
      await call();
      state = _withCleared(id);
    } catch (e) {
      debugPrint('[Notes] action failed for $id: $e');
      state = _withCleared(id).copyWith(failure: _mapFailure(e));
    }
  }

  NotesActionState _withCleared(String id) => state.copyWith(
        pending: {...state.pending}..remove(id),
        added: state.added.where((n) => n.id != id).toList(),
        overrides: {...state.overrides}..remove(id),
        removedIds: {...state.removedIds}..remove(id),
      );

  void clearFailure() => state = state.copyWith(clearFailure: true);

  void _record(EmployerActivityType type, String applicationId, String noteId) {
    final uid = _uid;
    if (uid == null) return;
    final activity = EmployerActivity(
      id: 'act_${_clock().microsecondsSinceEpoch}_${_seq++}',
      ownerUid: uid,
      actorUid: uid,
      type: type,
      applicationId: applicationId,
      at: _clock(),
      targetId: noteId,
    );
    unawaited(_activity.log(activity).catchError((_) {}));
  }

  NotesActionFailure _mapFailure(Object e) {
    final m = e.toString().toLowerCase();
    if (m.contains('permission')) return NotesActionFailure.permission;
    if (m.contains('network') ||
        m.contains('unavailable') ||
        m.contains('timeout')) {
      return NotesActionFailure.network;
    }
    return NotesActionFailure.unknown;
  }
}

final employerNotesControllerProvider =
    StateNotifierProvider<EmployerNotesController, NotesActionState>(
  EmployerNotesController.new,
);

/// Notes for an application merged with the controller's optimistic overlay
/// (adds/edits/deletes), oldest-first.
final visibleNotesProvider =
    Provider.family<List<ApplicationNote>, String>((ref, applicationId) {
  final base =
      ref.watch(notesForApplicationProvider(applicationId)).valueOrNull ??
          const [];
  final action = ref.watch(employerNotesControllerProvider);

  final seen = <String>{};
  final out = <ApplicationNote>[];
  final optimisticAdds =
      action.added.where((n) => n.applicationId == applicationId);
  for (final n in [...optimisticAdds, ...base]) {
    if (action.removedIds.contains(n.id)) continue;
    if (!seen.add(n.id)) continue;
    out.add(action.overrides[n.id] ?? n);
  }
  out.sort((a, b) => a.createdAt.compareTo(b.createdAt));
  return List.unmodifiable(out);
});
