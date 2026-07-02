import '../../../shared/models/job.dart';

/// A search/filter request over the jobs source.
///
/// A provider-neutral value object: `SeedJobsRepository` applies it in memory
/// today; a future `RemoteJobsRepository` maps it to HTTP query params. All
/// fields are optional — an empty [JobQuery] matches everything.
class JobQuery {
  const JobQuery({
    this.text = '',
    this.employmentTypes = const {},
    this.seniorities = const {},
    this.remoteOnly = false,
    this.location,
    this.limit,
    this.offset = 0,
  });

  /// Free-text matched against title / company / skills / location.
  final String text;

  /// If non-empty, keep only jobs whose employmentType is in this set.
  final Set<String> employmentTypes;

  /// If non-empty, keep only jobs whose seniority is in this set.
  final Set<String> seniorities;

  /// Keep only remote jobs when true.
  final bool remoteOnly;

  /// Substring-matched against the job location when set.
  final String? location;

  /// Optional pagination window.
  final int? limit;
  final int offset;

  bool get hasFilters =>
      text.trim().isNotEmpty ||
      employmentTypes.isNotEmpty ||
      seniorities.isNotEmpty ||
      remoteOnly ||
      (location != null && location!.trim().isNotEmpty);

  JobQuery copyWith({
    String? text,
    Set<String>? employmentTypes,
    Set<String>? seniorities,
    bool? remoteOnly,
    String? location,
    int? limit,
    int? offset,
  }) =>
      JobQuery(
        text: text ?? this.text,
        employmentTypes: employmentTypes ?? this.employmentTypes,
        seniorities: seniorities ?? this.seniorities,
        remoteOnly: remoteOnly ?? this.remoteOnly,
        location: location ?? this.location,
        limit: limit ?? this.limit,
        offset: offset ?? this.offset,
      );
}

/// Source of job postings for the whole app (browse, detail, and matching).
///
/// An interface (not a concrete class) so the current bundled seed dataset
/// (`SeedJobsRepository`) can be swapped for a real jobs API later without
/// touching any feature code. Only "give me jobs" crosses this boundary.
abstract interface class JobsRepository {
  /// Returns all available jobs. May be empty if the source has none.
  Future<List<Job>> fetchJobs();

  /// Returns the job with [id], or `null` if not found.
  Future<Job?> fetchJobById(String id);

  /// Returns jobs matching [query] (text + filters + optional pagination).
  Future<List<Job>> searchJobs(JobQuery query);
}
