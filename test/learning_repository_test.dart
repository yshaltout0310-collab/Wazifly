import 'package:careerbridge/core/services/learning/in_memory_learning_profile_repository.dart';
import 'package:careerbridge/shared/models/learning_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 7, 10);

  test('watchProfile emits the current profile then updates', () async {
    final repo = InMemoryLearningProfileRepository();
    final emissions = <LearningProfile>[];
    final sub = repo.watchProfile('u1').listen(emissions.add);
    await Future<void>.delayed(const Duration(milliseconds: 5));

    final next = LearningProfile.empty('u1').added(
        LearningInterest.create(
            category: LearningCategory.goals, label: 'Grow', now: now),
        now);
    await repo.saveProfile(next);
    await Future<void>.delayed(const Duration(milliseconds: 5));

    expect(emissions.first.isEmpty, true);
    expect(emissions.last.interests.length, 1);
    await sub.cancel();
  });

  test('save is owner-scoped (a different uid keeps its empty profile)',
      () async {
    final repo = InMemoryLearningProfileRepository();
    final saved = LearningProfile.empty('u1').added(
        LearningInterest.create(
            category: LearningCategory.skillsToLearn, label: 'Go', now: now),
        now);
    await repo.saveProfile(saved);

    expect((await repo.fetchProfile('u1')).interests.length, 1);
    expect((await repo.fetchProfile('other')).isEmpty, true);
  });

  test('seed is honored', () async {
    final seed = LearningProfile.empty('u9').added(
        LearningInterest.create(
            category: LearningCategory.industries, label: 'Fintech', now: now),
        now);
    final repo = InMemoryLearningProfileRepository(seed: seed);
    expect((await repo.fetchProfile('u9')).interests.single.label, 'Fintech');
  });
}
