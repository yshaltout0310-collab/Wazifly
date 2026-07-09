import 'package:flutter/widgets.dart';

/// Shared image helpers for remote avatars/logos.
///
/// The single seam for network images across the app (profile photos, company
/// logos, applicant avatars). Its job is **decode-downsizing**: a raw
/// `NetworkImage` decodes at the source resolution (a multi-megapixel photo
/// shown in a 96 px avatar wastes memory and jank), so [provider] wraps it in the
/// built-in [ResizeImage], targeting the display box × device pixel ratio.
///
/// Deliberately **dependency-free** — it uses Flutter's built-in [ResizeImage]
/// rather than `cached_network_image` (which pulls `flutter_cache_manager` +
/// `sqflite`, a native/KGP-Gradle risk like the removed `file_picker`, HANDOFF
/// §10). In-memory caching is handled by Flutter's own `ImageCache`, now keyed by
/// the downsized dimensions so cache pressure drops too.
abstract final class AppImage {
  AppImage._();

  /// A decode-downsizing [ImageProvider] for [url], sized to [logicalSize]
  /// (the larger display dimension in logical pixels) × the device pixel ratio.
  /// Aspect ratio is preserved (only the cache width is pinned); never upscales.
  static ImageProvider<Object> provider(
    String url, {
    required BuildContext context,
    required double logicalSize,
  }) {
    final dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 1.0;
    final cacheWidth = (logicalSize * dpr).round().clamp(1, 4096);
    return ResizeImage(
      NetworkImage(url),
      width: cacheWidth,
      allowUpscaling: false,
    );
  }
}
