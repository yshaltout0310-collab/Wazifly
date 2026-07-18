/// App-wide static configuration values.
abstract final class AppConstants {
  AppConstants._();

  static const String appName = 'Wazifly';
  static const String appVersion = '1.0.0';

  /// Maximum content width on large screens (tablets/desktop) so layouts stay
  /// readable instead of stretching edge-to-edge.
  static const double maxContentWidth = 560;

  /// Breakpoint above which a device is treated as a tablet.
  static const double tabletBreakpoint = 600;
}
