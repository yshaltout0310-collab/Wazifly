import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/resume_analyzer/domain/resume_analysis.dart';

/// Persistence seam for the most recently produced [ResumeAnalysis].
///
/// The Resume Analyzer (Milestone 1) writes here on a successful analysis;
/// Job Matching (Milestone 2) reads from here so the user isn't asked to
/// re-upload a resume they already analyzed.
///
/// Today the only implementation is [InMemoryResumeAnalysisStore] (session
/// scoped). Adding durable persistence later — a `SharedPreferences` cache or a
/// Firestore-backed `users/{uid}` document — means writing a new
/// [ResumeAnalysisStore] and rebinding [resumeAnalysisStoreProvider]. **No
/// feature code changes**, because everything depends on this interface.
abstract interface class ResumeAnalysisStore {
  /// Returns the cached analysis, or `null` if none has been stored yet.
  ///
  /// Synchronous so a store that hydrates eagerly (in-memory today, a local
  /// cache tomorrow) can seed the controller at construction. An async-only
  /// backend (e.g. Firestore) would hydrate via [read] + a later `refresh`.
  ResumeAnalysis? read();

  /// Persists [analysis] as the latest result.
  Future<void> write(ResumeAnalysis analysis);

  /// Clears any stored analysis.
  Future<void> clear();
}

/// Default store: keeps the analysis in memory for the app session only.
class InMemoryResumeAnalysisStore implements ResumeAnalysisStore {
  ResumeAnalysis? _cached;

  @override
  ResumeAnalysis? read() => _cached;

  @override
  Future<void> write(ResumeAnalysis analysis) async => _cached = analysis;

  @override
  Future<void> clear() async => _cached = null;
}

/// The app-wide [ResumeAnalysisStore]. Swap persistence strategies by changing
/// only this binding (overridden with a fake/seed in tests).
final resumeAnalysisStoreProvider =
    Provider<ResumeAnalysisStore>((ref) => InMemoryResumeAnalysisStore());

/// Reactive view of the cached resume analysis.
///
/// Holds the latest [ResumeAnalysis] (or `null`) and mirrors every change into
/// the bound [ResumeAnalysisStore], so writes survive navigation and any future
/// durable backend is written to transparently. Widgets `watch` this to react
/// when a fresh analysis becomes available.
class LastResumeAnalysisController extends StateNotifier<ResumeAnalysis?> {
  LastResumeAnalysisController(this._store) : super(_store.read());

  final ResumeAnalysisStore _store;

  /// Records [analysis] as the latest result (in state + the store).
  Future<void> set(ResumeAnalysis analysis) async {
    state = analysis;
    await _store.write(analysis);
  }

  /// Forgets the cached analysis.
  Future<void> clearAnalysis() async {
    state = null;
    await _store.clear();
  }
}

final lastResumeAnalysisProvider =
    StateNotifierProvider<LastResumeAnalysisController, ResumeAnalysis?>(
  (ref) => LastResumeAnalysisController(ref.watch(resumeAnalysisStoreProvider)),
);
