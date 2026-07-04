import 'package:equatable/equatable.dart';

/// Relative importance of a recommendation. Bad/unknown value → [medium].
enum RecPriority {
  high,
  medium,
  low;

  static RecPriority fromName(Object? value) {
    final v = _norm(value);
    for (final p in RecPriority.values) {
      if (p.name == v) return p;
    }
    if (v.contains('urgent') || v.contains('critical') || v.contains('top')) {
      return RecPriority.high;
    }
    if (v.contains('minor') || v.contains('optional')) return RecPriority.low;
    return RecPriority.medium;
  }
}

/// Practical, action-oriented time horizons for the career roadmap.
/// Bad/unknown value → [nextMonth].
enum RecHorizon {
  thisWeek,
  nextMonth,
  next3Months,
  sixToTwelveMonths;

  static RecHorizon fromName(Object? value) {
    final v = _norm(value);
    for (final h in RecHorizon.values) {
      if (_norm(h.name) == v) return h;
    }
    if (v.contains('week')) return RecHorizon.thisWeek;
    if (v.contains('quarter') || v.contains('3month')) {
      return RecHorizon.next3Months;
    }
    if (v.contains('6') || v.contains('12') || v.contains('year')) {
      return RecHorizon.sixToTwelveMonths;
    }
    if (v.contains('month')) return RecHorizon.nextMonth;
    return RecHorizon.nextMonth;
  }
}

/// The in-app action a "Next Best Action" points at. Each value (except [none])
/// maps to an existing route so the card is tappable. Unknown → [none].
enum NextActionType {
  analyzeResume,
  buildCv,
  practiceInterview,
  browseJobs,
  reviewApplications,
  completeProfile,
  applyToJob,
  learnSkill,
  none;

  static NextActionType fromName(Object? value) {
    final v = _norm(value);
    for (final t in NextActionType.values) {
      if (_norm(t.name) == v) return t;
    }
    // Tolerate a few natural aliases the model may emit.
    if (v.contains('resume') || v.contains('cvanalys')) {
      return NextActionType.analyzeResume;
    }
    if (v.contains('buildcv') || v.contains('createcv') || v.contains('cvbuild')) {
      return NextActionType.buildCv;
    }
    if (v.contains('interview')) return NextActionType.practiceInterview;
    if (v.contains('apply')) return NextActionType.applyToJob;
    if (v.contains('browse') || v.contains('search') || v.contains('findjob')) {
      return NextActionType.browseJobs;
    }
    if (v.contains('application')) return NextActionType.reviewApplications;
    if (v.contains('profile')) return NextActionType.completeProfile;
    if (v.contains('learn') || v.contains('skill') || v.contains('course')) {
      return NextActionType.learnSkill;
    }
    return NextActionType.none;
  }
}

/// A recommended job, referencing a real posting by [jobId] so the card can deep
/// link to `/jobs/:id`. Denormalizes [title]/[company] so the record is
/// self-contained (Firestore-ready) and carries a [confidence] strength (0–100)
/// plus a personalized [reason].
class JobRecommendation extends Equatable {
  const JobRecommendation({
    required this.jobId,
    this.title = '',
    this.company = '',
    this.reason = '',
    this.confidence = 0,
  });

  final String jobId;
  final String title;
  final String company;
  final String reason;
  final int confidence;

  bool get isEmpty => jobId.isEmpty && title.isEmpty;

  Map<String, dynamic> toJson() => {
        'jobId': jobId,
        'title': title,
        'company': company,
        'reason': reason,
        'confidence': confidence,
      };

  factory JobRecommendation.fromJson(Map<String, dynamic> json) =>
      JobRecommendation(
        jobId: _str(json['jobId'] ?? json['job_id'] ?? json['id']),
        title: _str(json['title'] ?? json['jobTitle'] ?? json['job_title']),
        company: _str(json['company']),
        reason: _str(json['reason'] ?? json['why'] ?? json['matchReason']),
        confidence:
            _clampScore(json['confidence'] ?? json['score'] ?? json['match']),
      );

  @override
  List<Object?> get props => [jobId, title, company, reason, confidence];
}

/// A skill worth learning, with a personalized [reason] and a [priority].
class SkillRecommendation extends Equatable {
  const SkillRecommendation({
    required this.skill,
    this.reason = '',
    this.priority = RecPriority.medium,
  });

  final String skill;
  final String reason;
  final RecPriority priority;

  bool get isEmpty => skill.isEmpty;

  Map<String, dynamic> toJson() => {
        'skill': skill,
        'reason': reason,
        'priority': priority.name,
      };

  factory SkillRecommendation.fromJson(Map<String, dynamic> json) =>
      SkillRecommendation(
        skill: _str(json['skill'] ?? json['name']),
        reason: _str(json['reason'] ?? json['why']),
        priority: RecPriority.fromName(json['priority']),
      );

