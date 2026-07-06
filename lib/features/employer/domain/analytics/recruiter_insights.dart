import 'package:equatable/equatable.dart';

/// Relative importance of a suggested recruiter action. Bad/unknown → [medium].
/// Kept local to the employer domain (not reusing the recommendations feature's
/// `RecPriority`) so there is no feature-to-feature coupling.
enum InsightPriority {
  high,
  medium,
  low;

  static InsightPriority fromName(Object? value) {
    final v = _norm(value);
    for (final p in InsightPriority.values) {
      if (p.name == v) return p;
    }
    if (v.contains('urgent') || v.contains('critical') || v.contains('top')) {
      return InsightPriority.high;
    }
    if (v.contains('minor') || v.contains('optional') || v.contains('low')) {
      return InsightPriority.low;
    }
    return InsightPriority.medium;
  }
}

/// A single observation (a strength or a bottleneck): a short [title] and a
/// grounded [detail] explaining it.
class InsightItem extends Equatable {
  const InsightItem({this.title = '', this.detail = ''});

  final String title;
  final String detail;

  bool get isEmpty => title.isEmpty && detail.isEmpty;

  Map<String, dynamic> toJson() => {'title': title, 'detail': detail};

  factory InsightItem.fromJson(Map<String, dynamic> json) => InsightItem(
        title: _str(json['title'] ?? json['name'] ?? json['point']),
        detail: _str(json['detail'] ?? json['description'] ?? json['reason'] ??
            json['why']),
      );

  @override
  List<Object?> get props => [title, detail];
}

/// A concrete, prioritized recommendation for the recruiter.
class InsightAction extends Equatable {
  const InsightAction({
    this.title = '',
    this.detail = '',
    this.priority = InsightPriority.medium,
  });

  final String title;
  final String detail;
  final InsightPriority priority;

  bool get isEmpty => title.isEmpty && detail.isEmpty;

  Map<String, dynamic> toJson() =>
      {'title': title, 'detail': detail, 'priority': priority.name};

  factory InsightAction.fromJson(Map<String, dynamic> json) => InsightAction(
        title: _str(json['title'] ?? json['action'] ?? json['name']),
        detail: _str(json['detail'] ?? json['description'] ?? json['reason'] ??
            json['why']),
        priority: InsightPriority.fromName(json['priority']),
      );

  @override
  List<Object?> get props => [title, detail, priority];
}

/// The AI "Recruiter Insights" result over an employer's hiring analytics: a
/// short narrative plus what's going well, where the pipeline is stuck, and what
/// to do next. Denormalized + defensively (de)serialized so it round-trips to a
/// future Firestore `companies/{id}/insights/latest` document unchanged.
/// [sourceSignature] fingerprints the analytics it was built from, so a refresh
/// can skip the AI call when nothing has changed (mirrors `Recommendations`).
class RecruiterInsights extends Equatable {
  const RecruiterInsights({
    this.generatedAt,
    this.sourceSignature = '',
    this.headline = '',
    this.summary = '',
    this.strengths = const [],
    this.bottlenecks = const [],
    this.suggestedActions = const [],
  });

  final DateTime? generatedAt;
  final String sourceSignature;
  final String headline;
  final String summary;
  final List<InsightItem> strengths;
  final List<InsightItem> bottlenecks;
  final List<InsightAction> suggestedActions;

  bool get hasContent =>
      summary.isNotEmpty ||
      strengths.isNotEmpty ||
      bottlenecks.isNotEmpty ||
      suggestedActions.isNotEmpty;

  /// Stamps the parsed result with its generation time + source fingerprint
  /// (the repository stays pure; the controller owns the clock + signature).
  RecruiterInsights stamp({
    required DateTime generatedAt,
    required String sourceSignature,
  }) =>
      RecruiterInsights(
        generatedAt: generatedAt,
        sourceSignature: sourceSignature,
        headline: headline,
        summary: summary,
        strengths: strengths,
        bottlenecks: bottlenecks,
        suggestedActions: suggestedActions,
      );

  Map<String, dynamic> toJson() => {
        'generatedAt': generatedAt?.toIso8601String(),
        'sourceSignature': sourceSignature,
        'headline': headline,
        'summary': summary,
        'strengths': strengths.map((e) => e.toJson()).toList(),
        'bottlenecks': bottlenecks.map((e) => e.toJson()).toList(),
        'suggestedActions': suggestedActions.map((e) => e.toJson()).toList(),
      };

  factory RecruiterInsights.fromJson(Map<String, dynamic> json) =>
      RecruiterInsights(
        generatedAt: _date(json['generatedAt'] ?? json['generated_at']),
        sourceSignature:
            _str(json['sourceSignature'] ?? json['source_signature']),
        headline: _str(json['headline'] ?? json['greeting']),
        summary: _str(json['summary'] ?? json['overview']),
        strengths: _list(json['strengths'] ?? json['whatsWorking'],
            InsightItem.fromJson, (e) => e.isEmpty),
        bottlenecks: _list(json['bottlenecks'] ?? json['issues'] ?? json['risks'],
            InsightItem.fromJson, (e) => e.isEmpty),
        suggestedActions: _list(
            json['suggestedActions'] ??
                json['suggested_actions'] ??
                json['actions'] ??
                json['recommendations'],
            InsightAction.fromJson,
            (e) => e.isEmpty),
      );

  @override
  List<Object?> get props => [
        generatedAt,
        sourceSignature,
        headline,
        summary,
        strengths,
        bottlenecks,
        suggestedActions,
      ];
}

// --- shared parsers ---

String _norm(Object? value) =>
    value?.toString().toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '') ?? '';

String _str(Object? value) => value?.toString().trim() ?? '';

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
