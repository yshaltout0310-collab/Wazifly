import 'package:careerbridge/core/services/learning/in_memory_learning_profile_repository.dart';
import 'package:careerbridge/core/services/learning/learning_profile_repository.dart';
import 'package:careerbridge/features/learning/application/learning_controller.dart';
import 'package:careerbridge/shared/models/app_user.dart';
import 'package:careerbridge/shared/models/learning_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_auth.dart';

/// A repository whose saves always throw, to exercise the failure path.
class _ThrowingRepo implements LearningProfileRepository {
  @override
  Stream<LearningProfile> watchProfile(String uid) =>
      Stream.value(LearningProfile.empty(uid));
  @override
  Future<LearningProfile> fetchProfile(String uid) async =>
      LearningProfile.empty(uid);
  @override
  Future<void> saveProfile(LearningProfile profile) async =>
      throw Exception('boom');
}

void main() {
  const user = AppUser(uid: 'u1', method: AuthMethod.email, email: 'a@b.com');

  late InMemoryLearningProfileRepository repo;
  late ProviderContainer c;

  Future<void> pump() => Future<void>.delayed(const Duration(milliseconds: 5));

  ProviderContainer container(LearningProfileRepository r) {
    final ct = ProviderContainer(overrides: [
      fakeAuthOverride(user: user),
      learningProfileRepositoryProvider.overrideWithValue(r),
    ]);
    ct.listen(learningProfileProvider, (_, __) {});
    addTearDown(ct.dispose);
    return ct;
  }

  setUp(() {
    repo = InMemoryLearningProfileRepository();
    c = container(repo);
  });

  LearningController ctrl() => c.read(learningControllerProvider.notifier);

  test('addInterest persists to the owner profile', () async {
    final ok = await ctrl()
        .addInterest(category: LearningCategory.skillsToLearn, label: 'Rust');
    expect(ok, true);
    final p = await repo.fetchProfile('u1');
    expect(p.contains(LearningCategory.skillsToLearn, 'Rust'), true);
  });

  test('empty label is rejected', () async {
    final ok =
        await ctrl().addInterest(category: LearningCategory.goals, label: '  ');
    expect(ok, false);
  });

  test('editInterest updates the label', () async {
    await ctrl().addInterest(category: LearningCategory.technologies, label: 'Fluter');
    await pump();
    final existing =
        (await repo.fetchProfile('u1')).byCategory(LearningCategory.technologies).single;
    final ok = await ctrl().editInterest(existing, label: 'Flutter');
    expect(ok, true);
    final p = await repo.fetchProfile('u1');
    expect(p.byCategory(LearningCategory.technologies).single.label, 'Flutter');
  });

  test('deleteInterest removes it', () async {
    await ctrl().addInterest(category: LearningCategory.industries, label: 'Fintech');
    await pump();
    final existing =
        (await repo.fetchProfile('u1')).byCategory(LearningCategory.industries).single;
    final ok = await ctrl().deleteInterest(existing);
    expect(ok, true);
    expect((await repo.fetchProfile('u1')).isEmpty, true);
  });

  test('search query is held in state', () {
    ctrl().setSearch('go');
    expect(c.read(learningControllerProvider).query, 'go');
  });

  test('save failure surfaces LearningFailure.saveFailed', () async {
    final tc = container(_ThrowingRepo());
    final ok = await tc
        .read(learningControllerProvider.notifier)
        .addInterest(category: LearningCategory.goals, label: 'x');
    expect(ok, false);
    expect(tc.read(learningControllerProvider).failure,
        LearningFailure.saveFailed);
  });
}
