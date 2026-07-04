import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/application/auth_providers.dart';
import '../../../shared/models/company.dart';
import 'firestore_company_repository.dart';

/// Reads/writes the `companies/{companyId}` document (companyId == ownerUid in
/// Milestone 1).
///
/// Feature code depends only on this interface; the concrete implementation is
/// injected via [companyRepositoryProvider]. Swap the binding for a different
/// backend (or a fake in tests) with **no feature changes** — the same seam
/// pattern as [UserProfileRepository].
abstract interface class CompanyRepository {
  /// Emits the company (or null) and every subsequent change — maps 1:1 to a
  /// Firestore document `.snapshots()` stream.
  Stream<Company?> watchCompany(String companyId);

  /// One-shot read of the company, if any.
  Future<Company?> fetchCompany(String companyId);

  /// Merges the user-editable fields into the company document.
  Future<void> saveCompany(Company company);

  /// Creates the company on first entry (idempotent), seeding contact/name from
  /// the auth identity. Safe to call whenever an employer is routed in.
  Future<void> ensureCompany(String ownerUid, {String? email, String? name});

  /// Persists a new company-logo download URL.
  Future<void> setLogoUrl(String companyId, String url);
}

/// The app-wide company repository. Backed by Firestore in production and
/// overridden with an in-memory fake in tests. Swap this one binding to change
/// the backend.
final companyRepositoryProvider = Provider<CompanyRepository>(
  (ref) => FirestoreCompanyRepository(),
);

/// Reactive view of the signed-in employer's company document.
///
/// Tracks the authenticated uid and pipes the repository's document stream, so
/// edits re-render every consumer automatically.
final companyProvider = StreamProvider<Company?>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream<Company?>.value(null);
  return ref.watch(companyRepositoryProvider).watchCompany(user.uid);
});
