import 'package:equatable/equatable.dart';

import '../../features/employer/domain/salary_period.dart';

/// An optional salary range on a job posting.
///
/// Lives in its own file (rather than inside `job_posting.dart`) so both the
/// seeker [Job] model and the employer `JobPosting` can carry it without a
/// circular import. `job_posting.dart` re-exports it for backward compatibility.
class SalaryRange extends Equatable {
  const SalaryRange({
    this.min,
    this.max,
    this.currency = 'USD',
    this.period = SalaryPeriod.yearly,
  });

  final int? min;
  final int? max;
  final String currency;
  final SalaryPeriod period;

  bool get isEmpty => min == null && max == null;

  /// Valid when non-negative and min ≤ max (either bound may be omitted).
  bool get isValid {
    if ((min ?? 0) < 0 || (max ?? 0) < 0) return false;
    if (min != null && max != null && min! > max!) return false;
    return true;
  }

  Map<String, dynamic> toJson() => {
        'min': min,
        'max': max,
        'currency': currency,
        'period': period.name,
      };

  factory SalaryRange.fromJson(Map<String, dynamic> json) => SalaryRange(
        min: _intOrNull(json['min']),
        max: _intOrNull(json['max']),
        currency: _str(json['currency']) ?? 'USD',
        period: SalaryPeriod.fromName(json['period']),
      );

  @override
  List<Object?> get props => [min, max, currency, period];
}

int? _intOrNull(Object? raw) {
  if (raw == null) return null;
  return raw is num ? raw.toInt() : int.tryParse(raw.toString());
}

String? _str(Object? raw) {
  final s = raw?.toString().trim();
  return (s == null || s.isEmpty) ? null : s;
}
