import 'package:equatable/equatable.dart';

/// Whether an internship is paid or unpaid.
enum InternshipFunding {
  paid,
  unpaid;

  static InternshipFunding? fromName(Object? value) => _enumFromName(
        value,
        InternshipFunding.values,
        (e) => e.name,
        const {'stipend': InternshipFunding.paid},
      );
}

/// Broad discipline of an internship (for browse filtering).
enum InternshipCategory {
  software,
  design,
  data,
  marketing,
  business,
  engineering,
  other;

  static InternshipCategory? fromName(Object? value) =>
      _enumFromName(value, InternshipCategory.values, (e) => e.name);
}

/// Target audience of an internship by education/career stage.
///
/// Distinct from [InternshipEligibility] (who may *apply*): [InternshipLevel]
/// describes the intended candidate stage, eligibility gates the application.
enum InternshipLevel {
  highSchool,
  undergraduate,
  graduate,
  bootcamp,
  careerSwitcher;

  static InternshipLevel? fromName(Object? value) =>
      _enumFromName(value, InternshipLevel.values, (e) => e.name);
}

/// Expected internship length.
enum InternshipDuration {
  upTo1Month,
  oneToThreeMonths,
  threeToSixMonths,
  sixToTwelveMonths;

  static InternshipDuration? fromName(Object? value) =>
      _enumFromName(value, InternshipDuration.values, (e) => e.name);
}

/// Work-location arrangement (addition 1).
///
/// Finer-grained than the seeker `Job.remote` bool; the employer editor derives
/// `remote = mode != onsite` so the existing remote browse filter keeps working.
enum WorkMode {
  onsite,
  remote,
  hybrid;

  /// Whether this mode counts as "remote" for the legacy [Job.remote] bool /
  /// the seeker's `remoteOnly` filter (remote + hybrid → true).
  bool get isRemoteish => this != WorkMode.onsite;

  static WorkMode? fromName(Object? value) => _enumFromName(
        value,
        WorkMode.values,
        (e) => e.name,
        const {'on-site': WorkMode.onsite, 'on_site': WorkMode.onsite},
      );
}

/// Who may apply to an internship (addition 2).
enum InternshipEligibility {
  universityStudents,
  freshGraduates,
  openToEveryone;

  static InternshipEligibility? fromName(Object? value) =>
      _enumFromName(value, InternshipEligibility.values, (e) => e.name);
}

/// Time commitment of an internship (addition 4).
///
/// A distinct, internship-scoped enum: the general [EmploymentType] has no
/// `flexible` value and its `internship` slot is taken, so a `Job`/`JobPosting`
/// with `employmentType == internship` still needs its own schedule axis.
enum InternshipSchedule {
  fullTime,
  partTime,
  flexible;

  static InternshipSchedule? fromName(Object? value) => _enumFromName(
        value,
        InternshipSchedule.values,
        (e) => e.name,
        const {
          'full-time': InternshipSchedule.fullTime,
          'part-time': InternshipSchedule.partTime,
        },
      );
}

/// Optional internship-specific metadata embedded on a [Job] / `JobPosting`.
///
/// Present only when the posting is an internship. Embedded exactly like
/// `SalaryRange`/`JobMetrics` on `JobPosting` — additive and fully defensive, so
/// a posting with no internship map (or a partial one) round-trips without
/// throwing. Lives in `shared/models` (with its enums) so the seeker [Job] can
/// embed it **without** importing any `features/employer` code — preserving the
/// seeker→employer decoupling rule.
class InternshipDetails extends Equatable {
  const InternshipDetails({
    this.funding,
    this.category,
    this.level,
    this.duration,
    this.workMode,
    this.eligibility,
    this.schedule,
    this.certificateProvided = false,
    this.stipendAmount,
    this.currency = 'USD',
    this.startDate,
    this.applicationDeadline,
  });

  final InternshipFunding? funding;
  final InternshipCategory? category;
  final InternshipLevel? level;
  final InternshipDuration? duration;

  /// Addition 1 — remote / hybrid / on-site.
  final WorkMode? workMode;

  /// Addition 2 — university students only / fresh graduates / open to everyone.
  final InternshipEligibility? eligibility;

  /// Addition 4 — full-time / part-time / flexible.
  final InternshipSchedule? schedule;

  /// Addition 3 — whether a completion certificate is provided.
  final bool certificateProvided;

  /// Optional stipend (only meaningful when [funding] is paid).
  final int? stipendAmount;
  final String currency;

  /// Addition 5 — important dates.
  final DateTime? startDate;
  final DateTime? applicationDeadline;