  @override
  List<Object?> get props => [skill, reason, priority];
}

/// A certification to pursue, with the issuing [provider] and a [reason].
class CertificationRecommendation extends Equatable {
  const CertificationRecommendation({
    required this.name,
    this.provider = '',
    this.reason = '',
  });

  final String name;
  final String provider;
  final String reason;

  bool get isEmpty => name.isEmpty;

  Map<String, dynamic> toJson() => {
        'name': name,
        'provider': provider,
        'reason': reason,
      };

  factory CertificationRecommendation.fromJson(Map<String, dynamic> json) =>
      CertificationRecommendation(
        name: _str(json['name'] ?? json['title'] ?? json['certification']),
        provider: _str(json['provider'] ?? json['issuer'] ?? json['organization']),
        reason: _str(json['reason'] ?? json['why']),
      );

  @override
  List<Object?> get props => [name, provider, reason];
}

/// A course to take. [url] and [skill] are optional; [reason] explains the pick.
class CourseRecommendation extends Equatable {
  const CourseRecommendation({
    required this.title,
    this.provider = '',
    this.reason = '',
    this.url = '',
    this.skill = '',
  });

  final String title;
  final String provider;
  final String reason;
  final String url;
  final String skill;

  bool get isEmpty => title.isEmpty;

  Map<String, dynamic> toJson() => {
        'title': title,
        'provider': provider,
        'reason': reason,
        'url': url,
        'skill': skill,
      };

  factory CourseRecommendation.fromJson(Map<String, dynamic> json) =>
      CourseRecommendation(
        title: _str(json['title'] ?? json['name'] ?? json['course']),
        provider: _str(json['provider'] ?? json['platform']),
        reason: _str(json['reason'] ?? json['why']),
        url: _str(json['url'] ?? json['link']),
        skill: _str(json['skill']),
      );

  @override
  List<Object?> get props => [title, provider, reason, url, skill];
}

/// A single, horizon-bucketed step of the career roadmap.
class RoadmapStep extends Equatable {
  const RoadmapStep({
    this.horizon = RecHorizon.nextMonth,
    this.title = '',
    this.description = '',
    this.focusSkills = const [],
  });

  final RecHorizon horizon;
  final String title;
  final String description;
  final List<String> focusSkills;

  bool get isEmpty => title.isEmpty && description.isEmpty;

  Map<String, dynamic> toJson() => {
        'horizon': horizon.name,
        'title': title,
        'description': description,
        'focusSkills': focusSkills,
      };

  factory RoadmapStep.fromJson(Map<String, dynamic> json) => RoadmapStep(
        horizon: RecHorizon.fromName(json['horizon'] ?? json['timeframe']),
        title: _str(json['title'] ?? json['goal']),
        description: _str(json['description'] ?? json['detail'] ?? json['details']),
        focusSkills:
            _stringList(json['focusSkills'] ?? json['focus_skills'] ?? json['skills']),
      );

  @override
  List<Object?> get props => [horizon, title, description, focusSkills];
}

/// A concrete next step, typed to an in-app [type] so it can deep link, with a
/// [reason] ([description]), a [priority], and an optional [estimatedTime]
/// (e.g. "15 minutes", "2 hours"). [targetId] carries a job id for [applyToJob].
class NextAction extends Equatable {
  const NextAction({
    this.type = NextActionType.none,
    this.title = '',
    this.description = '',
    this.priority = RecPriority.medium,
    this.estimatedTime = '',
    this.targetId = '',
  });

  final NextActionType type;
  final String title;
  final String description;
  final RecPriority priority;
  final String estimatedTime;
  final String targetId;

  bool get isEmpty => title.isEmpty && description.isEmpty;

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'title': title,
        'description': description,
        'priority': priority.name,
        'estimatedTime': estimatedTime,
        'targetId': targetId,
      };

  factory NextAction.fromJson(Map<String, dynamic> json) => NextAction(
        type: NextActionType.fromName(json['type'] ?? json['action']),
        title: _str(json['title'] ?? json['action'] ?? json['label']),
        description: _str(json['description'] ?? json['reason'] ?? json['why']),
        priority: RecPriority.fromName(json['priority']),
        estimatedTime: _str(json['estimatedTime'] ??
            json['estimated_time'] ??
            json['time'] ??
            json['duration']),
        targetId: _str(json['targetId'] ?? json['target_id'] ?? json['jobId']),
      );

  @override
  List<Object?> get props =>
      [type, title, description, priority, estimatedTime, targetId];
}

/// The full personalized "For You" result — the cached record and the single
/// source of truth for the Recommendations screen. Denormalized + defensively
/// (de)serialized so it round-trips to a Firestore `users/{uid}/recommendations`
/// document unchanged. [sourceSignature] fingerprints the user data it was built
/// from, so a refresh can skip the AI call when nothing has changed.
class Recommendations extends Equatable {
  const Recommendations({
    this.generatedAt,
    this.sourceSignature = '',
    this.headline = '',
    this.summary = '',
    this.recommendedJobs = const [],
    this.skillsToLearn = const [],
    this.certifications = const [],
    this.courses = const [],
    this.careerRoadmap = const [],
    this.nextBestActions = const [],
  });

