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

// Job "a" is in Qatar, "b" is remote, "c" is in Egypt. Browse opens with no
// location filter, so all three are visible; "c" is the one a Qatar filter
// would drop (it is neither remote nor in Qatar).
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

  test('opens with NO location filter, so every job is visible', () async {
    final c = _container();
    addTearDown(c.dispose);
    c.read(jobsBrowseControllerProvider);
    await pumpEventQueue();

    // Browse used to default this filter to Qatar, which silently dropped every
    // non-remote job outside Qatar — including anything an employer published
    // elsewhere. A job located "Doha" does not even contain "Qatar", so real
    // postings could not be found at all.
    expect(c.read(jobsBrowseControllerProvider).query.location, isNull);
    expect(_ids(c.read(jobsBrowseControllerProvider)), ['a', 'b', 'c']);
  });

  test('a job outside Qatar is findable by text search on first load',
      () async {
    // The reported symptom, at the controller level: no filter is touched, the
    // seeker just searches.
    final c = _container();
    addTearDown(c.dispose);
    final controller = c.read(jobsBrowseControllerProvider.notifier);
    await pumpEventQueue();

    controller.updateText('data');
    await pumpEventQueue();

    expect(_ids(c.read(jobsBrowseControllerProvider)), ['c']);
  });

  test('ignores the persisted profile country', () async {
    // Browse must not inherit the onboarding country either: the filter is the
    // seeker's explicit choice in the filter sheet, nothing else.
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

    expect(c.read(jobsBrowseControllerProvider).query.location, isNull);
    expect(_ids(c.read(jobsBrowseControllerProvider)), ['a', 'b', 'c']);
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

    controller.updateText('backend');
    await pumpEventQueue();
    expect(_ids(c.read(jobsBrowseControllerProvider)), ['b']);
  });

  test('clearFilters clears the country too', () async {
    final c = _container();
    addTearDown(c.dispose);
    final controller = c.read(jobsBrowseControllerProvider.notifier);
    await pumpEventQueue();

    controller.setCountry('Qatar');
    controller.toggleRemote();
    await pumpEventQueue();
    expect(_ids(c.read(jobsBrowseControllerProvider)), ['b']);

    controller.clearFilters();
    await pumpEventQueue();

    // "Clear filters" used to re-apply the Qatar default, so the one filter the
    // seeker had not set was also the one it could not clear.
    expect(_ids(c.read(jobsBrowseControllerProvider)), ['a', 'b', 'c']);
    expect(c.read(jobsBrowseControllerProvider).query.remoteOnly, isFalse);
    expect(c.read(jobsBrowseControllerProvider).query.location, isNull);
    expect(c.read(jobsBrowseControllerProvider).query.hasFilters, isFalse);
  });
}
