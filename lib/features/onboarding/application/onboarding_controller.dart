import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/services/storage/storage_keys.dart';

/// Tracks whether the user has finished the welcome/onboarding flow.
///
/// The splash screen reads this to decide whether to send a returning user
/// straight to authentication.
class OnboardingController extends StateNotifier<bool> {
  OnboardingController(this._ref)
      : super(
          _ref
              .read(localStorageProvider)
              .getBool(StorageKeys.onboardingCompleted),
        );

  final Ref _ref;

  Future<void> complete() async {
    state = true;
    await _ref
        .read(localStorageProvider)
        .setBool(StorageKeys.onboardingCompleted, value: true);
  }
}

final onboardingControllerProvider =
    StateNotifierProvider<OnboardingController, bool>(
  OnboardingController.new,
);
