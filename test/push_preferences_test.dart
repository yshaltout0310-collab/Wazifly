import 'package:careerbridge/core/services/messaging/push_preferences.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PushPreferences', () {
    test('master gate turns every category off', () {
      const p = PushPreferences(master: false);
      for (final c in PushCategory.values) {
        expect(p.isEnabled(c), isFalse);
      }
    });

    test('per-category toggles apply when master is on', () {
      const p = PushPreferences(applicationUpdates: false);
      expect(p.isEnabled(PushCategory.applicationUpdates), isFalse);
      expect(p.isEnabled(PushCategory.jobRecommendations), isTrue);
      expect(p.isEnabled(PushCategory.interviewReminders), isTrue);
      expect(p.isEnabled(PushCategory.employerNotifications), isTrue);
    });

    test('json round-trips and defends against missing / bad values', () {
      const p = PushPreferences(interviewReminders: false);
      expect(PushPreferences.fromJson(p.toJson()), p);
      expect(PushPreferences.fromJson(const {}), PushPreferences.defaults);
      expect(PushPreferences.fromJson(const {'master': 'nope'}).master, isTrue);
    });
  });

  group('InMemoryPushPreferencesRepository', () {
    test('defaults, then reflects saves', () async {
      final repo = InMemoryPushPreferencesRepository();
      expect(await repo.read('u'), PushPreferences.defaults);

      await repo.save('u', const PushPreferences(master: false));
      expect((await repo.read('u')).master, isFalse);
    });

    test('watch emits the current value then updates', () async {
      final repo = InMemoryPushPreferencesRepository();
      final seen = <PushPreferences>[];
      final sub = repo.watch('u').listen(seen.add);
      await Future<void>.delayed(Duration.zero);
      await repo.save('u', const PushPreferences(jobRecommendations: false));
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(seen.first, PushPreferences.defaults);
      expect(seen.last.jobRecommendations, isFalse);
    });
  });
}
