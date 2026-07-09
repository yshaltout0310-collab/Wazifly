import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How the binary was compiled.
enum BuildType { debug, profile, release }

/// Release build metadata — app version, build number, and build type.
///
/// A **foundation** (no UI this milestone) that a future About screen and bug
/// reports can reuse. Kept a plain value type behind [buildInfoProvider], so the
/// source can be swapped (e.g. to a `package_info_plus`-backed impl) with no
/// consumer change — the same seam pattern as every other core service.
///
/// Version/build-number are read from `--dart-define`s (dependency-free, no
/// native plugin — respecting the KGP/Gradle caution) with defaults that mirror
/// `pubspec.yaml`. Release builds pass them (see docs/RELEASE.md); everything
/// still works with the defaults if they're omitted.
@immutable
class BuildInfo {
  const BuildInfo({
    required this.appName,
    required this.version,
    required this.buildNumber,
    required this.buildType,
  });

  final String appName;

  /// Marketing version, e.g. `1.0.0`.
  final String version;

  /// Build/version code, e.g. `1`.
  final String buildNumber;

  final BuildType buildType;

  /// `1.0.0+1` — the full pubspec-style version string.
  String get fullVersion => '$version+$buildNumber';

  /// `Career Bridge 1.0.0 (1) · release` — a human-facing label for a future
  /// About screen / bug report.
  String get displayLabel =>
      '$appName $version ($buildNumber) · ${buildType.name}';

  /// Resolves from compile-time environment + build mode. `APP_VERSION` /
  /// `BUILD_NUMBER` are injected via `--dart-define` in release builds.
  factory BuildInfo.resolve() {
    const version = String.fromEnvironment('APP_VERSION', defaultValue: '1.0.0');
    const buildNumber =
        String.fromEnvironment('BUILD_NUMBER', defaultValue: '1');
    const type = kReleaseMode
        ? BuildType.release
        : (kProfileMode ? BuildType.profile : BuildType.debug);
    return const BuildInfo(
      appName: 'Career Bridge',
      version: version,
      buildNumber: buildNumber,
      buildType: type,
    );
  }
}

/// The app-wide build metadata (rebind for a plugin-backed impl later).
final buildInfoProvider = Provider<BuildInfo>((ref) => BuildInfo.resolve());
