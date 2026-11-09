import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/models/employer_activity.dart';
import '../firebase/firebase_service.dart';
import '../firebase/firestore_stream.dart';
import 'employer_activity_repository.dart';

/// Firestore-backed [EmployerActivityRepository] — the production path.
///
/// Queries by `ownerUid` (equality — no composite index); sort in Dart. Degrades
/// to no-op/empty when Firebase isn't ready.
class FirestoreEmployerActivityRepository
    implements EmployerActivityRepository {
  FirestoreEmployerActivityRepository([FirebaseFirestore? firestore])
      : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  static const String _collection = 'employerActivity';

  bool get _ready => FirebaseService.instance.isReady;

  CollectionReference<Map<String, dynamic>> get _activity =>
      (_firestore ?? FirebaseFirestore.instance).collection(_collection);

  @override
  Future<void> log(EmployerActivity activity) async {
    if (!_ready) return;
    final data = activity.toJson()..remove('id');
    await _activity.doc(activity.id).set(data);
  }

  @override
  Stream<List<EmployerActivity>> watchActivity(String ownerUid) {
    if (!_ready) return Stream<List<EmployerActivity>>.value(const []);
    return _activity
        .where('ownerUid', isEqualTo: ownerUid)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => EmployerActivity.fromJson({...d.data(), 'id': d.id}))
          .toList();
      list.sort((a, b) => b.at.compareTo(a.at));
      return list;
    }).logAndForwardErrors('EmployerActivity.watchActivity');
  }
}
