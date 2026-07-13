import 'dart:convert';

import 'package:careerbridge/core/providers/app_providers.dart';
import 'package:careerbridge/core/services/jobs/seed_jobs_repository.dart';
import 'package:careerbridge/core/services/storage/local_storage_service.dart';
import 'package:careerbridge/features/jobs/application/jobs_browse_controller.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeBundle extends CachingAssetBundle {
  _FakeBundle(this.json);
  final String json;
  @override
  Future<ByteData> load(String key) async =>
      ByteData.view(Uint8List.fromList(utf8.encode(json)).buffer);
}

// Job "a" is in Qatar, "b" is remote, "c" is in Egypt — so the default Qatar
// country filter keeps a + b (remote is location-agnostic) and drops c.
const _json = '''
[
  {"id":"a","title":"Flutter Engineer","company":"Acme","location":"Doha, Qatar","employmentType":"Full-time","seniority":"Mid","remote":false,"requiredSkills":["Flutter"],"description":"x"},
  {"id":"b","title":"Backend Engineer","company":"Cedar","location":"Remote","employmentType":"Contract","seniority":"Senior","remote":true,"requiredSkills":["Node.js"],"description":"x"},
  {"id":"c","title":"Data Engineer","company":"Nile","location":"Cairo, Egypt","employmentType":"Full-time","seniority":"Mid","remote":false,"requiredSkills":["SQL"],"description":"x"}
]
''';

late LocalStorageService _storage;

ProviderContainer _container() => ProviderContainer(overrides: [
      localStorageProvider.overrideWithValue(_storage),
      jobsRepositoryProvider
          .overrideWithValue(SeedJobsRepository(bundle: _FakeBundle(_json))),
    ]);

List<String> _ids(JobsBrowseState s) => s.results.map((j) => j.id).toList();

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    _storage = await LocalStorageService.create();
  });

  test('loads jobs and derives filter options', () async {
    final c = _container();
    addTearDown(c.dispose);
    c.read(jobsBrowseControllerProvider); // trigger load
    await pumpEventQueue();

    final state = c.read(jobsBrowseControllerProvider);
    expect(state.status, JobsStatus.ready);
    expect(state.allJobs.length, 3);
    expect(state.typeOptions, containsAll(['Full-time', 'Contract']));
    expect(state.seniorityOptions, containsAll(['Mid', 'Senior']));
  });

  test('defaults the location filter to the user country (Qatar)', () async {
    final c = _container();
    addTearDown(c.dispose);
    c.read(jobsBrowseControllerProvider);
    await pumpEventQueue();

    // Qatar (default) + remote pass; the Egypt job is filtered out.
    expect(_ids(c.read(jobsBrowseControllerProvider)), ['a', 'b']);
    expect(c.read(jobsBrowseControllerProvider).query.location, 'Qatar');
  });

  test('Browse defaults to Qatar even when the profile country is not Qatar',
      () async {
    // The user's device had a non-Qatar profile country persisted from
    // onboarding; Browse must still open on the Qatar market by default.
    SharedPreferences.setMockInitialValues({
      'pref_selected_country': jsonEncode({
        'isoCode': 'EG',
        'name': 'Egypt',
        'dialCode': '+20',
        'flag': '🇪🇬',
      }),
    });
    _storage = await LocalStorageService.create();

    final c = _container();
    addTearDown(c.dispose);
    c.read(jobsBrowseControllerProvider);
    await pumpEventQueue();

    expect(c.read(jobsBrowseControllerProvider).query.location, 'Qatar');
    expect(_ids(c.read(jobsBrowseControllerProvider)), ['a', 'b']);
  });

  test('setCountry widens/changes the country filter', () async {
    final c = _container();
    addTearDown(c.dispose);
    final controller = c.read(jobsBrowseControllerProvider.notifier);
    await pumpEventQueue();

    controller.setCountry('Egypt');
    await pumpEventQueue();
    // Egypt job + remote job.
    expect(_ids(c.read(jobsBrowseControllerProvider)), ['b', 'c']);

    controller.setCountry(null); // "All countries"
    await pumpEventQueue();
    expect(_ids(c.read(jobsBrowseControllerProvider)), ['a', 'b', 'c']);
  });

  test('text search filters results', () async {
    final c = _container();
    addTearDown(c.dispose);
    final controller = c.read(jobsBrowseControllerProvider.notifier);
    await pumpEventQueue();

    controller.setCountry(null); // search across all countries
    controller.updateText('backend');
    await pumpEventQueue();
    expect(_ids(c.read(jobsBrowseControllerProvider)), ['b']);
  });

  test('remote filter, then clearFilters restores the default country', () async {
    final c = _container();
    addTearDown(c.dispose);
    final controller = c.read(jobsBrowseControllerProvider.notifier);
    await pumpEventQueue();

    controller.toggleRemote();
    await pumpEventQueue();
    expect(_ids(c.read(jobsBrowseControllerProvider)), ['b']);

    controller.clearFilters();
    await pumpEventQueue();
    // Clear drops remote-only but restores the Qatar default (a + remote b).
    expect(_ids(c.read(jobsBrowseControllerProvider)), ['a', 'b']);
    expect(c.read(jobsBrowseControllerProvider).query.remoteOnly, isFalse);
    expect(c.read(jobsBrowseControllerProvider).query.location, 'Qatar');
  });
}
