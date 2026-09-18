import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/application/auth_providers.dart';
import '../../../shared/models/application.dart';
import '../security/security_audit_log.dart';
import 'applicant_snapshot_builder.dart';
import 'applications_repository.dart';
import 'firestore_applications_repository.dart';

/// The app-wide applications store — Firestore-backed, scoped to the signed-in
/// seeker.
///
/// Rebuilt on every auth change so the repository always carries the current
/// uid: signing out swaps in a repository with no uid (reads empty, writes
/// no-op) and signing in as somebody else can never surface the previous user's
/// applications. The applicant snapshot is assembled here, where provider access
/// is legitimate, and injected into the repository as a callback.
final applicationsRepositoryProvider = Provider<ApplicationsRepository>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  return FirestoreApplicationsRepository(
    applicantUid: user?.uid,
    applicantName: user?.displayName ?? '',
    snapshotBuilder: () =>
        buildApplicantSnapshot(ref, fallbackName: user?.displayName),
    audit: ref.watch(securityAuditLogProvider),
  );
});

/// Reactive view of the signed-in seeker's applications (a Firestore
/// `.snapshots()` stream, newest first).
final applicationsProvider = StreamProvider<List<Application>>(
  (ref) => ref.watch(applicationsRepositoryProvider).watchApplications(),
);

/// Job ids the user has applied to — derived so "applied" has a single source
/// of truth (the applications), consumed by the Jobs platform's badges.
final appliedJobIdsProvider = Provider<Set<String>>((ref) {
  final apps = ref.watch(applicationsProvider).valueOrNull ?? const [];
  return {for (final a in apps) a.jobId};
});
