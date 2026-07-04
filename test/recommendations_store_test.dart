import 'package:careerbridge/core/services/recommendations_store/in_memory_recommendations_store.dart';
import 'package:careerbridge/features/recommendations/domain/recommendation_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const recs = Recommendations(
      headline: 'h', skillsToLearn: [SkillRecommendation(skill: 'x')]);

  test('seed is readable synchronously', () {
    final store = InMemoryRecommendationsStore(seed: recs);
    expect(store.read(), recs);
  });

  test('save/read/clear + stream re-emits', () async {
    final store = InMemoryRecommendationsStore();
    expect(store.read(), isNull);

    final events = <Recommendations?>[];
    final sub = store.watchLatest().listen(events.add);
    await Future<void>.delayed(Duration.zero); // deliver initial null + subscribe

    await store.save(recs);
    await Future<void>.delayed(Duration.zero);
    expect(store.read(), recs);

    await store.clear();
    await Future<void>.delayed(Duration.zero);
    expect(store.read(), isNull);

    await sub.cancel();
    expect(events.first, isNull); // current value to a new listener
    expect(events, contains(recs));
    expect(events.last, isNull); // after clear
  });
}
