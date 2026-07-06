import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/activity/employer_activity_repository.dart';
import '../../../core/services/applications/employer_applicants_repository.dart';
import '../../../core/services/jobs/employer_jobs_repository.dart';
import '../domain/analytics/analytics_calculator.dart';
import '../domain/analytics/employer_analytics.dart';

/// Clock seam for time-relative analytics (age-in-pipeline, weekly trend). The
/// default is `DateTime.now`; tests override this to make the derived metrics
/// deterministic.
final analyticsClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// The employer's computed [EmployerAnalytics], recomputed reactively whenever
/// the underlying jobs / applicants / activity streams emit. Reads **core
/// providers only** (no cross-feature imports); the heavy lifting lives in the
/// pure [AnalyticsCalculator].
final employerAnalyticsProvider = Provider<EmployerAnalytics>((ref) {
  final jobs = ref.watch(employerJobsProvider).valueOrNull ?? const [];
  final applicants = ref.watch(employerApplicantsProvider).valueOrNull ?? const [];
  final activity = ref.watch(employerActivityProvider).valueOrNull ?? const [];
  final now = ref.watch(analyticsClockProvider)();

  return AnalyticsCalculator.compute(
    jobs: jobs,
    applicants: applicants,
    activity: activity,
    now: now,
  );
});
