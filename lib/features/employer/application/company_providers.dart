import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/company/company_repository.dart';
import '../../../core/services/jobs/employer_jobs_repository.dart';
import '../../../shared/models/company.dart';
import '../../auth/application/auth_providers.dart';
import '../domain/company_stats.dart';
import '../domain/job_status.dart';

/// The signed-in employer's effective company: the stored document with the auth
/// email as a contact fallback (so a freshly created doc still shows a sensible
/// contact). Null when signed out.
final currentCompanyProvider = Provider<Company?>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return null;
  final stored = ref.watch(companyProvider).valueOrNull;
  final base = stored ?? Company.empty(user.uid);
  return base.copyWith(contactEmail: base.contactEmail ?? user.email);
});

/// Company completion as a percentage `[0, 100]` (0 when signed out).
final companyCompletionProvider = Provider<int>((ref) {
  return ref.watch(currentCompanyProvider)?.completionPercent ?? 0;
});

/// At-a-glance recruiting metrics for the Employer Home dashboard.
///
/// `activeJobs` derives from the employer jobs stream (published, non-deleted);
/// Applications/Interviews/Hires stay zero until the employer applicant
/// milestone wires them — the dashboard widgets need no change.
final companyStatsProvider = Provider<CompanyStats>((ref) {
  final jobs = ref.watch(employerJobsProvider).valueOrNull ?? const [];
  final active = jobs.where((j) => j.status == JobStatus.published).length;
  return CompanyStats(activeJobs: active);
});
