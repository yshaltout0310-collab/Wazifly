import 'performance_monitor.dart';

/// Inert [PerfTrace] — does nothing.
class NoopPerfTrace implements PerfTrace {
  const NoopPerfTrace();

  @override
  Future<void> start() async {}

  @override
  Future<void> stop() async {}

  @override
  void putMetric(String name, int value) {}

  @override
  void incrementMetric(String name, int value) {}

  @override
  void putAttribute(String name, String value) {}
}

/// Inert [PerformanceMonitor] for tests, debug, and unconfigured runs.
class NoopPerformanceMonitor implements PerformanceMonitor {
  const NoopPerformanceMonitor();

  @override
  PerfTrace newTrace(String name) => const NoopPerfTrace();

  @override
  Future<void> setEnabled(bool enabled) async {}
}
