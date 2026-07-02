import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/job.dart';
import 'jobs_repository.dart';

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
  Future<List<Job>> searchJobs(JobQuery query) async {
    final text = query.text.trim().toLowerCase();
    final loc = query.location?.trim().toLowerCase();

    var jobs = (await _all()).where((j) {
      if (query.remoteOnly && !j.remote) return false;
      if (query.employmentTypes.isNotEmpty &&
          !query.employmentTypes.contains(j.employmentType)) {
        return false;
      }
      if (query.seniorities.isNotEmpty &&
          !query.seniorities.contains(j.seniority)) {
        return false;
      }
      if (loc != null && loc.isNotEmpty &&
          !j.location.toLowerCase().contains(loc)) {
        return false;
      }
      if (text.isNotEmpty && !_matchesText(j, text)) return false;
      return true;
    }).toList(growable: false);

    // Pagination (optional).
    if (query.offset > 0) {
      jobs = jobs.length > query.offset
          ? jobs.sublist(query.offset)
          : const [];
    }
    final limit = query.limit;
    if (limit != null && jobs.length > limit) {
      jobs = jobs.sublist(0, limit);
    }
    return jobs;
  }

  bool _matchesText(Job j, String text) {
    if (j.title.toLowerCase().contains(text)) return true;
    if (j.company.toLowerCase().contains(text)) return true;
    if (j.location.toLowerCase().contains(text)) return true;
    for (final s in j.requiredSkills) {
      if (s.toLowerCase().contains(text)) return true;
    }
    return false;
  }
}

/// The app-wide jobs source. Bundled seed data today; swap the binding to plug
/// in a real jobs API later (both the Jobs platform and Job Matching use this).
final jobsRepositoryProvider =
    Provider<JobsRepository>((ref) => SeedJobsRepository());
