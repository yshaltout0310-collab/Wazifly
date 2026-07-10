import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/application.dart';
import '../../../shared/models/job.dart';
import 'applications_repository.dart';

/// Session-scoped [ApplicationsRepository]: keeps applications in memory and
/// pushes the full list on every change through a broadcast stream (mirroring
/// how Firestore `.snapshots()` re-emits). Swap the binding for a
/// `FirestoreApplicationsRepository` later with no feature changes.
class InMemoryApplicationsRepository implements ApplicationsRepository {
  InMemoryApplicationsRepository({DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  /// Injectable so tests get deterministic timestamps and the real backend can
  /// use server time.
  final DateTime Function() _clock;

  final List<Application> _items = [];
  final _controller = StreamController<List<Application>>.broadcast();
  int _seq = 0;

  List<Application> get _snapshot => List.unmodifiable(_items);

  void _emit() => _controller.add(_snapshot);

  @override
  Stream<List<Application>> watchApplications() async* {
    yield _snapshot; // current value to new listeners
    yield* _controller.stream;
  }

  @override
  Future<Application> apply({
    required Job job,
    String cvId = '',
    String cvName = '',
  }) async {
    final existing = _indexOfJob(job.id);
    if (existing != -1) return _items[existing];
    final app = Application.create(
      id: 'app_${_seq++}',
      job: job,
      now: _clock(),
      cvId: cvId,
      cvName: cvName,
    );
    _items.insert(0, app); // newest first
    _emit();
    return app;
  }

  @override
  Future<void> updateStatus(String id, ApplicationStatus status) async {
    final i = _indexOfId(id);
    if (i == -1) return;
    if (_items[i].status == status) return;
    _items[i] = _items[i].withStatus(status, _clock());
    _emit();
  }

  @override
  Future<void> withdraw(String id) async {
    final i = _indexOfId(id);
    if (i == -1) return;
    _items.removeAt(i);
    _emit();
  }

  @override
  Future<Application?> findByJobId(String jobId) async {
    final i = _indexOfJob(jobId);
    return i == -1 ? null : _items[i];
  }

  int _indexOfId(String id) => _items.indexWhere((a) => a.id == id);
  int _indexOfJob(String jobId) => _items.indexWhere((a) => a.jobId == jobId);
}

/// The app-wide applications repository (swap this binding for Firestore later).
final applicationsRepositoryProvider = Provider<ApplicationsRepository>(
  (ref) => InMemoryApplicationsRepository(),
);

/// Reactive view of all applications (maps to a Firestore snapshot stream).
final applicationsProvider = StreamProvider<List<Application>>(
  (ref) => ref.watch(applicationsRepositoryProvider).watchApplications(),
);

/// Job ids the user has applied to — derived so "applied" has a single source
/// of truth (the applications), consumed by the Jobs platform's badges.
final appliedJobIdsProvider = Provider<Set<String>>((ref) {
  final apps = ref.watch(applicationsProvider).valueOrNull ?? const [];
  return {for (final a in apps) a.jobId};
});