  final DateTime? generatedAt;
  final String sourceSignature;
  final String headline;
  final String summary;
  final List<JobRecommendation> recommendedJobs;
  final List<SkillRecommendation> skillsToLearn;
  final List<CertificationRecommendation> certifications;
  final List<CourseRecommendation> courses;
  final List<RoadmapStep> careerRoadmap;
  final List<NextAction> nextBestActions;

  /// True when at least one section carries something to show.
  bool get hasContent =>
      recommendedJobs.isNotEmpty ||
      skillsToLearn.isNotEmpty ||
      certifications.isNotEmpty ||
      courses.isNotEmpty ||
      careerRoadmap.isNotEmpty ||
      nextBestActions.isNotEmpty;

  /// Stamps the parsed result with its generation time + source fingerprint
  /// (the repository stays pure; the controller owns the clock + signature).
  Recommendations stamp({
    required DateTime generatedAt,
    required String sourceSignature,
  }) =>
      Recommendations(
        generatedAt: generatedAt,
        sourceSignature: sourceSignature,
        headline: headline,
        summary: summary,
        recommendedJobs: recommendedJobs,
        skillsToLearn: skillsToLearn,
        certifications: certifications,
        courses: courses,
        careerRoadmap: careerRoadmap,
        nextBestActions: nextBestActions,
      );

  Map<String, dynamic> toJson() => {
        'generatedAt': generatedAt?.toIso8601String(),
        'sourceSignature': sourceSignature,
        'headline': headline,
        'summary': summary,
        'recommendedJobs': recommendedJobs.map((e) => e.toJson()).toList(),
        'skillsToLearn': skillsToLearn.map((e) => e.toJson()).toList(),
        'certifications': certifications.map((e) => e.toJson()).toList(),
        'courses': courses.map((e) => e.toJson()).toList(),
        'careerRoadmap': careerRoadmap.map((e) => e.toJson()).toList(),
        'nextBestActions': nextBestActions.map((e) => e.toJson()).toList(),
      };

  factory Recommendations.fromJson(Map<String, dynamic> json) => Recommendations(
        generatedAt: _date(json['generatedAt'] ?? json['generated_at']),
        sourceSignature: _str(json['sourceSignature'] ?? json['source_signature']),
        headline: _str(json['headline'] ?? json['greeting']),
        summary: _str(json['summary'] ?? json['overview']),
        recommendedJobs: _list(
            json['recommendedJobs'] ?? json['recommended_jobs'] ?? json['jobs'],
            JobRecommendation.fromJson,
            (e) => e.isEmpty),
        skillsToLearn: _list(
            json['skillsToLearn'] ?? json['skills_to_learn'] ?? json['skills'],
            SkillRecommendation.fromJson,
            (e) => e.isEmpty),
        certifications: _list(json['certifications'],
            CertificationRecommendation.fromJson, (e) => e.isEmpty),
        courses: _list(
            json['courses'], CourseRecommendation.fromJson, (e) => e.isEmpty),
        careerRoadmap: _list(
            json['careerRoadmap'] ?? json['career_roadmap'] ?? json['roadmap'],
            RoadmapStep.fromJson,
            (e) => e.isEmpty),
        nextBestActions: _list(
            json['nextBestActions'] ??
                json['next_best_actions'] ??
                json['nextActions'] ??
                json['actions'],
            NextAction.fromJson,
            (e) => e.isEmpty),
      );

  @override
  List<Object?> get props => [
        generatedAt,
        sourceSignature,
        headline,
        summary,
        recommendedJobs,
        skillsToLearn,
        certifications,
        courses,
        careerRoadmap,
        nextBestActions,
      ];
}

// --- shared parsers ---

String _norm(Object? value) =>
    value?.toString().toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '') ?? '';

String _str(Object? value) => value?.toString().trim() ?? '';

int _clampScore(Object? raw) {
  final n = raw is num ? raw.toInt() : int.tryParse(raw?.toString() ?? '') ?? 0;
  return n.clamp(0, 100);
}

List<String> _stringList(Object? value) {
  if (value is List) {
    return value
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
  }
  if (value is String && value.trim().isNotEmpty) {
    return value
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }
  return const [];
}

/// Parses a JSON list into models, dropping entries that fail [isEmpty].
List<T> _list<T>(
  Object? value,
  T Function(Map<String, dynamic>) parse,
  bool Function(T) isEmpty,
) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((e) => parse(Map<String, dynamic>.from(e)))
      .where((e) => !isEmpty(e))
      .toList(growable: false);
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
