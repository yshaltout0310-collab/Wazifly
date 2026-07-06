import 'package:careerbridge/features/employer/domain/employment_type.dart';
import 'package:careerbridge/features/employer/domain/job_experience.dart';
import 'package:careerbridge/features/employer/domain/job_status.dart';
import 'package:careerbridge/features/employer/domain/salary_period.dart';
import 'package:careerbridge/shared/models/job_posting.dart';
import 'package:flutter_test/flutter_test.dart';

JobPosting _sample() => JobPosting(
      id: 'j1',
      companyId: 'c1',
      ownerUid: 'c1',
      companyName: 'Acme',
      title: 'Flutter Engineer',
      description: 'Build apps.',
      requiredSkills: const ['Flutter', 'Dart'],
      location: 'Doha',
      remote: true,
      employmentType: EmploymentType.fullTime,
      experience: JobExperience.senior,
      salary: const SalaryRange(min: 100, max: 200, period: SalaryPeriod.monthly),
      openings: 3,
      createdAt: DateTime(2026, 7, 1),
      updatedAt: DateTime(2026, 7, 1),
    );

void main() {
  group('toJob projection', () {
    test('projects public fields with canonical enum strings', () {
      final job = _sample().toJob();
      expect(job.id, 'j1');
      expect(job.title, 'Flutter Engineer');
      expect(job.company, 'Acme');
      expect(job.employmentType, 'Full-time');
      expect(job.seniority, 'Senior');
      expect(job.remote, isTrue);
      expect(job.requiredSkills, ['Flutter', 'Dart']);
    });
  });

  group('lifecycle', () {
    test('create seeds a draft with an initial history entry', () {
      final p = JobPosting.create(
          id: 'j2', companyId: 'c1', ownerUid: 'c1', now: DateTime(2026, 7, 5));
      expect(p.status, JobStatus.draft);
      expect(p.statusHistory.single.status, JobStatus.draft);
    });

    test('withStatus stamps publishedAt on first publish and appends history',
        () {
      final published = _sample()
          .copyWith(status: JobStatus.draft)
          .withStatus(JobStatus.published, at: DateTime(2026, 7, 6));
      expect(published.status, JobStatus.published);
      expect(published.publishedAt, DateTime(2026, 7, 6));
      expect(published.statusHistory.last.status, JobStatus.published);
    });

    test('archive sets a reason; reopen clears it', () {
      final archived = _sample()
          .copyWith(status: JobStatus.published)
          .withStatus(JobStatus.archived,
              at: DateTime(2026, 7, 6), reason: 'Filled');
      expect(archived.archiveReason, 'Filled');
      final reopened =
          archived.withStatus(JobStatus.published, at: DateTime(2026, 7, 7));
      expect(reopened.archiveReason, isNull);
    });

    test('softDeleted retains the doc but marks it deleted', () {
      final deleted = _sample().softDeleted(at: DateTime(2026, 7, 6));
      expect(deleted.isDeleted, isTrue);
      expect(deleted.id, 'j1');
    });

    test('duplicated is a fresh draft with a suffixed title + cleared metrics',
        () {
      final copy = _sample()
          .copyWith(status: JobStatus.published)
          .duplicated(id: 'j9', now: DateTime(2026, 7, 6));
      expect(copy.id, 'j9');
      expect(copy.status, JobStatus.draft);
      expect(copy.title, 'Flutter Engineer (Copy)');
      expect(copy.publishedAt, isNull);
      expect(copy.metrics, JobMetrics.zero);
    });

    test('isPublishable follows the status machine', () {
      expect(_sample().copyWith(status: JobStatus.draft).isPublishable, isTrue);
      expect(
          _sample().copyWith(status: JobStatus.published).isPublishable, isFalse);
      expect(_sample().copyWith(status: JobStatus.closed).isPublishable, isTrue);
    });

    test('displayOpenings defaults to 1 when unset', () {
      // copyWith can't null-out openings, so build one without it.
      const bare = JobPosting(id: 'j1', companyId: 'c1', ownerUid: 'c1');
      expect(bare.displayOpenings, 1);
      expect(_sample().displayOpenings, 3);
    });

    test('availability helpers respect the clock', () {
      final p = _sample().copyWith(
        opensAt: DateTime(2026, 8, 1),
        expiresAt: DateTime(2026, 9, 1),
      );
      expect(p.isScheduledAt(DateTime(2026, 7, 1)), isTrue);
      expect(p.isExpiredAt(DateTime(2026, 10, 1)), isTrue);
      expect(p.isExpiredAt(DateTime(2026, 8, 15)), isFalse);
    });
  });

  group('JSON', () {
    test('round-trips through toJson/fromJson', () {
      final back = JobPosting.fromJson(_sample().toJson());
      expect(back.id, 'j1');
      expect(back.title, 'Flutter Engineer');
      expect(back.employmentType, EmploymentType.fullTime);
      expect(back.experience, JobExperience.senior);
      expect(back.salary?.min, 100);
      expect(back.salary?.period, SalaryPeriod.monthly);
      expect(back.openings, 3);
      expect(back.status, JobStatus.draft);
    });

    test('tolerates snake_case + bad enums + defaults ownerUid to companyId',
        () {
      final p = JobPosting.fromJson(const {
        'id': 'j5',
        'company_id': 'c5',
        'title': 'Role',
        'required_skills': 'A, B, C',
        'employment_type': 'Full-time',
        'status': 'not-a-status',
      });
      expect(p.companyId, 'c5');
      expect(p.ownerUid, 'c5'); // falls back to companyId
      expect(p.requiredSkills, ['A', 'B', 'C']);
      expect(p.employmentType, EmploymentType.fullTime);
      expect(p.status, JobStatus.draft); // bad -> draft
    });
  });
}
