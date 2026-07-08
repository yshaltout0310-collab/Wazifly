import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firebase/firebase_service.dart';
import 'noop_performance_monitor.dart';
import 'performance_monitor.dart';

/// Firebase Performance implementation of [PerformanceMonitor] — the **only**
/// file that imports `firebase_performance`. Guarded so a monitoring failure
/// never propagates.
class FirebasePerformanceMonitor implements PerformanceMonitor {
  FirebasePerformanceMonitor([FirebasePerformance? performance])
      : _performance = performance ?? FirebasePerformance.instance;

  final FirebasePerformance _performance;

  @override
  PerfTrace newTrace(String name) {
    try {
      return _FirebasePerfTrace(_performance.newTrace(name));
    } catch (e) {
      debugPrint('[Performance] newTrace failed: $e');
      return const NoopPerfTrace();
    }
  }

  @override
  Future<void> setEnabled(bool enabled) async {
    try {
      await _performance.setPerformanceCollectionEnabled(enabled);
    } catch (e) {
      debugPrint('[Performance] setEnabled failed: $e');
    }
  }
}

/// Wraps a Firebase [Trace] behind the vendor-neutral [PerfTrace]; every call is
/// guarded.
class _FirebasePerfTrace implements PerfTrace {
  _FirebasePerfTrace(this._trace);

  final Trace _trace;

  @override
  Future<void> start() async {
    try {
      await _trace.start();
    } catch (e) {
      debugPrint('[Performance] trace.start failed: $e');
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _trace.stop();
    } catch (e) {
      debugPrint('[Performance] trace.stop failed: $e');
    }
  }

  @override
  void putMetric(String name, int value) {
    try {
      _trace.setMetric(name, value);
    } catch (_) {/* best-effort */}
  }

  @override
  void incrementMetric(String name, int value) {
    try {
      _trace.incrementMetric(name, value);
    } catch (_) {/* best-effort */}
  }

  @override
  void putAttribute(String name, String value) {
    try {
      _trace.putAttribute(name, value);
    } catch (_) {/* best-effort */}
  }
}

/// The app-wide performance monitor: Firebase when ready, else an inert no-op.
final performanceMonitorProvider = Provider<PerformanceMonitor>(
  (ref) => FirebaseService.instance.isReady
      ? FirebasePerformanceMonitor()
      : const NoopPerformanceMonitor(),
);
