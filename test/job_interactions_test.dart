import 'package:careerbridge/core/services/jobs/job_interactions_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('toggleSaved adds then removes an id', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final controller = c.read(jobInteractionsProvider.notifier);

    await controller.toggleSaved('a');
    expect(c.read(jobInteractionsProvider).saved, {'a'});

    await controller.toggleSaved('a');
    expect(c.read(jobInteractionsProvider).saved, isEmpty);
  });

  test('markApplied is idempotent', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final controller = c.read(jobInteractionsProvider.notifier);

    await controller.markApplied('a');
    await controller.markApplied('a');
    expect(c.read(jobInteractionsProvider).applied, {'a'});
  });

  test('persists through the store seam', () async {
    final store = InMemoryJobInteractionsStore();
    final c = ProviderContainer(overrides: [
      jobInteractionsStoreProvider.overrideWithValue(store),
    ]);
    addTearDown(c.dispose);

    await c.read(jobInteractionsProvider.notifier).toggleSaved('x');
    expect(store.readSaved(), {'x'});
  });
}
