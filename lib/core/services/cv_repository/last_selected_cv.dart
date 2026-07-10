import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_providers.dart';
import '../storage/storage_keys.dart';

/// Remembers the CV the user last submitted with a job application, so the apply
/// picker can preselect it next time. Persisted via [LocalStorageService]
/// (mirrors `UserTypeController`/`CountryController`).
class LastSelectedCvController extends StateNotifier<String?> {
  LastSelectedCvController(this._ref)
      : super(_ref
            .read(localStorageProvider)
            .getString(StorageKeys.lastSelectedCvId));

  final Ref _ref;

  Future<void> set(String cvId) async {
    state = cvId;
    await _ref
        .read(localStorageProvider)
        .setString(StorageKeys.lastSelectedCvId, cvId);
  }

  Future<void> clear() async {
    state = null;
    await _ref.read(localStorageProvider).remove(StorageKeys.lastSelectedCvId);
  }
}

final lastSelectedCvProvider =
    StateNotifierProvider<LastSelectedCvController, String?>(
  LastSelectedCvController.new,
);
