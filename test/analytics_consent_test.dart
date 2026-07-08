import 'package:careerbridge/core/providers/app_providers.dart';
import 'package:careerbridge/core/services/analytics/analytics_consent.dart';
import 'package:careerbridge/core/services/storage/local_storage_service.dart';
import 'package:careerbridge/core/services/storage/storage_keys.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _container() async {
  SharedPreferences.setMockInitialValues({});
  final storage = await LocalStorageService.create();
  final c = ProviderContainer(
    overrides: [localStorageProvider.overrideWithValue(storage)],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('defaults to enabled and persists a toggle', () async {
    final c = await _container();
    expect(c.read(analyticsConsentControllerProvider), isTrue);

    await c.read(analyticsConsentControllerProvider.notifier).setEnabled(false);
    expect(c.read(analyticsConsentControllerProvider), isFalse);
    expect(
      c.read(localStorageProvider).getBool(StorageKeys.analyticsConsent,
          defaultValue: true),
      isFalse,
    );
  });

  test('re-reads the persisted value on construction', () async {
    SharedPreferences.setMockInitialValues(
        {StorageKeys.analyticsConsent: false});
    final storage = await LocalStorageService.create();
    final c = ProviderContainer(
      overrides: [localStorageProvider.overrideWithValue(storage)],
    );
    addTearDown(c.dispose);
    expect(c.read(analyticsConsentControllerProvider), isFalse);
  });
}
