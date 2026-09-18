// Contract tests for the seeker's Firestore-backed applications store.
//
// The project deliberately carries no fake-Firestore dependency, so these cover
// the parts that decide correctness without a live backend:
//
//   * the deterministic document id, which is what actually prevents duplicate
//     applications;
//   * the assembly of the application document — above all the ownership fields
//     that route it to the right employer;
//   * graceful degradation when Firebase is unconfigured (the state every test
//     and a cold web boot runs in).
//
// Rules enforcement itself is asserted in firestore_rules_guard_test.dart and
// can only be executed against the emulator/production backend.
import 'package:careerbridge/core/services/applications/firestore_applications_repository.dart';
import 'package:careerbridge/shared/models/applicant_snapshot.dart';
import 'package:careerbridge/shared/models/application.dart';
import 'package:careerbridge/shared/models/job.dart';
import 'package:flutter_test/flutter_test.dart';

Job _job({
  String id = 'job1',
  String ownerUid = 'employer1',
  String companyId = 'employer1',
  String company = 'Acme',
  String employmentType = 'Full-time',
}) =>
    Job(
      id: id,
      title: 'Flutter Engineer',
      company: company,
      location: 'Doha',
      employmentType: employmentType,
      seniority: 'Mid',
      description: 'Build things',
      requiredSkills: const ['Dart'],
      remote: false,
      ownerUid: ownerUid,
      companyId: companyId,
    );

void main() {
  group('documentIdFor — duplicate prevention', () {
    test('is deterministic for the same applicant and job', () {
      expect(
        FirestoreApplicationsRepository.documentIdFor('uid1', 'job1'),
        FirestoreApplicationsRepository.documentIdFor('uid1', 'job1'),
      );
    });

    test('differs per applicant and per job', () {
      final a = FirestoreApplicationsRepository.documentIdFor('uid1', 'job1');
      expect(a,
          isNot(FirestoreApplicationsRepository.documentIdFor('uid2', 'job1')));
      expect(a,
          isNot(FirestoreApplicationsRepository.documentIdFor('uid1', 'job2')));
    });

    test('sanitizes characters Firestore forbids in a document id', () {
      final id = FirestoreApplicationsRepository.documentIdFor(
          'uid1', 'jobs/with spaces#and?slashes');
      expect(id.contains('/'), isFalse);
      expect(id.contains(' '), isFalse);
      expect(id.startsWith('uid1__'), isTrue);
    });

    test('stays within Firestore document-id length limits', () {
      final id = FirestoreApplicationsRepository.documentIdFor(
          'uid1', List.filled(2000, 'x').join());
      expect(id.length, lessThanOrEqualTo(300));
    });
  });

  group('apply — document assembly', () {
    test('binds the application to the job owner so the employer can see it',
        () async {
      final repo = FirestoreApplicationsRepository(
        applicantUid: 'seeker1',
        clock: () => DateTime(2026, 9, 15),
      );

      final app = await repo.apply(job: _job());

      expect(app.applicantUid, 'seeker1');
      expect(app.ownerUid, 'employer1', reason: 'routes to the employer list');
      expect(app.companyId, 'employer1');
      expect(app.jobId, 'job1');
      expect(app.jobTitle, 'Flutter Engineer');
      expect(app.companyName, 'Acme');
      expect(app.status, ApplicationStatus.pending,
          reason: 'the rules require a new application to start as pending');
      expect(app.appliedAt, DateTime(2026, 9, 15));
      expect(app.id, FirestoreApplicationsRepository.documentIdFor('seeker1', 'job1'));
    });

    test('records the chosen CV', () async {
      final repo = FirestoreApplicationsRepository(applicantUid: 'seeker1');
      final app = await repo.apply(job: _job(), cvId: 'cv7', cvName: 'Backend CV');
      expect(app.cvId, 'cv7');
      expect(app.cvName, 'Backend CV');
    });

    test('carries the applicant snapshot the employer UI renders', () async {
      final repo = FirestoreApplicationsRepository(
        applicantUid: 'seeker1',
        snapshotBuilder: () => const ApplicantSnapshot(
          name: 'Sara',
          headline: 'Flutter dev',
          skills: ['Dart', 'Firebase'],
          atsScore: 82,
        ),
      );

      final app = await repo.apply(job: _job());

      expect(app.applicant, isNotNull);
      expect(app.applicant!.name, 'Sara');
      expect(app.applicant!.atsScore, 82);
      expect(app.applicant!.skills, ['Dart', 'Firebase']);
    });

    test('falls back to the auth display name when no profile snapshot exists',
        () async {
      final repo = FirestoreApplicationsRepository(
        applicantUid: 'seeker1',
        applicantName: 'Youssef',
      );
      final app = await repo.apply(job: _job());
      expect(app.applicant?.name, 'Youssef');
    });

    test('a demo-catalogue job claims no employer', () async {
      // Seed jobs have no Firestore document behind them, so the application
      // must claim an EMPTY ownerUid — the security rule rejects any other value
      // for a job that does not exist.
      final repo = FirestoreApplicationsRepository(applicantUid: 'seeker1');
      final app = await repo.apply(job: _job(ownerUid: '', companyId: ''));
      expect(app.ownerUid, isEmpty);
      expect(app.companyId, isEmpty);
    });

    test('marks internship applications from the job', () async {
      final repo = FirestoreApplicationsRepository(applicantUid: 'seeker1');
      final app = await repo.apply(job: _job(employmentType: 'Internship'));
      expect(app.isInternship, isTrue);
    });
  });

  group('degradation — Firebase unconfigured or signed out', () {
    test('watchApplications emits an empty list rather than throwing', () async {
      final repo = FirestoreApplicationsRepository(applicantUid: 'seeker1');
      expect(await repo.watchApplications().first, isEmpty);
    });

    test('a signed-out repository reads empty and applies locally', () async {
      final repo = FirestoreApplicationsRepository(applicantUid: null);
      expect(await repo.watchApplications().first, isEmpty);
      final app = await repo.apply(job: _job());
      expect(app.applicantUid, isEmpty);
      expect(await repo.findByJobId('job1'), isNull);
    });

    test('blank uid is treated as signed out', () async {
      final repo = FirestoreApplicationsRepository(applicantUid: '   ');
      expect(await repo.watchApplications().first, isEmpty);
    });

    test('mutations no-op instead of crashing', () async {
      final repo = FirestoreApplicationsRepository(applicantUid: 'seeker1');
      await expectLater(
          repo.updateStatus('x', ApplicationStatus.reviewed), completes);
      await expectLater(repo.withdraw('x'), completes);
    });
  });
}
