import 'dart:async';

import '../../../shared/models/job_posting.dart';
import 'employer_jobs_repository.dart';

/// Session-scoped [EmployerJobsRepository] for tests and offline runs.
///
/// Holds postings in memory keyed by id, and re-emits a company's live
/// (non-deleted, newest-first) list on every change through a per-company
/// broadcast stream (mirroring Firestore `.snapshots()`).
class InMemoryEmployerJobsRepository implements EmployerJobsRepository {
  InMemoryEmployerJobsRepository({List<JobPosting> seed = const []}) {
    for (final j in seed) {
      _jobs[j.id] = j;
    }
  }

  final Map<String, JobPosting> _jobs = {};
  final Map<String, StreamController<List<JobPosting>>> _controllers = {};

  StreamController<List<JobPosting>> _controllerFor(String companyId) =>
      _controllers.putIfAbsent(
        companyId,
        () => StreamController<List<JobPosting>>.broadcast(),
      );

  List<JobPosting> _snapshot(String companyId) {
    final list = _jobs.values
        .where((j) => j.companyId == companyId && !j.isDeleted)
        .toList();
    list.sort((a, b) => (b.updatedAt ?? _epoch).compareTo(a.updatedAt ?? _epoch));
    return List.unmodifiable(list);
  }

  void _emit(String companyId) =>
      _controllerFor(companyId).add(_snapshot(companyId));

  @override
  Stream<List<JobPosting>> watchJobs(String companyId) async* {
    yield _snapshot(companyId);
    yield* _controllerFor(companyId).stream;
  }

  @override
  Future<JobPosting?> fetchJob(String id) async => _jobs[id];

  @override
  Future<JobPosting> createJob(JobPosting posting) async {
    _jobs[posting.id] = posting;
    _emit(posting.companyId);
    return posting;
  }

  @override
  Future<void> updateJob(JobPosting posting) async {
    _jobs[posting.id] = posting;
    _emit(posting.companyId);
  }
}

final DateTime _epoch = DateTime.fromMillisecondsSinceEpoch(0);
