import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../shared/models/applicant_snapshot.dart';
import '../../../shared/models/application.dart';
import '../../../shared/models/job.dart';
import '../firebase/firebase_service.dart';
import '../firebase/firestore_stream.dart';
import '../security/security_audit_log.dart';
import 'applications_repository.dart';

/// Firestore-backed [ApplicationsRepository] — the seeker's half of the
/// `applications` collection, and the production path.
///
/// This is the write side of the marketplace loop. The employer's
/// `FirestoreEmployerApplicantsRepository` already reads the same collection by
/// `ownerUid`, so an application created here shows up in the owning employer's
/// applicant list and analytics with **no employer-side change at all** — the
/// two sides were always designed around one collection and one [Application]
/// model; only the seeker's store was in memory.
///
/// **Duplicate prevention.** The document id is derived deterministically from
/// `(applicantUid, jobId)`, so a second application to the same job is the same
/// document — impossible to duplicate even across devices or a lost stream.
/// This also makes [findByJobId] a single document read rather than a query, so
/// no composite index is needed.
///
/// **Identity.** `applicantUid` is taken from the signed-in user, never from
/// caller input, and the security rules independently require it to equal
/// `request.auth.uid` — a client cannot file an application as somebody else.
/// `ownerUid`/`companyId` come from the job's own projection, and the rules
/// verify them against the referenced job document.
///
/// Degrades gracefully: unconfigured Firebase or a signed-out user makes reads
/// emit empty and writes no-op, exactly like the other Firestore repositories.
class FirestoreApplicationsRepository implements ApplicationsRepository {
  FirestoreApplicationsRepository({
    required this.applicantUid,
    this.snapshotBuilder,
    this.applicantName = '',
    FirebaseFirestore? firestore,
    SecurityAuditLog? audit,
    DateTime Function()? clock,
  })  : _firestore = firestore,
        _audit = audit,
        _clock = clock ?? DateTime.now;

  /// The signed-in seeker, or null when signed out.
  final String? applicantUid;

  /// Supplies the denormalized applicant snapshot at apply time. Injected (not
  /// read from Riverpod here) so this repository stays free of provider
  /// dependencies and is trivially testable.
  final ApplicantSnapshot Function()? snapshotBuilder;

  /// Fallback display name when no profile snapshot is available.
  final String applicantName;

  final FirebaseFirestore? _firestore;
  final SecurityAuditLog? _audit;
  final DateTime Function() _clock;

  static const String _collection = 'applications';

  /// Runaway guard on the seeker's own history (sort runs in Dart).
  static const int maxDocs = 300;

  bool get _ready => FirebaseService.instance.isReady && _uid != null;

  String? get _uid {
    final uid = applicantUid?.trim();
    return (uid == null || uid.isEmpty) ? null : uid;
  }

  CollectionReference<Map<String, dynamic>> get _apps =>
      (_firestore ?? FirebaseFirestore.instance).collection(_collection);

  /// Stable per-(applicant, job) document id.
  ///
  /// Firestore forbids `/` in a document id and rejects ids over 1500 bytes, so
  /// the job id is sanitized and bounded. The mapping stays deterministic, which
  /// is the property duplicate-prevention relies on.
  @visibleForTesting
  static String documentIdFor(String applicantUid, String jobId) {
    final safeJob = jobId
        .trim()
        .replaceAll(RegExp(r'[^A-Za-z0-9_\-.]'), '_');
    final id = '${applicantUid}__$safeJob';
    return id.length <= 300 ? id : id.substring(0, 300);
  }

