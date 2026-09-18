import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../security/security_audit_log.dart';
import 'composite_jobs_repository.dart';
import 'firestore_jobs_repository.dart';
import 'jobs_repository.dart';
import 'seed_jobs_repository.dart';

/// Whether the bundled demo catalogue is appended after the live Firestore
/// postings in the seeker's browse/search/matching experience.
///
/// `true` (today) keeps the 18-job demo catalogue visible so the app is never
/// empty on a fresh project or offline. Flip to `false` for a pure production
/// marketplace in which the seeker only ever sees jobs employers have actually
/// published. This is the only switch — see [CompositeJobsRepository].
const bool kIncludeDemoJobCatalogue = true;

/// The app-wide jobs source for every seeker-facing surface: browse, search,
/// job detail, AI job matching, recommendations and internships.
///
/// Live Firestore postings first (source of truth), bundled demo catalogue
/// behind them. Rebind this one provider to change where jobs come from —
/// no feature code changes.
final jobsRepositoryProvider = Provider<JobsRepository>((ref) {
  final audit = ref.watch(securityAuditLogProvider);
  return CompositeJobsRepository(
    live: FirestoreJobsRepository(null, audit),
    fallback: SeedJobsRepository(),
    includeFallbackCatalogue: kIncludeDemoJobCatalogue,
  );
});
