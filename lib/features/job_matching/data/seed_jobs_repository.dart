import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;

import '../domain/job.dart';
import '../domain/jobs_repository.dart';

/// [JobsRepository] backed by a bundled JSON asset.
///
/// This is the seam for real job data: to plug in a live jobs API later, write
/// another [JobsRepository] and rebind `jobsRepositoryProvider` — nothing else
/// in the matching pipeline changes. The asset is parsed once and cached.
class SeedJobsRepository implements JobsRepository {
  SeedJobsRepository({
    AssetBundle? bundle,
    this.assetPath = 'assets/data/seed_jobs.json',
  }) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  final String assetPath;

  List<Job>? _cache;

  @override
  Future<List<Job>> fetchJobs() async {
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
}
