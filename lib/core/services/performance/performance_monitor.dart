/// A single, vendor-neutral performance trace handle. Obtained from
/// [PerformanceMonitor.newTrace]; all methods are best-effort and non-throwing.
abstract interface class PerfTrace {
  Future<void> start();
  Future<void> stop();
  void putMetric(String name, int value);
  void incrementMetric(String name, int value);
  void putAttribute(String name, String value);
}

/// Provider-agnostic performance monitoring (the single Firebase Performance
/// boundary). Only `FirebasePerformanceMonitor` imports `firebase_performance`;
/// swap the backend by rebinding `performanceMonitorProvider`.
///
/// Custom traces work at runtime without the firebase-perf Gradle plugin (which
/// only adds automatic HTTP/screen instrumentation + is deferred for AGP 9).
/// Best-effort and non-throwing per the M1 telemetry principle.
abstract interface class PerformanceMonitor {
  /// Creates a custom trace (call [PerfTrace.start] / [PerfTrace.stop] around
  /// the work you want to measure).
  PerfTrace newTrace(String name);

  /// Enables/disables collection.
  Future<void> setEnabled(bool enabled);
}
