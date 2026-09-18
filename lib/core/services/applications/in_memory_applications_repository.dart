import 'dart:async';

import '../../../shared/models/application.dart';
import '../../../shared/models/job.dart';
import 'applications_repository.dart';

// The app-wide bindings (`applicationsRepositoryProvider`, `applicationsProvider`,
// `appliedJobIdsProvider`) now live in `applications_providers.dart`, where they
// bind the Firestore-backed implementation. They are re-exported here so every
// existing import of this file keeps resolving them unchanged. This class
// remains the in-memory implementation used by tests and as a swap target.
export 'applications_providers.dart';

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
