import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/cv_data.dart';

/// Persistence seam for the in-progress CV draft.
///
/// In-memory today (survives navigation within a session). Rebind
/// [cvDraftStoreProvider] to a Firestore/local implementation later — **no
/// feature code changes** — mirroring the resume/chat/saved-jobs store seams.
abstract interface class CvDraftStore {
  CvData? read();
  void write(CvData data);
  void clear();
}

class InMemoryCvDraftStore implements CvDraftStore {
  CvData? _draft;

  @override
  CvData? read() => _draft;

  @override
  void write(CvData data) => _draft = data;

  @override
  void clear() => _draft = null;
}

final cvDraftStoreProvider =
    Provider<CvDraftStore>((ref) => InMemoryCvDraftStore());
