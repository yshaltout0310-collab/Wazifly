import 'package:careerbridge/core/services/build_info/build_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('BuildInfo.resolve returns app metadata with pubspec defaults', () {
    final b = BuildInfo.resolve();
    expect(b.appName, 'Wazifly');
    // Defaults mirror pubspec (release builds override via --dart-define).
    expect(b.version, '1.0.0');
    expect(b.buildNumber, '1');
    expect(b.fullVersion, '1.0.0+1');
    // The test host runs in debug/JIT.
    expect(b.buildType, BuildType.debug);
  });

  test('displayLabel is human-readable and carries the build type', () {
    const b = BuildInfo(
      appName: 'Wazifly',
      version: '2.3.0',
      buildNumber: '42',
      buildType: BuildType.release,
    );
    expect(b.fullVersion, '2.3.0+42');
    expect(b.displayLabel, 'Wazifly 2.3.0 (42) · release');
  });
}
