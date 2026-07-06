import 'package:careerbridge/shared/models/applicant_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defaults snapshotVersion to the current version', () {
    expect(const ApplicantSnapshot().snapshotVersion,
        ApplicantSnapshot.currentVersion);
  });

  test('round-trips through toJson/fromJson', () {
    const snap = ApplicantSnapshot(
      name: 'Sara',
      headline: 'Flutter Engineer',
      location: 'Doha',
      skills: ['Flutter', 'Dart'],
      experienceLevel: 'Senior',
      atsScore: 88,
      resumeSummary: 'Strong mobile background',
      resumeStrengths: ['Clear', 'Concise'],
      matchScore: 92,
      matchReason: 'Great fit',
      matchingSkills: ['Flutter'],
      missingSkills: ['Kubernetes'],
      interviewSessions: 3,
      interviewBestScore: 81,
      interviewLatestType: 'technical',
    );
    final back = ApplicantSnapshot.fromJson(snap.toJson());
    expect(back, snap);
  });

  test('clamps scores and tolerates snake_case + missing fields', () {
    final s = ApplicantSnapshot.fromJson(const {
      'name': 'Omar',
      'match_score': 150, // clamped to 100
      'ats_score': -5, // clamped to 0
      'interview_sessions': 2,
      'resume_strengths': 'A, B, C',
    });
    expect(s.name, 'Omar');
    expect(s.matchScore, 100);
    expect(s.atsScore, 0);
    expect(s.interviewSessions, 2);
    expect(s.resumeStrengths, ['A', 'B', 'C']);
    expect(s.snapshotVersion, ApplicantSnapshot.currentVersion);
  });

  test('has* getters reflect presence', () {
    expect(const ApplicantSnapshot(atsScore: 70).hasResumeAnalysis, isTrue);
    expect(const ApplicantSnapshot(matchScore: 60).hasMatch, isTrue);
    expect(const ApplicantSnapshot(resumeUrl: 'x').hasResumeFile, isTrue);
    expect(const ApplicantSnapshot(interviewSessions: 1).hasInterviewActivity,
        isTrue);
    expect(const ApplicantSnapshot().hasMatch, isFalse);
  });
}
