import 'package:careerbridge/core/services/recruiter_insights_store/in_memory_recruiter_insights_store.dart';
import 'package:careerbridge/features/employer/domain/analytics/recruiter_insights.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('save/clear update read() synchronously', () async {
    final store = InMemoryRecruiterInsightsStore();
    expect(store.read(), isNull);

    const a = RecruiterInsights(headline: 'one');
    await store.save(a);
    expect(store.read(), a);

    const b = RecruiterInsights(headline: 'two');
    await store.save(b);
    expect(store.read(), b);

    await store.clear();
    expect(store.read(), isNull);
  });

  test('watchLatest emits the current value then subsequent updates', () async {
    final store = InMemoryRecruiterInsightsStore();
    const a = RecruiterInsights(headline: 'one');
    await store.save(a);

    final emissions = <RecruiterInsights?>[];
    final sub = store.watchLatest().listen(emissions.add);
    await Future<void>.delayed(Duration.zero); // let the initial value emit

    const b = RecruiterInsights(headline: 'two');
    await store.save(b);
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();

    expect(emissions, [a, b]);
  });

  test('seed is exposed synchronously', () {
    const seed = RecruiterInsights(headline: 'seed');
    final store = InMemoryRecruiterInsightsStore(seed: seed);
    expect(store.read(), seed);
  });
}
