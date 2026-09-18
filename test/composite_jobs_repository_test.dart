// The seeker's job catalogue: live Firestore postings composed with the bundled
// demo catalogue.
//
// These cover the behaviour that makes an employer's job visible to a seeker —
// the single most important link in the marketplace loop — plus the ownership
// projection an application depends on.
import 'package:careerbridge/core/services/jobs/composite_jobs_repository.dart';
import 'package:careerbridge/core/services/jobs/jobs_repository.dart';
import 'package:careerbridge/features/employer/domain/job_status.dart';
import 'package:careerbridge/shared/models/job.dart';
import 'package:careerbridge/shared/models/job_posting.dart';
import 'package:flutter_test/flutter_test.dart';

/// A [JobsRepository] over a fixed list — stands in for either source.
class _StaticJobs implements JobsRepository {
  _StaticJobs(this.jobs);

  final List<Job> jobs;

  @override
  Future<List<Job>> fetchJobs() async => jobs;

  @override
  Future<Job?> fetchJobById(String id) async {
    for (final j in jobs) {
      if (j.id == id) return j;
    }
    return null;
  }

  @override
  Future<List<Job>> searchJobs(JobQuery query) async => jobs;
}

Job _job(
  String id, {
  String title = 'Engineer',
  String company = 'Acme',
  String location = 'Doha',
  String ownerUid = '',
  bool remote = false,
  String employmentType = 'Full-time',
  String seniority = 'Mid',
  List<String> skills = const ['Dart'],
}) =>
    Job(
      id: id,
      title: title,
      company: company,
      location: location,
      employmentType: employmentType,
      seniority: seniority,
      description: 'd',
      requiredSkills: skills,
      remote: remote,
      ownerUid: ownerUid,
      companyId: ownerUid,
    );

void main() {
  group('JobPosting.toJob — ownership projection', () {
    test('carries ownerUid/companyId so an application can reach the employer',
        () {
      const posting = JobPosting(
        id: 'j1',
        companyId: 'company1',
        ownerUid: 'employer1',
        companyName: 'Acme',
        title: 'Flutter Engineer',
        status: JobStatus.published,
      );

      final job = posting.toJob();

      expect(job.ownerUid, 'employer1');
      expect(job.companyId, 'company1');
      expect(job.hasEmployer, isTrue);
      expect(job.company, 'Acme');
      expect(job.title, 'Flutter Engineer');
    });

    test('a job with no employer behind it reports hasEmployer false', () {
      expect(_job('seed1').hasEmployer, isFalse);
    });

    test('Job.fromJson round-trips the ownership fields', () {
      final job = Job.fromJson(const {
        'id': 'j1',
        'title': 't',
        'company': 'c',
        'ownerUid': 'employer1',
        'companyId': 'company1',
      });
      expect(job.ownerUid, 'employer1');
      expect(job.companyId, 'company1');
    });

    test('Job.fromJson defaults ownership to empty when absent', () {
      final job = Job.fromJson(const {'id': 'j1', 'title': 't'});
      expect(job.ownerUid, isEmpty);
      expect(job.hasEmployer, isFalse);
    });
  });

  group('CompositeJobsRepository', () {
    test('an employer-published job is visible to the seeker, listed first',
        () async {
      final repo = CompositeJobsRepository(
        live: _StaticJobs([_job('live1', ownerUid: 'employer1')]),
        fallback: _StaticJobs([_job('seed1'), _job('seed2')]),
      );

      final jobs = await repo.fetchJobs();

      expect(jobs.map((j) => j.id), ['live1', 'seed1', 'seed2']);
      expect(jobs.first.hasEmployer, isTrue);
    });

    test('the demo catalogue still shows when no employer has published',
        () async {
      final repo = CompositeJobsRepository(
        live: _StaticJobs(const []),
        fallback: _StaticJobs([_job('seed1')]),
      );
      expect((await repo.fetchJobs()).map((j) => j.id), ['seed1']);
    });

    test('a live posting wins over a demo job sharing its id', () async {
      final repo = CompositeJobsRepository(
        live: _StaticJobs([_job('dup', company: 'Live')]),
        fallback: _StaticJobs([_job('dup', company: 'Demo')]),
      );
      final jobs = await repo.fetchJobs();
      expect(jobs, hasLength(1));
      expect(jobs.single.company, 'Live');
    });

    test('with the demo catalogue disabled only live postings are served',
        () async {
      final repo = CompositeJobsRepository(
        live: _StaticJobs([_job('live1', ownerUid: 'e1')]),
        fallback: _StaticJobs([_job('seed1')]),
        includeFallbackCatalogue: false,
      );
      expect((await repo.fetchJobs()).map((j) => j.id), ['live1']);
      expect(await repo.fetchJobById('seed1'), isNull);
    });

    test('fetchJobById resolves from either source', () async {
      final repo = CompositeJobsRepository(
        live: _StaticJobs([_job('live1', ownerUid: 'e1')]),
        fallback: _StaticJobs([_job('seed1')]),
      );
      expect((await repo.fetchJobById('live1'))?.ownerUid, 'e1');
      expect((await repo.fetchJobById('seed1'))?.id, 'seed1');
      expect(await repo.fetchJobById('nope'), isNull);
    });

    test('search filters across the merged catalogue, not one source', () async {
      final repo = CompositeJobsRepository(
        live: _StaticJobs([_job('live1', title: 'Flutter Engineer')]),
        fallback: _StaticJobs([_job('seed1', title: 'Flutter Designer')]),
      );
      final results = await repo.searchJobs(const JobQuery(text: 'flutter'));
      expect(results.map((j) => j.id), ['live1', 'seed1']);
    });

    test('search applies filters to live postings too', () async {
      final repo = CompositeJobsRepository(
        live: _StaticJobs([
          _job('live1', remote: true, ownerUid: 'e1'),
          _job('live2', ownerUid: 'e1'),
        ]),
        fallback: _StaticJobs(const []),
      );
      final results = await repo.searchJobs(const JobQuery(remoteOnly: true));
      expect(results.map((j) => j.id), ['live1']);
    });
  });
}
