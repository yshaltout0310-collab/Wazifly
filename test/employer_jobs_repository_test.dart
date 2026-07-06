import 'package:careerbridge/core/services/jobs/in_memory_employer_jobs_repository.dart';
import 'package:careerbridge/features/employer/domain/job_status.dart';
import 'package:careerbridge/shared/models/job_posting.dart';
import 'package:flutter_test/flutter_test.dart';

JobPosting _job(String id,
        {String company = 'c1',
        JobStatus status = JobStatus.draft,
        DateTime? updatedAt,
        DateTime? deletedAt}) =>
    JobPosting(
      id: id,
      companyId: company,
      ownerUid: company,
      title: 'Job $id',
      status: status,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );

void main() {
  test('watchJobs emits the company list, newest-updated first', () async {
    final repo = InMemoryEmployerJobsRepository(seed: [
      _job('a', updatedAt: DateTime(2026, 7, 1)),
      _job('b', updatedAt: DateTime(2026, 7, 5)),
      _job('c', company: 'other', updatedAt: DateTime(2026, 7, 9)),
    ]);
    final first = await repo.watchJobs('c1').first;
    expect(first.map((j) => j.id), ['b', 'a']); // c belongs to another company
  });

  test('watchJobs excludes soft-deleted postings', () async {
    final repo = InMemoryEmployerJobsRepository(seed: [
      _job('a', updatedAt: DateTime(2026, 7, 1)),
      _job('b', updatedAt: DateTime(2026, 7, 5), deletedAt: DateTime(2026, 7, 6)),
    ]);
    final first = await repo.watchJobs('c1').first;
    expect(first.map((j) => j.id), ['a']);
  });

  test('createJob then updateJob re-emit on the stream', () async {
    final repo = InMemoryEmployerJobsRepository();
    final emissions = <List<String>>[];
    final sub = repo
        .watchJobs('c1')
        .listen((jobs) => emissions.add(jobs.map((j) => j.id).toList()));

    await repo.createJob(_job('a', updatedAt: DateTime(2026, 7, 1)));
    await repo.updateJob(
        _job('a', status: JobStatus.published, updatedAt: DateTime(2026, 7, 2)));
    await Future<void>.delayed(Duration.zero);

    expect(emissions.last, ['a']);
    final stored = await repo.fetchJob('a');
    expect(stored?.status, JobStatus.published);
    await sub.cancel();
  });

  test('fetchJob returns a soft-deleted posting (for audit)', () async {
    final repo = InMemoryEmployerJobsRepository(seed: [
      _job('a', deletedAt: DateTime(2026, 7, 6)),
    ]);
    expect((await repo.fetchJob('a'))?.isDeleted, isTrue);
    expect(await repo.fetchJob('missing'), isNull);
  });
}
