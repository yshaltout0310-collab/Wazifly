import 'package:careerbridge/core/services/user_profile/in_memory_user_profile_repository.dart';
import 'package:careerbridge/features/profile/domain/experience_level.dart';
import 'package:careerbridge/features/user_type/domain/user_type.dart';
import 'package:careerbridge/shared/models/app_user.dart';
import 'package:careerbridge/shared/models/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const user = AppUser(
    uid: 'u1',
    method: AuthMethod.email,
    email: 'sarah@cb.app',
    displayName: 'Sarah',
  );

  test('watchProfile emits the current value then updates on save', () async {
    final repo = InMemoryUserProfileRepository();
    final emissions = <UserProfile?>[];
    final sub = repo.watchProfile('u1').listen(emissions.add);

    await Future<void>.delayed(Duration.zero);
    expect(emissions.first, isNull); // no profile yet

    await repo.saveProfile(const UserProfile(uid: 'u1', headline: 'Engineer'));
    await Future<void>.delayed(Duration.zero);

    expect(emissions.last?.headline, 'Engineer');
    await sub.cancel();
  });

  test('ensureProfile seeds identity fields and is idempotent', () async {
    final repo = InMemoryUserProfileRepository();
    await repo.ensureProfile(user);
    var stored = await repo.fetchProfile('u1');
    expect(stored?.displayName, 'Sarah');

    // A later edit must survive a subsequent ensureProfile (merge, not clobber).
    await repo.saveProfile(
        stored!.copyWith(skills: const ['Flutter'], headline: 'Flutter Eng'));
    await repo.ensureProfile(user);
    stored = await repo.fetchProfile('u1');
    expect(stored?.skills, ['Flutter']);
    expect(stored?.headline, 'Flutter Eng');
  });

  test('setUserType and setPhotoUrl merge into the existing profile', () async {
    final repo = InMemoryUserProfileRepository(
      seed: const [UserProfile(uid: 'u1', headline: 'Eng')],
    );
    await repo.setUserType('u1', UserType.jobSeeker);
    await repo.setPhotoUrl('u1', 'https://img/p.jpg');

    final stored = await repo.fetchProfile('u1');
    expect(stored?.userType, UserType.jobSeeker);
    expect(stored?.photoUrl, 'https://img/p.jpg');
    expect(stored?.headline, 'Eng'); // untouched
  });

  test('saveProfile persists the full editable field set', () async {
    final repo = InMemoryUserProfileRepository();
    const profile = UserProfile(
      uid: 'u1',
      skills: ['Dart'],
      experienceLevel: ExperienceLevel.lead,
      preferredJobTitles: ['Architect'],
    );
    await repo.saveProfile(profile);
    final stored = await repo.fetchProfile('u1');
    expect(stored?.experienceLevel, ExperienceLevel.lead);
    expect(stored?.preferredJobTitles, ['Architect']);
  });
}
