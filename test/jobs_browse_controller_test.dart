import 'dart:convert';

import 'package:careerbridge/core/services/jobs/seed_jobs_repository.dart';
import 'package:careerbridge/features/jobs/application/jobs_browse_controller.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeBundle extends CachingAssetBundle {
  _FakeBundle(this.json);
  final String json;
  @override
  Future<ByteData> load(String key) async =>
      ByteData.view(Uint8List.fromList(utf8.encode(json)).buffer);
}

const _json = '''
[
  {"id":"a","title":"Flutter Engineer","company":"Acme","location":"Doha","employmentType":"Full-time","seniority":"Mid","remote":false,"requiredSkills":["Flutter"],"description":"x"},
  {"id":"b","title":"Backend Engineer","company":"Cedar","location":"Remote","employmentType":"Contract","seniority":"Senior","remote":true,"requiredSkills":["Node.js"],"description":"x"}
]
''';

ProviderContainer _container() => ProviderContainer(overrides: [
      jobsRepositoryProvider
          .overrideWithValue(SeedJobsRepository(bundle: _FakeBundle(_json))),
    ]);

List<String> _ids(JobsBrowseState s) =>
    s.results.map((j) => j.id).toList();

void main() {
  test('loads jobs and derives filter options', () async {
    final c = _container();
    addTearDown(c.dispose);
    c.read(jobsBrowseControllerProvider); // trigger load
    await pumpEventQueue();

    final state = c.read(jobsBrowseControllerProvider);
    expect(state.status, JobsStatus.ready);
    expect(state.allJobs.length, 2);
    expect(state.typeOptions, containsAll(['Full-time', 'Contract']));
    expect(state.seniorityOptions, containsAll(['Mid', 'Senior']));
  });

  test('text search filters results', () async {
    final c = _container();
    addTearDown(c.dispose);
    final controller = c.read(jobsBrowseControllerProvider.notifier);
    await pumpEventQueue();

    controller.updateText('backend');
    await pumpEventQueue();
    expect(_ids(c.read(jobsBrowseControllerProvider)), ['b']);
  });

  test('remote filter and clearFilters', () async {
    final c = _container();
    addTearDown(c.dispose);
    final controller = c.read(jobsBrowseControllerProvider.notifier);
    await pumpEventQueue();

    controller.toggleRemote();
    await pumpEventQueue();
    expect(_ids(c.read(jobsBrowseControllerProvider)), ['b']);

    controller.clearFilters();
    await pumpEventQueue();
    expect(c.read(jobsBrowseControllerProvider).results.length, 2);
    expect(c.read(jobsBrowseControllerProvider).hasActiveFilters, isFalse);
  });
}
