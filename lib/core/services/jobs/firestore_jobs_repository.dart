import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../shared/models/job.dart';
import '../../../shared/models/job_posting.dart';
import '../firebase/firebase_service.dart';
import '../security/security_audit_log.dart';
import 'job_query_filter.dart';
import 'jobs_repository.dart';

/// Seeker-facing [JobsRepository] backed by the live `jobs` collection — the
/// production marketplace source.
///
/// This is the other half of the employer's `FirestoreEmployerJobsRepository`:
/// the employer writes `JobPosting` documents, and this reads the **published**
/// ones back and projects them through [JobPosting.toJob] into the public [Job]
/// the seeker UI already renders. Reuse by projection, not duplication — there
/// is no second schema.
///
/// **Query shape.** Exactly one equality clause, `status == 'published'`, and no
/// `orderBy`. That is deliberate:
///
/// * It mirrors the `jobs` security rule (`resource.data.status == 'published'
///   || ownerUid == uid`) so a seeker's list read is *authorized* rather than
///   permission-denied.
/// * A single-field equality needs only Firestore's automatic index — adding an
///   `orderBy` on a different field would require a composite index per filter
///   combination. Sorting and all filtering therefore run in Dart, matching the
///   discipline already used by the CV, company and employer-jobs repositories.
///
/// Degrades gracefully: when Firebase is unconfigured, or the read is denied, or
/// the device is offline with a cold cache, reads emit an empty list rather than
/// throwing — the composing repository then falls back to the bundled catalogue.
class FirestoreJobsRepository implements JobsRepository {
  FirestoreJobsRepository([FirebaseFirestore? firestore, this._audit])
      : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  /// Optional audit trail — records a rules rejection so denied traffic is
  /// observable in production (best-effort; null in tests).
  final SecurityAuditLog? _audit;

  static const String _collection = 'jobs';

  /// Runaway guard on the public catalogue read. Filtering/sorting run in Dart
  /// over this page.
  static const int maxDocs = 300;

  /// The status a posting must carry to be publicly visible. Matches
  /// `JobStatus.published.name` and the security rule's literal.
  static const String publishedStatus = 'published';

  bool get _ready => FirebaseService.instance.isReady;

  CollectionReference<Map<String, dynamic>> get _jobs =>
      (_firestore ?? FirebaseFirestore.instance).collection(_collection);

  @override
  Future<List<Job>> fetchJobs() async {
    if (!_ready) return const [];
    try {
      final snap = await _jobs
          .where('status', isEqualTo: publishedStatus)
          .limit(maxDocs)
          .get();
      return _project(snap.docs);
    } catch (e) {
      debugPrint('[Jobs] fetchJobs failed: $e');
      _auditDenied(e);
      return const [];
    }
  }

  @override
  Future<Job?> fetchJobById(String id) async {
    if (!_ready || id.trim().isEmpty) return null;
    try {
      final snap = await _jobs.doc(id).get();
      final data = snap.data();
      if (data == null) return null;
      final posting = JobPosting.fromJson({...data, 'id': snap.id});
      // A draft/archived/closed or soft-deleted posting is not public, even
      // when its id is known.
      if (!posting.isLive) return null;
      return posting.toJob();
    } catch (e) {
      debugPrint('[Jobs] fetchJobById failed: $e');
      _auditDenied(e);
      return null;
    }
  }

  @override
  Future<List<Job>> searchJobs(JobQuery query) async =>
      applyJobQuery(await fetchJobs(), query);

  /// Maps raw documents to public jobs: drop soft-deleted postings, newest
  /// first. `publishedAt` is the seeker-meaningful ordering key.
  List<Job> _project(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final postings = docs
        .map((d) => JobPosting.fromJson({...d.data(), 'id': d.id}))
        .where((p) => p.isLive)
        .toList();
    postings.sort((a, b) =>
        (b.publishedAt ?? _epoch).compareTo(a.publishedAt ?? _epoch));
    return postings.map((p) => p.toJob()).toList(growable: false);
  }

  void _auditDenied(Object e) {
    if (_audit != null &&
        e is FirebaseException &&
        e.code == 'permission-denied') {
      _audit.record(SecurityEventType.permissionDenied,
          detail: 'public_jobs_read');
    }
  }
}

final DateTime _epoch = DateTime.fromMillisecondsSinceEpoch(0);
