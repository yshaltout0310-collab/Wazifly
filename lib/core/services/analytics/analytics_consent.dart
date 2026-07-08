import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_providers.dart';
import '../storage/storage_keys.dart';

/// Analytics collection consent (opt-out foundation), persisted across launches.
///
/// Defaults to enabled (current behavior). Toggling this is the **only** thing a
/// future consent/settings screen needs to do — the bootstrap applies the value
/// to [AnalyticsService.setEnabled], so no feature code changes when consent is
/// introduced.
class AnalyticsConsentController extends StateNotifier<bool> {
  AnalyticsConsentController(this._ref)
      : super(_ref.read(localStorageProvider).getBool(
          StorageKeys.analyticsConsent,
          defaultValue: true,
        ));

  final Ref _ref;

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    await _ref
        .read(localStorageProvider)
        .setBool(StorageKeys.analyticsConsent, value: enabled);
  }
}

final analyticsConsentControllerProvider =
    StateNotifierProvider<AnalyticsConsentController, bool>(
  AnalyticsConsentController.new,
);
