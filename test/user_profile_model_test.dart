// ignore_for_file: prefer_const_literals_to_create_immutables
import 'package:careerbridge/features/profile/domain/experience_level.dart';
import 'package:careerbridge/features/user_type/domain/user_type.dart';
import 'package:careerbridge/shared/models/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserProfile.completion', () {
    test('an empty profile is 0% complete and lists every field', () {
      final p = UserProfile.empty('u1');
      expect(p.completionPercent, 0);
      expect(p.missingFields.length, 10);
      expect(p.missingFields, contains(ProfileField.skills));
      expect(p.missingFields, contains(ProfileField.experienceLevel));
      expect(p.missingFields, contains(ProfileField.preferredJobTitles));
      expect(p.missingFields, contains(ProfileField.links));
    });

    test('a fully populated profile is 100% complete', () {
      const p = UserProfile(
        uid: 'u1',
        displayName: 'Sarah Ahmed',
        photoUrl: 'https://img/p.jpg',
        headline: 'Flutter Engineer',
        location: 'Doha',
        bio: 'Builds delightful apps.',
        userType: UserType.jobSeeker,
        skills: ['Flutter', 'Dart'],
        experienceLevel: ExperienceLevel.senior,
        preferredJobTitles: ['Mobile Engineer'],
        githubUrl: 'https://github.com/sarah',
      );
      expect(p.completionPercent, 100);
      expect(p.missingFields, isEmpty);
      expect(p.hasAnyLink, isTrue);
    });

    test('a single link satisfies the links field', () {
      const base = UserProfile(uid: 'u1');
      expect(base.hasAnyLink, isFalse);
      final withLink = base.copyWith(linkedinUrl: 'https://linkedin/x');
      expect(withLink.hasAnyLink, isTrue);
      expect(withLink.missingFields, isNot(contains(ProfileField.links)));
    });

    test('completion is a monotonic ratio as fields fill', () {
      const empty = UserProfile(uid: 'u1');
      final partial = empty.copyWith(headline: 'x', skills: const ['Flutter']);
      expect(partial.completionPercent, greaterThan(empty.completionPercent));
      expect(partial.completionPercent, 20); // 2 of 10
    });
  });

  group('UserProfile json', () {
    test('round-trips through toJson/fromJson', () {
      const original = UserProfile(
        uid: 'u1',
        displayName: 'Sarah',
        headline: 'Flutter Engineer',
        location: 'Doha',
        bio: 'Hi',
        userType: UserType.jobSeeker,
        skills: ['Flutter', 'Dart'],
        experienceLevel: ExperienceLevel.mid,
        preferredJobTitles: ['Mobile Engineer', 'Frontend'],
        portfolioUrl: 'https://p',
        githubUrl: 'https://g',
        linkedinUrl: 'https://l',
      );
      final restored = UserProfile.fromJson(original.toJson());
      expect(restored, original);
    });

    test('tolerates snake_case keys and comma-string lists', () {
      final p = UserProfile.fromJson({
        'uid': 'u2',
        'display_name': 'Omar',
        'experience_level': 'SENIOR',
        'preferred_job_titles': 'Backend, ,Backend, Data',
        'skills': ['Go', ' Go ', ''],
        'github_url': 'https://g',
      });
      expect(p.displayName, 'Omar');
      expect(p.experienceLevel, ExperienceLevel.senior);
      // De-duplicated (case-insensitive) + blanks dropped, order preserved.
      expect(p.preferredJobTitles, ['Backend', 'Data']);
      expect(p.skills, ['Go']);
      expect(p.githubUrl, 'https://g');
    });

    test('bad/missing values degrade gracefully rather than throw', () {
      final p = UserProfile.fromJson({
        'uid': 'u3',
        'experienceLevel': 'wizard', // unknown
        'skills': 42, // wrong type
        'userType': null,
      });
      expect(p.experienceLevel, isNull);
      expect(p.skills, isEmpty);
      expect(p.userType, isNull);
      expect(p.completionPercent, 0);
    });

    test('parses epoch millis and ISO dates', () {
      final iso = UserProfile.fromJson({
        'uid': 'u4',
        'createdAt': '2026-01-02T03:04:05.000Z',
      });
      expect(iso.createdAt, DateTime.utc(2026, 1, 2, 3, 4, 5));
      final millis = UserProfile.fromJson({
        'uid': 'u4',
        'updatedAt': 1735783200000,
      });
      expect(millis.updatedAt, isNotNull);
    });
  });
}
