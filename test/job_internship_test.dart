import 'package:careerbridge/features/employer/domain/employment_type.dart';
import 'package:careerbridge/features/employer/domain/job_experience.dart';
import 'package:careerbridge/shared/models/internship_details.dart';
import 'package:careerbridge/shared/models/job.dart';
import 'package:careerbridge/shared/models/job_posting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Job', () {
    test('fromJson tolerates a missing internship block (no regression)', () {
      final j = Job.fromJson(const {
        'id': 'j1',
        'title': 'Engineer',
        'employmentType': 'Full-time',
      });
      expect(j.internship, isNull);
      expect(j.trainsBeginners, false);
      expect(j.isInternship, false);
    });

    test('parses an embedded internship + trainsBeginners', () {
      final j = Job.fromJson(const {
        'id': 'i1',
        'title': 'Intern',
        'employmentType': 'Internship',
        'trainsBeginners': true,
        'internship': {'funding': 'paid', 'workMode': 'remote'},
      });
      expect(j.isInternship, true);
      expect(j.trainsBeginners, true);
      expect(j.internship?.funding, InternshipFunding.paid);
    });

    test('isInternship is true by canonical employmentType even without details',
        () {
      const j = Job(
        id: 'i2',
        title: 'Intern',
        company: 'Acme',
        location: 'Doha',
        employmentType: 'Internship',
        seniority: 'Entry',
        description: 'x',
        requiredSkills: [],
        remote: false,
      );
      expect(j.isInternship, true);
    });
  });

  group('JobPosting.toJob projection', () {
    JobPosting base() => JobPosting.create(
          id: 'p1',
          companyId: 'c1',
          ownerUid: 'u1',
          companyName: 'Acme',
          now: DateTime(2026, 1, 1),
        );

    test('projects internship details + trainsBeginners for an internship', () {
      final p = base().copyWith(
        employmentType: EmploymentType.internship,
        experience: JobExperience.entry,
        trainsBeginners: true,
        internship: const InternshipDetails(
          funding: InternshipFunding.paid,
          workMode: WorkMode.hybrid,
        ),
      );
      final job = p.toJob();
      expect(job.isInternship, true);
      expect(job.trainsBeginners, true);
      expect(job.internship?.funding, InternshipFunding.paid);
    });

    test('a non-internship job never leaks a stray internship block', () {
      final p = base().copyWith(
        employmentType: EmploymentType.fullTime,
        internship: const InternshipDetails(funding: InternshipFunding.paid),
      );
      expect(p.toJob().internship, isNull);
    });

    test('JobPosting JSON round-trips internship + trainsBeginners', () {
      final p = base().copyWith(
        employmentType: EmploymentType.internship,
        trainsBeginners: true,
        internship: const InternshipDetails(
          funding: InternshipFunding.unpaid,
          category: InternshipCategory.data,
          certificateProvided: true,
        ),
      );
      final back = JobPosting.fromJson(p.toJson());
      expect(back.trainsBeginners, true);
      expect(back.internship?.category, InternshipCategory.data);
      expect(back.internship?.certificateProvided, true);
    });
  });
}
