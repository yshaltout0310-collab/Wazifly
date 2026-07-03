import 'package:careerbridge/core/services/applications/in_memory_applications_repository.dart';
import 'package:careerbridge/core/services/jobs/saved_jobs_store.dart';
import 'package:careerbridge/features/applications/application/applications_controller.dart';
import 'package:careerbridge/shared/models/application.dart';
import 'package:careerbridge/shared/models/job.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Job _job(String id, String title) => Job(
      id: id,
      title: title,
      company: 'Acme',
      location: 'Doha',
      employmentType: 'Full-time',
      seniority: 'Mid',
      description: 'x',
      requiredSkills: const ['Flutter'],
      remote: false,
    );

final _t = DateTime(2026, 1, 10);

final _apps = <Application>[
  Application.create(id: 'a1', job: _job('j1', 'Flutter Engineer'), now: _t),
  Application.create(id: 'a2', job: _job('j2', 'Backend Engineer'), now: _t)
      .withStatus(ApplicationStatus.interview, _t),
  Application.create(id: 'a3', job: _job('j3', 'iOS Developer'), now: _t)
      .withStatus(ApplicationStatus.interview, _t)
      .withStatus(ApplicationStatus.accepted, _t),
];

Future<ProviderContainer> _container({Set<String> saved = const {}}) async {
  final store = InMemorySavedJobsStore();
  await store.write(saved);
  final c = ProviderContainer(overrides: [
    applicationsProvider.overrideWith((ref) => Stream.value(_apps)),
    savedJobsStoreProvider.overrideWithValue(store),
  ]);
  await c.read(applicationsProvider.future); // ensure data is present
  return c;
}

void main() {
  test('stats: applied / saved / interviews / offers', () async {
    final c = await _container(saved: {'x', 'y'});
    addTearDown(c.dispose);

    final stats = c.read(applicationStatsProvider);
    expect(stats.applied, 3);
    expect(stats.saved, 2);
    expect(stats.interviews, 2); // a2 + a3 both reached interview (history)
    expect(stats.offers, 1); // a3 accepted
  });

  test('filter by status', () async {
    final c = await _container();
    addTearDown(c.dispose);

    c.read(applicationsFilterProvider.notifier)
        .toggleStatus(ApplicationStatus.interview);
    final ids = c.read(filteredApplicationsProvider).map((a) => a.id);
    expect(ids, ['a2']); // only current-status interview
  });

  test('filter by text (title/company)', () async {
    final c = await _container();
    addTearDown(c.dispose);

    c.read(applicationsFilterProvider.notifier).updateText('backend');
    final ids = c.read(filteredApplicationsProvider).map((a) => a.id);
    expect(ids, ['a2']);
  });

  test('no filter returns all', () async {
    final c = await _container();
    addTearDown(c.dispose);
    expect(c.read(filteredApplicationsProvider).length, 3);
  });
}
