import 'package:careerbridge/features/job_matching/domain/job.dart';
import 'package:careerbridge/features/job_matching/domain/job_match.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Job.fromJson', () {
    test('parses a full record', () {
      final job = Job.fromJson(const {
        'id': 'flutter-eng',
        'title': 'Flutter Engineer',
        'company': 'Acme',
        'location': 'Doha',
        'employmentType': 'Full-time',
        'seniority': 'Mid',
        'description': 'Build apps',
        'requiredSkills': ['Flutter', 'Dart'],
        'remote': true,
      });

      expect(job.id, 'flutter-eng');
      expect(job.requiredSkills, ['Flutter', 'Dart']);
      expect(job.remote, isTrue);
    });

    test('tolerates snake_case and missing fields', () {
      final job = Job.fromJson(const {
        'id': 'x',
        'title': 'Dev',
        'required_skills': ['Kotlin'],
        'employment_type': 'Contract',
        'remote': 'yes',
      });

      expect(job.requiredSkills, ['Kotlin']);
      expect(job.employmentType, 'Contract');
      expect(job.remote, isTrue); // string "yes" → true
      expect(job.company, isEmpty); // missing → empty, not null
      expect(job.location, isEmpty);
    });
  });

  group('JobMatch.fromRanking', () {
    const job = Job(
      id: 'x',
      title: 'Dev',
      company: 'Acme',
      location: 'Doha',
      employmentType: 'Full-time',
      seniority: 'Mid',
      description: '',
      requiredSkills: ['Flutter'],
      remote: false,
    );

    test('merges ranking with its job and clamps the score', () {
      final match = JobMatch.fromRanking(const {
        'id': 'x',
        'matchScore': 140, // over 100 → clamped
        'reason': 'Great fit',
        'matchingSkills': ['Flutter'],
        'missingSkills': ['Kotlin'],
      }, job);

      expect(match.job, job);
      expect(match.matchScore, 100);
      expect(match.reason, 'Great fit');
      expect(match.matchingSkills, ['Flutter']);
      expect(match.missingSkills, ['Kotlin']);
    });

    test('defaults missing/mistyped fields to empties', () {
      final match = JobMatch.fromRanking(const {'id': 'x'}, job);

      expect(match.matchScore, 0);
      expect(match.reason, isEmpty);
      expect(match.matchingSkills, isEmpty);
      expect(match.missingSkills, isEmpty);
    });
  });
}
