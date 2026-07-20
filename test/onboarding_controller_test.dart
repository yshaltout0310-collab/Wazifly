import 'package:careerbridge/core/providers/app_providers.dart';
import 'package:careerbridge/core/services/storage/local_storage_service.dart';
import 'package:careerbridge/core/services/storage/storage_keys.dart';
import 'package:careerbridge/features/onboarding/application/onboarding_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Guards the first-launch onboarding gate: the splash sends a user to the
/// language-selection screen exactly when onboarding is NOT yet complete
/// (`if (!onboardingDone) goNamed(language)`). These tests lock in that
/// precondition so the language step can't silently disappear again.
Future<LocalStorageService> _storage([Map<String, Object> seed = const {}]) {
  SharedPreferences.setMockInitialValues(seed);
  return LocalStorageService.create();
}

ProviderContainer _container(LocalStorageService storage) {
  final c = ProviderContainer(
    overrides: [localStorageProvider.overrideWithValue(storage)],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('fresh install → onboarding is NOT complete (splash routes to language)',
      () async {
    final c = _container(await _storage()); // no keys persisted
    expect(c.read(onboardingControllerProvider), isFalse);
  });

  test('completing onboarding persists true so language is not shown again',
      () async {
    final storage = await _storage();
    final c = _container(storage);
    expect(c.read(onboardingControllerProvider), isFalse);

    await c.read(onboardingControllerProvider.notifier).complete();

    expect(c.read(onboardingControllerProvider), isTrue);
    // Survives a restart (a new controller reading the same storage).
    expect(storage.getBool(StorageKeys.onboardingCompleted), isTrue);
  });

  test('returning user (flag already set) skips the language step', () async {
    final c = _container(
      await _storage({StorageKeys.onboardingCompleted: true}),
    );
    expect(c.read(onboardingControllerProvider), isTrue);
  });

  test('reset() clears the flag so the first-launch flow runs again', () async {
    // A completed user (e.g. from Settings → Restart onboarding).
    final storage = await _storage({StorageKeys.onboardingCompleted: true});
    final c = _container(storage);
    expect(c.read(onboardingControllerProvider), isTrue);

    await c.read(onboardingControllerProvider.notifier).reset();

    // In-memory state flips false (splash will route to language)...
    expect(c.read(onboardingControllerProvider), isFalse);
    // ...and it persists across a restart.
    expect(storage.getBool(StorageKeys.onboardingCompleted), isFalse);
  });

  test('reset() touches ONLY the onboarding flag, not language/country/other',
      () async {
    final storage = await _storage({
      StorageKeys.onboardingCompleted: true,
      StorageKeys.languageCode: 'ar',
      StorageKeys.selectedCountry: 'QA',
      'pref_some_other_data': 'keep-me',
    });
    final c = _container(storage);

    await c.read(onboardingControllerProvider.notifier).reset();

    // Onboarding flag cleared, everything else preserved.
    expect(storage.getBool(StorageKeys.onboardingCompleted), isFalse);
    expect(storage.getString(StorageKeys.languageCode), 'ar');
    expect(storage.getString(StorageKeys.selectedCountry), 'QA');
    expect(storage.getString('pref_some_other_data'), 'keep-me');
  });
}
