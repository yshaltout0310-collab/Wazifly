import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../shared/models/application.dart';
import '../firebase/firebase_service.dart';
import '../security/security_audit_log.dart';
import 'employer_applicants_repository.dart';

/// Firestore-backed [EmployerApplicantsRepository] — the production path.
///
/// Degrades gracefully when Firebase isn't configured (reads emit empty, writes
/// no-op). Queries by `ownerUid` (equality — no composite index) so the list
/// matches the security rule's owner clause exactly (a query on any other field
/// would be denied). Sort runs in Dart. Writes **rethrow** so the optimistic
/// controller can roll back. Mirrors `FirestoreEmployerJobsRepository`.
class FirestoreEmployerApplicantsRepository
    implements EmployerApplicantsRepository {
  FirestoreEmployerApplicantsRepository([FirebaseFirestore? firestore, this._audit])
      : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  /// Optional audit trail — records a rules rejection (best-effort; null in tests).
  final SecurityAuditLog? _audit;

  static const String _collection = 'applications';

  /// Runaway guard: cap the stream (seed scale is tiny). Sort still runs in Dart.
  static const int _maxDocs = 300;

  bool get _ready => FirebaseService.instance.isReady;

  CollectionReference<Map<String, dynamic>> get _apps =>
      (_firestore ?? FirebaseFirestore.instance).collection(_collection);

  @override
  Stream<List<Application>> watchApplicants(String ownerUid) {
    if (!_ready) return Stream<List<Application>>.value(const []);
    return _apps
        .where('ownerUid', isEqualTo: ownerUid)
        .limit(_maxDocs)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => Application.fromJson({...d.data(), 'id': d.id}))
          .toList();
      list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return list;
    }).handleError((Object e) {
      debugPrint('[EmployerApplicants] watch failed: $e');
      if (_audit != null &&
          e is FirebaseException &&
          e.code == 'permission-denied') {
        _audit.record(SecurityEventType.permissionDenied,
            detail: 'applications_read');
      }
    });
  }

  @override
  Future<Application?> fetchApplicant(String id) async {
    if (!_ready) return null;
    try {
      final snap = await _apps.doc(id).get();
      final data = snap.data();
      if (data == null) return null;
      return Application.fromJson({...data, 'id': id});
    } catch (e) {
      debugPrint('[EmployerApplicants] fetch failed: $e');
      return null;
    }
  }

  @override
  Future<void> updateApplication(Application application) async {
    if (!_ready) return;
    // Persist the model's own updatedAt (client clock) so the authoritative doc
    // orders identically to the optimistic overlay (no reorder flicker). Merge
    // keeps applicantUid/ownerUid intact (the rule checks the existing ownerUid).
    final data = application.toJson()..remove('id');
    await _apps.doc(application.id).set(data, SetOptions(merge: true));
  }
}
