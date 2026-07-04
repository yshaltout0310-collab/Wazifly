import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/cv_builder/domain/cv_data.dart';

/// Persistence seam for the in-progress CV draft.
///
/// Lives in `core/services` alongside the other reusable store seams
/// (resume/chat/saved-jobs) so features (CV Builder, Interview Prep) read the
/// draft via this one core provider without depending on each other. In-memory
/// today (survives navigation within a session); rebind [cvDraftStoreProvider]
/// to a Firestore/local implementation later — **no feature code changes**.
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
