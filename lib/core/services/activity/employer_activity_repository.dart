import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/application/auth_providers.dart';
import '../../../shared/models/employer_activity.dart';
import 'firestore_employer_activity_repository.dart';

/// Owner-private employer **activity log** at `employerActivity/{id}` — the
/// foundation for future employer auditing (Milestone 3 addition #2).
///
/// Significant employer actions are recorded fire-and-forget by the controllers;
/// no UI consumes this yet. [watchActivity] is provided so a future audit screen
/// needs no data-model redesign. Every query filters on `ownerUid` to match the
/// security rule.
abstract interface class EmployerActivityRepository {
  /// Records an activity. Rethrows on failure; callers log fire-and-forget and
  /// swallow errors so auditing never breaks the primary action.
  Future<void> log(EmployerActivity activity);

  /// Emits the owner's activity, newest-first (for a future audit UI).
  Stream<List<EmployerActivity>> watchActivity(String ownerUid);
}

final employerActivityRepositoryProvider =
    Provider<EmployerActivityRepository>(
  (ref) => FirestoreEmployerActivityRepository(),
);

/// Reactive employer activity (auth-scoped) — reserved for a future audit UI.
final employerActivityProvider = StreamProvider<List<EmployerActivity>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream<List<EmployerActivity>>.value(const []);
  return ref.watch(employerActivityRepositoryProvider).watchActivity(user.uid);
});
