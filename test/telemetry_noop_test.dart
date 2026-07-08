import 'package:careerbridge/core/services/analytics/noop_analytics_service.dart';
import 'package:careerbridge/core/services/crashlytics/noop_crash_reporter.dart';
import 'package:careerbridge/core/services/performance/noop_performance_monitor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('NoopAnalyticsService never throws', () async {
    const a = NoopAnalyticsService();
    await a.logScreenView('home');
    await a.logEvent('job_apply', parameters: {'job_id': '1'});
    await a.setUserId('u');
    await a.setUserProperty(name: 'account_type', value: 'employer');
    await a.setEnabled(false);
  });

  test('NoopCrashReporter never throws', () async {
    const r = NoopCrashReporter();
    await r.recordError(Exception('x'), StackTrace.current, fatal: true);
    await r.log('breadcrumb');
    await r.setUserIdentifier('u');
    await r.setCustomKey('account_type', 'jobSeeker');
    await r.setEnabled(true);
  });

  test('NoopPerformanceMonitor returns an inert trace', () async {
    const m = NoopPerformanceMonitor();
    final t = m.newTrace('profile_photo_upload');
    await t.start();
    t.putMetric('bytes', 100);
    t.incrementMetric('bytes', 1);
    t.putAttribute('type', 'image');
    await t.stop();
    await m.setEnabled(true);
  });
}
