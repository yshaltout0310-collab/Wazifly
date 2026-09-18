import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;

import '../../../shared/models/job.dart';
import 'job_query_filter.dart';
import 'jobs_repository.dart';

// The app-wide `jobsRepositoryProvider` binding now lives in
// `jobs_providers.dart` (it composes Firestore + this catalogue). It is
// re-exported here so every existing import of this file keeps resolving it.
export 'jobs_providers.dart';

/// [JobsRepository] backed by a bundled JSON asset.
///
/// This is the seam for real job data: to plug in a live jobs API later, write
/// another [JobsRepository] and rebind [jobsRepositoryProvider] — nothing else
/// in the app changes. The asset is parsed once and cached; search/filter and
/// by-id lookups run over that in-memory list.
class SeedJobsRepository implements JobsRepository {
  SeedJobsRepository({
    AssetBundle? bundle,
    this.assetPath = 'assets/data/seed_jobs.json',
  }) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  final String assetPath;

  List<Job>? _cache;

  Future<List<Job>> _all() async {
    final cached = _cache;
    if (cached != null) return cached;

    final raw = await _bundle.loadString(assetPath);
    final decoded = jsonDecode(raw);
    if (decoded is! List) return _cache = const [];

    final jobs = decoded
        .whereType<Map>()
        .map((e) => Job.fromJson(Map<String, dynamic>.from(e)))
        .where((j) => j.id.isNotEmpty && j.title.isNotEmpty)
        .toList(growable: false);
    return _cache = jobs;
  }

  @override
  Future<List<Job>> fetchJobs() => _all();

  @override
  Future<Job?> fetchJobById(String id) async {
    for (final j in await _all()) {
      if (j.id == id) return j;
    }
    return null;
  }

  @override
  Future<List<Job>> searchJobs(JobQuery query) async =>
      applyJobQuery(await _all(), query);
}