  @override
  Stream<List<Application>> watchApplications() {
    final uid = _uid;
    if (!FirebaseService.instance.isReady || uid == null) {
      return Stream<List<Application>>.value(const []);
    }
    return _apps
        .where('applicantUid', isEqualTo: uid)
        .limit(maxDocs)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => Application.fromJson({...d.data(), 'id': d.id}))
          .toList();
      list.sort((a, b) => b.appliedAt.compareTo(a.appliedAt)); // newest first
      return list;
    }).logAndForwardErrors('Applications.watchApplications',
        onError: (e) => _auditDenied(e, 'applications_read'));
  }

  @override
  Future<Application> apply({
    required Job job,
    String cvId = '',
    String cvName = '',
  }) async {
    final uid = _uid;
    final now = _clock();

    final application = Application.create(
      id: uid == null ? 'local_${job.id}' : documentIdFor(uid, job.id),
      job: job,
      now: now,
      applicantUid: uid ?? '',
      // Projected from the job itself, so the application is addressed to the
      // employer that actually owns the posting. Empty for the demo catalogue,
      // which has no employer behind it.
      ownerUid: job.ownerUid,
      companyId: job.companyId,
      companyName: job.company,
      applicant: snapshotBuilder?.call() ??
          (applicantName.isEmpty
              ? null
              : ApplicantSnapshot(name: applicantName)),
      cvId: cvId,
      cvName: cvName,
    );

    if (!_ready) return application;

    // Idempotent per (applicant, job): an existing application wins unchanged,
    // which is the same contract the in-memory store honoured.
    final existing = await findByJobId(job.id);
    if (existing != null) return existing;

    try {
      final data = application.toJson()..remove('id');
      await _apps.doc(application.id).set(data);
    } on FirebaseException catch (e) {
      // Overwriting an existing application is an *update* as far as the rules
      // are concerned, and updates are employer-only — deliberately, so an
      // applicant cannot rewrite their snapshot or status after review starts.
      // So a denial here can simply mean "already applied" when the read above
      // missed it: a stale offline cache, or a second device racing this one.
      // Re-read before surfacing an error, and honour idempotency if it's there.
      if (e.code == 'permission-denied') {
        final raced = await findByJobId(job.id);
        if (raced != null) return raced;
      }
      debugPrint('[Applications] apply failed: $e');
      _auditDenied(e, 'application_create');
      rethrow; // the caller surfaces the failure; nothing silently "succeeds"
    } catch (e) {
      debugPrint('[Applications] apply failed: $e');
      rethrow;
    }
    return application;
  }

  @override
  Future<Application?> findByJobId(String jobId) async {
    final uid = _uid;
    if (!_ready || uid == null) return null;
    try {
      final id = documentIdFor(uid, jobId);
      final snap = await _apps.doc(id).get();
      final data = snap.data();
      if (data == null) return null;
      return Application.fromJson({...data, 'id': snap.id});
    } catch (e) {
      debugPrint('[Applications] findByJobId failed: $e');
      return null;
    }
  }

  /// Status is **employer-controlled**: the security rules allow an update only
  /// from the job's owner, so a seeker-initiated call is expected to be denied
  /// and is swallowed rather than crashing the UI. The `.snapshots()` stream
  /// stays authoritative and simply keeps showing the real status.
  @override
  Future<void> updateStatus(String id, ApplicationStatus status) async {
    if (!_ready) return;
    try {
      await _apps.doc(id).update({
        'status': status.name,
        'updatedAt': _clock().toIso8601String(),
      });
    } catch (e) {
      debugPrint('[Applications] updateStatus denied/failed: $e');
      _auditDenied(e, 'application_status_update');
    }
  }

  /// Withdrawal — the one mutation an applicant owns. The rules allow a delete
  /// only when `applicantUid == request.auth.uid`.
  @override
  Future<void> withdraw(String id) async {
    if (!_ready) return;
    try {
      await _apps.doc(id).delete();
    } catch (e) {
      debugPrint('[Applications] withdraw failed: $e');
      _auditDenied(e, 'application_withdraw');
      rethrow;
    }
  }

  void _auditDenied(Object e, String detail) {
    if (_audit != null &&
        e is FirebaseException &&
        e.code == 'permission-denied') {
      _audit.record(SecurityEventType.permissionDenied, detail: detail);
    }
  }
}
