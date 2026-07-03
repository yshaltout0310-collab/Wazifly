import 'package:careerbridge/core/services/jobs/saved_jobs_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('toggle adds then removes an id', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final controller = c.read(savedJobsProvider.notifier);

    await controller.toggle('a');
    expect(c.read(savedJobsProvider), {'a'});

    await controller.toggle('a');
    expect(c.read(savedJobsProvider), isEmpty);
  });

  test('persists through the store seam', () async {
    final store = InMemorySavedJobsStore();
    final c = ProviderContainer(overrides: [
      savedJobsStoreProvider.overrideWithValue(store),
    ]);
    addTearDown(c.dispose);

    await c.read(savedJobsProvider.notifier).toggle('x');
    expect(store.read(), {'x'});
  });
}