  /// True when no field carries information (a blank internship block).
  bool get isEmpty =>
      funding == null &&
      category == null &&
      level == null &&
      duration == null &&
      workMode == null &&
      eligibility == null &&
      schedule == null &&
      !certificateProvided &&
      stipendAmount == null &&
      startDate == null &&
      applicationDeadline == null;

  bool get isPaid => funding == InternshipFunding.paid;

  InternshipDetails copyWith({
    InternshipFunding? funding,
    InternshipCategory? category,
    InternshipLevel? level,
    InternshipDuration? duration,
    WorkMode? workMode,
    InternshipEligibility? eligibility,
    InternshipSchedule? schedule,
    bool? certificateProvided,
    int? stipendAmount,
    String? currency,
    DateTime? startDate,
    DateTime? applicationDeadline,
    bool clearFunding = false,
    bool clearCategory = false,
    bool clearLevel = false,
    bool clearDuration = false,
    bool clearWorkMode = false,
    bool clearEligibility = false,
    bool clearSchedule = false,
    bool clearStipend = false,
    bool clearStartDate = false,
    bool clearApplicationDeadline = false,
  }) =>
      InternshipDetails(
        funding: clearFunding ? null : (funding ?? this.funding),
        category: clearCategory ? null : (category ?? this.category),
        level: clearLevel ? null : (level ?? this.level),
        duration: clearDuration ? null : (duration ?? this.duration),
        workMode: clearWorkMode ? null : (workMode ?? this.workMode),
        eligibility:
            clearEligibility ? null : (eligibility ?? this.eligibility),
        schedule: clearSchedule ? null : (schedule ?? this.schedule),
        certificateProvided: certificateProvided ?? this.certificateProvided,
        stipendAmount:
            clearStipend ? null : (stipendAmount ?? this.stipendAmount),
        currency: currency ?? this.currency,
        startDate: clearStartDate ? null : (startDate ?? this.startDate),
        applicationDeadline: clearApplicationDeadline
            ? null
            : (applicationDeadline ?? this.applicationDeadline),
      );

  Map<String, dynamic> toJson() => {
        'funding': funding?.name,
        'category': category?.name,
        'level': level?.name,
        'duration': duration?.name,
        'workMode': workMode?.name,
        'eligibility': eligibility?.name,
        'schedule': schedule?.name,
        'certificateProvided': certificateProvided,
        'stipendAmount': stipendAmount,
        'currency': currency,
        'startDate': startDate?.toIso8601String(),
        'applicationDeadline': applicationDeadline?.toIso8601String(),
      };

  factory InternshipDetails.fromJson(Map<String, dynamic> json) =>
      InternshipDetails(
        funding: InternshipFunding.fromName(json['funding']),
        category: InternshipCategory.fromName(json['category']),
        level: InternshipLevel.fromName(json['level']),
        duration: InternshipDuration.fromName(json['duration']),
        workMode: WorkMode.fromName(json['workMode'] ?? json['work_mode']),
        eligibility: InternshipEligibility.fromName(json['eligibility']),
        schedule: InternshipSchedule.fromName(json['schedule']),
        certificateProvided: json['certificateProvided'] == true ||
            json['certificate_provided'] == true,
        stipendAmount: _intOrNull(json['stipendAmount'] ?? json['stipend_amount']),
        currency: _str(json['currency']) ?? 'USD',
        startDate: _date(json['startDate'] ?? json['start_date']),
        applicationDeadline:
            _date(json['applicationDeadline'] ?? json['application_deadline']),
      );

  @override
  List<Object?> get props => [
        funding,
        category,
        level,
        duration,
        workMode,
        eligibility,
        schedule,
        certificateProvided,
        stipendAmount,
        currency,
        startDate,
        applicationDeadline,
      ];
}

// --- shared parsers ---

/// Tolerant enum parse: matches an enum by its [name] (case-insensitive),
/// with an optional [aliases] map for canonical/human strings.
T? _enumFromName<T>(
  Object? value,
  List<T> values,
  String Function(T) name, [
  Map<String, T> aliases = const {},
]) {
  if (value is! String) return null;
  final v = value.trim().toLowerCase();
  if (v.isEmpty) return null;
  final alias = aliases[v];
  if (alias != null) return alias;
  for (final e in values) {
    if (name(e).toLowerCase() == v) return e;
  }
  return null;
}

String? _str(Object? value) {
  if (value == null) return null;
  final s = value.toString().trim();
  return s.isEmpty ? null : s;
}

int? _intOrNull(Object? raw) {
  if (raw == null) return null;
  return raw is num ? raw.toInt() : int.tryParse(raw.toString());
}

DateTime? _date(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is String) return DateTime.tryParse(value);
  try {
    final result = (value as dynamic).toDate();
    if (result is DateTime) return result;
  } catch (_) {/* not a Timestamp */}
  return null;
}
