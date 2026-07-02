import 'dart:convert';

import 'package:careerbridge/core/services/jobs/seed_jobs_repository.dart';
import 'package:careerbridge/features/jobs/application/job_detail_controller.dart';
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
  {"id":"a","title":"Flutter Engineer","company":"Acme","location":"Doha","employmentType":"Full-time","seniority":"Mid","remote":false,"requiredSkills":["Flutter"],"description":"x"}
]
''';

ProviderContainer _container() => ProviderContainer(overrides: [
      jobsRepositoryProvider
          .overrideWithValue(SeedJobsRepository(bundle: _FakeBundle(_json))),
    ]);

void main() {
  test('loads an existing job', () async {
    final c = _container();
    addTearDown(c.dispose);
    c.read(jobDetailControllerProvider('a'));
    await pumpEventQueue();

    final state = c.read(jobDetailControllerProvider('a'));
    expect(state.status, JobDetailStatus.ready);
    expect(state.job?.title, 'Flutter Engineer');
    expect(state.hasResume, isFalse); // no cached analysis
  });

  test('reports notFound for an unknown id', () async {
    final c = _container();
    addTearDown(c.dispose);
    c.read(jobDetailControllerProvider('zzz'));
    await pumpEventQueue();

    expect(c.read(jobDetailControllerProvider('zzz')).status,
        JobDetailStatus.notFound);
  });

  test('computeMatch is a no-op without a cached resume', () async {
    final c = _container();
    addTearDown(c.dispose);
    final controller = c.read(jobDetailControllerProvider('a').notifier);
    await pumpEventQueue();

    await controller.computeMatch();
    await pumpEventQueue();
    expect(
        c.read(jobDetailControllerProvider('a')).matchStatus, MatchStatus.idle);
  });
}
