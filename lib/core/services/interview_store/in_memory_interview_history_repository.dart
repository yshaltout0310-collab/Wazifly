import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/interview_prep/domain/interview_models.dart';
import 'interview_history_repository.dart';

/// Session-scoped [InterviewHistoryRepository]: keeps sessions in memory and
/// re-emits the full list on every change through a broadcast stream (mirroring
/// how Firestore `.snapshots()` re-emits). Swap the binding for a
/// `FirestoreInterviewHistoryRepository` later with no feature changes.
class InMemoryInterviewHistoryRepository implements InterviewHistoryRepository {
  InMemoryInterviewHistoryRepository({List<InterviewSession> seed = const []})
      : _items = [...seed];

  final List<InterviewSession> _items; // newest first
  final _controller = StreamController<List<InterviewSession>>.broadcast();

  List<InterviewSession> get _snapshot => List.unmodifiable(_items);

  void _emit() => _controller.add(_snapshot);

  @override
  Stream<List<InterviewSession>> watchSessions() async* {
    yield _snapshot; // current value to new listeners
    yield* _controller.stream;
  }

  @override
  Future<void> saveSession(InterviewSession session) async {
    final i = _items.indexWhere((s) => s.id == session.id);
    if (i == -1) {
      _items.insert(0, session); // newest first
    } else {
      _items[i] = session;
    }
    _emit();
  }

  @override
  Future<InterviewSession?> findById(String id) async {
    final i = _items.indexWhere((s) => s.id == id);
    return i == -1 ? null : _items[i];
  }

  @override
  Future<void> delete(String id) async {
    _items.removeWhere((s) => s.id == id);
    _emit();
  }
}

/// The app-wide interview history repository (swap this binding for Firestore
/// `users/{uid}/interviews` later — no feature changes).
final interviewHistoryRepositoryProvider =
    Provider<InterviewHistoryRepository>(
  (ref) => InMemoryInterviewHistoryRepository(),
);

/// Reactive view of all past interview sessions (maps to a Firestore snapshot
/// stream), consumed by the history screen.
final interviewSessionsProvider = StreamProvider<List<InterviewSession>>(
  (ref) => ref.watch(interviewHistoryRepositoryProvider).watchSessions(),
);
