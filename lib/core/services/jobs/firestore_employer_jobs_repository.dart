import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../shared/models/job_posting.dart';
import '../firebase/firebase_service.dart';
import '../security/security_audit_log.dart';
import 'employer_jobs_repository.dart';

/// Firestore-backed [EmployerJobsRepository] — the production path.
///
/// Degrades gracefully when Firebase isn't configured (reads emit empty, writes
/// no-op). Queries by `ownerUid` (equality — no composite index needed) so the
/// list matches the Firestore security rule's owner clause exactly (a query on a
/// different field would be denied, since rules can't prove `companyId == uid`);
/// soft-delete filtering + sort run in Dart. Mirrors `FirestoreCompanyRepository`.
/// `companyId == ownerUid` in this milestone, so results are identical.
class FirestoreEmployerJobsRepository implements EmployerJobsRepository {
  FirestoreEmployerJobsRepository([FirebaseFirestore? firestore, this._audit])
      : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  /// Optional audit trail — records a rules rejection so denied traffic is
  /// observable in production (best-effort; null in tests).
  final SecurityAuditLog? _audit;

  static const String _collection = 'jobs';

  /// Runaway guard: never stream more than this many docs (seed scale is tiny;
  /// this only bounds a pathological owner). Sort still runs in Dart.
  static const int _maxDocs = 300;

  bool get _ready => FirebaseService.instance.isReady;

  CollectionReference<Map<String, dynamic>> get _jobs =>
      (_firestore ?? FirebaseFirestore.instance).collection(_collection);

  @override
  Stream<List<JobPosting>> watchJobs(String companyId) {
    if (!_ready) return Stream<List<JobPosting>>.value(const []);
    // Filter by ownerUid (== companyId here) to match the security rule's owner
    // clause, so the list query is authorized rather than permission-denied.
    return _jobs
        .where('ownerUid', isEqualTo: companyId)
        .limit(_maxDocs)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => JobPosting.fromJson({...d.data(), 'id': d.id}))
          .where((j) => !j.isDeleted)
          .toList();
      list.sort((a, b) => (b.updatedAt ?? _epoch).compareTo(a.updatedAt ?? _epoch));
      return list;
    }).handleError((Object e) {
      debugPrint('[EmployerJobs] watchJobs failed: $e');
      _auditDenied(e);
    });
  }

  @override
  Future<JobPosting?> fetchJob(String id) async {
    if (!_ready) return null;
    try {
      final snap = await _jobs.doc(id).get();
      final data = snap.data();
      if (data == null) return null;
      return JobPosting.fromJson({...data, 'id': id});
    } catch (e) {
      debugPrint('[EmployerJobs] fetchJob failed: $e');
      return null;
    }
  }

  // NOTE: writes rethrow on failure (unlike the M1 company repo, which swallows)
  // so the controllers can roll back optimistic UI updates. `.snapshots()` also
  // rolls the local pending write back on a rejected write, keeping the stream
  // authoritative.

  @override
  Future<JobPosting> createJob(JobPosting posting) async {
    if (!_ready) return posting;
    final data = posting.toJson()
      ..remove('id')
      ..['createdAt'] = FieldValue.serverTimestamp()
      ..['updatedAt'] = FieldValue.serverTimestamp();
    await _jobs.doc(posting.id).set(data);
    return posting;
  }

  @override
  Future<void> updateJob(JobPosting posting) async {
    if (!_ready) return;
    final data = posting.toJson()
      ..remove('id')
      ..['updatedAt'] = FieldValue.serverTimestamp();
    await _jobs.doc(posting.id).set(data, SetOptions(merge: true));
  }

  /// Records a permission-denied read to the security audit log (best-effort).
  void _auditDenied(Object e) {
    if (_audit != null &&
        e is FirebaseException &&
        e.code == 'permission-denied') {
      _audit.record(SecurityEventType.permissionDenied, detail: 'jobs_read');
    }
  }
}

final DateTime _epoch = DateTime.fromMillisecondsSinceEpoch(0);
