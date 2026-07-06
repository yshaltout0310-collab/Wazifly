import 'package:careerbridge/core/services/activity/employer_activity_repository.dart';
import 'package:careerbridge/core/services/activity/in_memory_employer_activity_repository.dart';
import 'package:careerbridge/core/services/applications/employer_applicants_repository.dart';
import 'package:careerbridge/core/services/applications/in_memory_employer_applicants_repository.dart';
import 'package:careerbridge/features/auth/application/auth_providers.dart';
import 'package:careerbridge/features/employer/application/employer_applicants_controller.dart';
import 'package:careerbridge/shared/models/app_user.dart';
import 'package:careerbridge/shared/models/application.dart';
import 'package:careerbridge/shared/models/employer_activity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_auth.dart';

const _user = AppUser(uid: 'emp1', method: AuthMethod.email, email: 'e@b.co');

Application _app(String id,
        {ApplicationStatus status = ApplicationStatus.pending}) =>
    Application(
      id: id,
      jobId: 'job1',
      jobTitle: 'Flutter Engineer',
      company: 'Acme',
      location: 'Doha',
      status: status,
      appliedAt: DateTime(2026, 7, 1),
      updatedAt: DateTime(2026, 7, 1),
      history: [
        ApplicationEvent(status: status, at: DateTime(2026, 7, 1)),
      ],
      applicantUid: 'seeker_$id',
      ownerUid: 'emp1',
    );

class _ThrowingRepo implements EmployerApplicantsRepository {
  @override
  Future<void> updateApplication(Application a) async => throw 'boom';
  @override
  Future<Application?> fetchApplicant(String id) async => null;
  @override
  Stream<List<Application>> watchApplicants(String ownerUid) =>
      Stream.value(const []);
}

({ProviderContainer container, InMemoryEmployerActivityRepository activity})
    _make(EmployerApplicantsRepository repo) {
  final activity = InMemoryEmployerActivityRepository();
  final container = ProviderContainer(overrides: [
    authRepositoryProvider.overrideWithValue(FakeAuthRepository(user: _user)),
    employerApplicantsRepositoryProvider.overrideWithValue(repo),
    employerActivityRepositoryProvider.overrideWithValue(activity),
  ]);
  addTearDown(container.dispose);
  return (container: container, activity: activity);
}

void main() {
  test('moveToInterview persists, appends history, clears overlay, logs activity',
      () async {
    final repo = InMemoryEmployerApplicantsRepository(seed: [_app('a')]);
    final (:container, :activity) = _make(repo);
    await container
        .read(employerApplicantsControllerProvider.notifier)
        .moveToInterview(_app('a'));

    final stored = await repo.fetchApplicant('a');
    expect(stored?.status, ApplicationStatus.interview);
    expect(stored?.history.length, 2); // appended, not replaced
    final state = container.read(employerApplicantsControllerProvider);
    expect(state.failure, isNull);
    expect(state.overrides, isEmpty);
    expect(state.pending, isEmpty);
    await Future<void>.delayed(Duration.zero);
    expect(activity.logged.map((e) => e.type),
        contains(EmployerActivityType.statusInterview));
  });

  test('reject stores the reason on the appended event', () async {
    final repo = InMemoryEmployerApplicantsRepository(seed: [_app('a')]);
    final (:container, :activity) = _make(repo);
    await container
        .read(employerApplicantsControllerProvider.notifier)
        .reject(_app('a'), reason: 'Not a fit');
    final stored = await repo.fetchApplicant('a');
    expect(stored?.status, ApplicationStatus.rejected);
    expect(stored?.history.last.note, 'Not a fit');
  });

  test('a write failure rolls back the overlay and surfaces a failure', () async {
    final (:container, :activity) = _make(_ThrowingRepo());
    await container
        .read(employerApplicantsControllerProvider.notifier)
        .accept(_app('a'));
    final state = container.read(employerApplicantsControllerProvider);
    expect(state.failure, ApplicantsActionFailure.unknown);
    expect(state.overrides, isEmpty);
    expect(state.pending, isEmpty);
    // No activity is recorded on failure.
    expect(activity.logged, isEmpty);
  });

  test('an illegal transition is a no-op', () async {
    final repo = InMemoryEmployerApplicantsRepository(
        seed: [_app('a', status: ApplicationStatus.accepted)]);
    final (:container, :activity) = _make(repo);
    // accepted cannot move straight to interview.
    await container
        .read(employerApplicantsControllerProvider.notifier)
        .moveToInterview(_app('a', status: ApplicationStatus.accepted));
    expect((await repo.fetchApplicant('a'))?.status,
        ApplicationStatus.accepted);
  });
}
