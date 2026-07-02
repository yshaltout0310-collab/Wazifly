import 'dart:convert';

import 'package:careerbridge/core/services/jobs/jobs_repository.dart';
import 'package:careerbridge/core/services/jobs/seed_jobs_repository.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Serves a fixed JSON string as if it were the bundled asset.
class _FakeBundle extends CachingAssetBundle {
  _FakeBundle(this.json);
  final String json;
  @override
  Future<ByteData> load(String key) async {
    final bytes = Uint8List.fromList(utf8.encode(json));
    return ByteData.view(bytes.buffer);
  }
}

const _json = '''
[
  {"id":"a","title":"Flutter Engineer","company":"Acme","location":"Doha","employmentType":"Full-time","seniority":"Mid","remote":false,"requiredSkills":["Flutter","Dart"],"description":"x"},
  {"id":"b","title":"Backend Engineer","company":"Cedar","location":"Remote","employmentType":"Contract","seniority":"Senior","remote":true,"requiredSkills":["Node.js"],"description":"x"},
  {"id":"c","title":"iOS Developer","company":"Acme","location":"Dubai","employmentType":"Full-time","seniority":"Mid","remote":false,"requiredSkills":["Swift"],"description":"x"}
]
''';

SeedJobsRepository _repo() => SeedJobsRepository(bundle: _FakeBundle(_json));

Future<List<String>> _ids(Future<List<dynamic>> jobs) async =>
    (await jobs).map((j) => j.id as String).toList();

void main() {
  test('fetchJobs parses the asset', () async {
    expect((await _repo().fetchJobs()).length, 3);
  });

  test('fetchJobById returns the job or null', () async {
    final repo = _repo();
    expect((await repo.fetchJobById('b'))?.title, 'Backend Engineer');
    expect(await repo.fetchJobById('zzz'), isNull);
  });

  test('searchJobs matches text on title/company/skill', () async {
    final repo = _repo();
    expect(await _ids(repo.searchJobs(const JobQuery(text: 'flutter'))), ['a']);
    expect(await _ids(repo.searchJobs(const JobQuery(text: 'acme'))), ['a', 'c']);
    expect(await _ids(repo.searchJobs(const JobQuery(text: 'swift'))), ['c']);
  });

  test('searchJobs applies remote / type / seniority filters', () async {
    final repo = _repo();
    expect(await _ids(repo.searchJobs(const JobQuery(remoteOnly: true))), ['b']);
    expect(
        await _ids(
            repo.searchJobs(const JobQuery(employmentTypes: {'Full-time'}))),
        ['a', 'c']);
    expect(
        await _ids(repo.searchJobs(const JobQuery(seniorities: {'Senior'}))),
        ['b']);
  });

  test('searchJobs combines filters (AND)', () async {
    final repo = _repo();
    final ids = await _ids(repo.searchJobs(
        const JobQuery(text: 'engineer', employmentTypes: {'Contract'})));
    expect(ids, ['b']);
  });

  test('searchJobs paginates with offset/limit', () async {
    final repo = _repo();
    expect(await _ids(repo.searchJobs(const JobQuery(limit: 2))), ['a', 'b']);
    expect(await _ids(repo.searchJobs(const JobQuery(offset: 1))), ['b', 'c']);
  });

  test('empty query returns everything', () async {
    expect((await _repo().searchJobs(const JobQuery())).length, 3);
  });
}
