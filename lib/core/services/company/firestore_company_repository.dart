import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../shared/models/company.dart';
import '../firebase/firebase_service.dart';
import 'company_repository.dart';

/// Firestore-backed [CompanyRepository] — the production path.
///
/// Every method degrades gracefully when Firebase isn't configured (reads emit
/// null, writes no-op), so calling code never branches on backend availability.
/// Mirrors `FirestoreUserProfileRepository`.
class FirestoreCompanyRepository implements CompanyRepository {
  FirestoreCompanyRepository([FirebaseFirestore? firestore])
      : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  static const String _collection = 'companies';

  bool get _ready => FirebaseService.instance.isReady;

  CollectionReference<Map<String, dynamic>> get _companies =>
      (_firestore ?? FirebaseFirestore.instance).collection(_collection);

  @override
  Stream<Company?> watchCompany(String companyId) {
    if (!_ready) return Stream<Company?>.value(null);
    return _companies.doc(companyId).snapshots().map((snap) {
      final data = snap.data();
      if (data == null) return null;
      return Company.fromJson({...data, 'companyId': companyId});
    }).handleError((Object e) {
      debugPrint('[CompanyRepository] watchCompany failed: $e');
    });
  }

  @override
  Future<Company?> fetchCompany(String companyId) async {
    if (!_ready) return null;
    try {
      final snap = await _companies.doc(companyId).get();
      final data = snap.data();
      if (data == null) return null;
      return Company.fromJson({...data, 'companyId': companyId});
    } catch (e) {
      debugPrint('[CompanyRepository] fetchCompany failed: $e');
      return null;
    }
  }

  @override
  Future<void> saveCompany(Company company) async {
    if (!_ready) return;
    try {
      final data = company.toJson()
        ..remove('companyId')
        ..['updatedAt'] = FieldValue.serverTimestamp();
      await _companies.doc(company.companyId).set(data, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[CompanyRepository] saveCompany failed: $e');
    }
  }

  @override
  Future<void> ensureCompany(String ownerUid,
      {String? email, String? name}) async {
    if (!_ready) return;
    try {
      final doc = _companies.doc(ownerUid);
      final snapshot = await doc.get();
      final data = <String, dynamic>{
        'ownerUid': ownerUid,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (!snapshot.exists) {
        // Seed once from the auth identity; never overwrite later edits.
        data['createdAt'] = FieldValue.serverTimestamp();
        data['verificationStatus'] = 'pending';
        if (email != null && email.isNotEmpty) data['contactEmail'] = email;
        if (name != null && name.isNotEmpty) data['name'] = name;
      }
      await doc.set(data, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[CompanyRepository] ensureCompany failed: $e');
    }
  }

  @override
  Future<void> setLogoUrl(String companyId, String url) async {
    if (!_ready) return;
    try {
      await _companies.doc(companyId).set(
        {'logoUrl': url, 'updatedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('[CompanyRepository] setLogoUrl failed: $e');
    }
  }
}
