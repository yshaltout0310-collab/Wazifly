import 'package:careerbridge/shared/models/application.dart';
import 'package:careerbridge/shared/models/job.dart';
import 'package:flutter_test/flutter_test.dart';

const _job = Job(
  id: 'j1',
  title: 'Flutter Engineer',
  company: 'Acme',
  location: 'Doha',
  employmentType: 'Full-time',
  seniority: 'Mid',
  description: 'x',
  requiredSkills: ['Flutter'],
  remote: false,
);

void main() {
  final t0 = DateTime(2026, 1, 10, 9);
  final t1 = DateTime(2026, 1, 12, 14);

  test('create() starts Pending with a single history event', () {
    final app = Application.create(id: 'a1', job: _job, now: t0);
    expect(app.status, ApplicationStatus.pending);
    expect(app.jobId, 'j1');
    expect(app.jobTitle, 'Flutter Engineer'); // denormalized snapshot
    expect(app.company, 'Acme');
    expect(app.appliedAt, t0);
    expect(app.updatedAt, t0);
    expect(app.history.single.status, ApplicationStatus.pending);
    expect(app.history.single.at, t0);
  });

  test('withStatus() appends history and bumps updatedAt', () {
    final app = Application.create(id: 'a1', job: _job, now: t0)
        .withStatus(ApplicationStatus.interview, t1);
    expect(app.status, ApplicationStatus.interview);
    expect(app.updatedAt, t1);
    expect(app.appliedAt, t0); // unchanged
    expect(app.history.map((e) => e.status),
        [ApplicationStatus.pending, ApplicationStatus.interview]);
  });

  test('toJson/fromJson round-trips', () {
    final app = Application.create(id: 'a1', job: _job, now: t0)
        .withStatus(ApplicationStatus.accepted, t1);
    final restored = Application.fromJson(app.toJson());
    expect(restored, app);
  });

  test('fromJson is defensive (snake_case, bad status, epoch millis)', () {
    final app = Application.fromJson({
      'id': 'a2',
      'job_id': 'j9',
      'job_title': 'Dev',
      'company': 'Cedar',
      'status': 'nonsense', // → pending
      'appliedAt': t0.millisecondsSinceEpoch, // int millis
      'history': const [],
    });
    expect(app.jobId, 'j9');
    expect(app.jobTitle, 'Dev');
    expect(app.status, ApplicationStatus.pending);
    expect(app.appliedAt, t0);
    expect(app.updatedAt, t0); // defaults to appliedAt when missing
    expect(app.history, isEmpty);
  });

  test('applicationStatusFromName parses names and defaults to pending', () {
    expect(applicationStatusFromName('interview'), ApplicationStatus.interview);
    expect(applicationStatusFromName('ACCEPTED'), ApplicationStatus.accepted);
    expect(applicationStatusFromName(null), ApplicationStatus.pending);
    expect(applicationStatusFromName('???'), ApplicationStatus.pending);
  });
}
