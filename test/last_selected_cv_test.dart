import 'package:careerbridge/core/providers/app_providers.dart';
import 'package:careerbridge/core/services/cv_repository/last_selected_cv.dart';
import 'package:careerbridge/core/services/storage/local_storage_service.dart';
import 'package:careerbridge/core/services/storage/storage_keys.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<ProviderContainer> container([Map<String, Object> seed = const {}]) async {
    SharedPreferences.setMockInitialValues(seed);
    final storage = await LocalStorageService.create();
    final c = ProviderContainer(
      overrides: [localStorageProvider.overrideWithValue(storage)],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('defaults to null and persists a selection', () async {
    final c = await container();
    expect(c.read(lastSelectedCvProvider), isNull);
    await c.read(lastSelectedCvProvider.notifier).set('cv-123');
    expect(c.read(lastSelectedCvProvider), 'cv-123');
  });

  test('hydrates from persisted value', () async {
    final c = await container({StorageKeys.lastSelectedCvId: 'cv-abc'});
    expect(c.read(lastSelectedCvProvider), 'cv-abc');
  });

  test('clear removes the selection', () async {
    final c = await container({StorageKeys.lastSelectedCvId: 'cv-abc'});
    await c.read(lastSelectedCvProvider.notifier).clear();
    expect(c.read(lastSelectedCvProvider), isNull);
  });
}
