// ignore_for_file: prefer_const_literals_to_create_immutables
import 'package:careerbridge/features/cv_builder/domain/cv_data.dart';
import 'package:careerbridge/features/profile/domain/experience_level.dart';
import 'package:careerbridge/features/resume_analyzer/domain/resume_analysis.dart';
import 'package:careerbridge/features/user_type/domain/user_type.dart';
import 'package:careerbridge/shared/models/app_user.dart';
import 'package:careerbridge/shared/models/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CvData.fromProfile', () {
    const profile = UserProfile(
      uid: 'u1',
      displayName: 'Sarah Ahmed',
      headline: 'Flutter Engineer',
      location: 'Doha',
      bio: 'Builds delightful apps.',
      userType: UserType.jobSeeker,
      skills: ['Flutter', 'Dart'],
      experienceLevel: ExperienceLevel.senior,
      preferredJobTitles: ['Mobile Engineer', 'Frontend'],
      githubUrl: 'github.com/sarah',
    );
    const user = AppUser(
      uid: 'u1',
      method: AuthMethod.email,
      email: 'sarah@cb.app',
      phoneNumber: '+974500',
      displayName: 'Sarah Ahmed',
    );

    test('seeds contact, skills, links, and target role from the profile', () {
      final cv = CvData.fromProfile(profile, user: user);
      expect(cv.fullName, 'Sarah Ahmed');
      expect(cv.email, 'sarah@cb.app');
      expect(cv.phone, '+974500');
      expect(cv.location, 'Doha');
      expect(cv.githubUrl, 'github.com/sarah');
      expect(cv.skills, ['Flutter', 'Dart']);
      expect(cv.targetRole, 'Mobile Engineer'); // first preferred title
    });

    test('summary falls back to the profile bio when no analysis', () {
      final cv = CvData.fromProfile(profile, user: user);
      expect(cv.summary, 'Builds delightful apps.');
    });

    test('reuses the resume analysis summary when available', () {
      const analysis = ResumeAnalysis(
        atsScore: 88,
        summary: 'Seasoned mobile engineer with strong Flutter delivery.',
        strengths: ['Ownership'],
        weaknesses: [],
        missingSkills: ['CI/CD'],
        grammarIssues: [],
        improvementSuggestions: ['Add metrics'],
      );
      final cv = CvData.fromProfile(profile, user: user, analysis: analysis);
      expect(cv.summary, 'Seasoned mobile engineer with strong Flutter delivery.');
    });
  });

  group('CvData json', () {
    test('round-trips including nested experience/education', () {
      const cv = CvData(
        fullName: 'Omar',
        headline: 'Backend Engineer',
        email: 'omar@cb.app',
        summary: 'Hi',
        skills: ['Go', 'SQL'],
        experiences: [
          CvExperience(
            role: 'Engineer',
            company: 'Acme',
            startDate: '2020',
            current: true,
            bullets: ['Shipped X', 'Scaled Y'],
          ),
        ],
        education: [
          CvEducation(
              degree: 'BSc', institution: 'QU', startYear: '2016', endYear: '2020'),
        ],
        targetRole: 'Staff Engineer',
      );
      final restored = CvData.fromJson(cv.toJson());
      expect(restored, cv);
    });

    test('defensive parse tolerates snake_case + comma-string skills', () {
      final cv = CvData.fromJson({
        'full_name': 'Lina',
        'skills': 'Flutter, Dart, ,Flutter',
        'experiences': 'not-a-list',
      });
      expect(cv.fullName, 'Lina');
      expect(cv.skills, ['Flutter', 'Dart']); // deduped, blanks dropped
      expect(cv.experiences, isEmpty);
    });

    test('isEmpty is true for a blank CV', () {
      expect(const CvData().isEmpty, isTrue);
      expect(const CvData(fullName: 'x').isEmpty, isFalse);
    });
  });
}
