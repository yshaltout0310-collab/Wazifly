/// Coarse network reachability.
enum ConnectivityStatus { online, offline }

/// Provider-agnostic network-reachability signal.
///
/// Deliberately **plugin-free** (the impl uses `dart:io`, not
/// `connectivity_plus`, to avoid the native/KGP-Gradle risk — HANDOFF §10) and
/// **advisory only**: it drives an ambient offline banner but never gates any
/// feature (a captive portal / flaky lookup must not break the app). Swap the
/// backend by rebinding `connectivityServiceProvider` — the `AiService` pattern.
abstract interface class ConnectivityService {
  /// Emits whenever reachability changes (de-duplicated). Starts by emitting the
  /// first observed status.
  Stream<ConnectivityStatus> watch();

  /// One-shot best-effort check.
  Future<ConnectivityStatus> check();
}
