import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The result of [ImageOptimizer.optimize]: the (possibly downscaled) bytes and
/// the content type they should be stored with.
class OptimizedImage {
  const OptimizedImage(this.bytes, this.contentType);

  final Uint8List bytes;
  final String contentType;
}

/// Downscales an image before upload so a multi-megapixel camera photo isn't
/// stored / streamed at full resolution (bandwidth + storage + later decode
/// cost). A **write-path** companion to the display-side [AppImage] seam.
///
/// Dependency-free — uses `dart:ui` for both decode and (PNG) re-encode rather
/// than a native compressor (`flutter_image_compress`) or a new package, to
/// avoid the KGP/Gradle risk (HANDOFF §10). Best-effort: any failure returns the
/// original bytes unchanged, and the re-encoded bytes are only used when they're
/// actually smaller — so optimization can never make an upload worse or fail it.
abstract interface class ImageOptimizer {
  /// Returns [bytes] downscaled so its longest edge is ≤ [maxDimension]px, or the
  /// original bytes when already small enough / on any error.
  /// [fallbackContentType] is the type to report when bytes are unchanged.
  Future<OptimizedImage> optimize(
    Uint8List bytes, {
    int maxDimension = 512,
    String fallbackContentType = 'image/jpeg',
  });
}

/// `dart:ui`-based [ImageOptimizer] — the production implementation.
class UiImageOptimizer implements ImageOptimizer {
  const UiImageOptimizer();

  @override
  Future<OptimizedImage> optimize(
    Uint8List bytes, {
    int maxDimension = 512,
    String fallbackContentType = 'image/jpeg',
  }) async {
    try {
      // Read the source dimensions.
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final src = frame.image;
      final longest = src.width > src.height ? src.width : src.height;
      if (longest <= maxDimension) {
        src.dispose();
        codec.dispose();
        return OptimizedImage(bytes, fallbackContentType); // already small.
      }
      src.dispose();
      codec.dispose();

      // Re-decode at the target size (aspect ratio preserved by the codec).
      final target = await ui.instantiateImageCodec(
        bytes,
        targetWidth: src.width >= src.height ? maxDimension : null,
        targetHeight: src.height > src.width ? maxDimension : null,
      );
      final scaledFrame = await target.getNextFrame();
      final scaled = scaledFrame.image;
      final png = await scaled.toByteData(format: ui.ImageByteFormat.png);
      scaled.dispose();
      target.dispose();
      if (png == null) return OptimizedImage(bytes, fallbackContentType);

      final out = png.buffer.asUint8List();
      // Only adopt the re-encode when it's genuinely smaller (PNG can bloat
      // photographic content), so we never increase the stored size.
      return out.lengthInBytes < bytes.lengthInBytes
          ? OptimizedImage(out, 'image/png')
          : OptimizedImage(bytes, fallbackContentType);
    } catch (e) {
      debugPrint('[ImageOptimizer] optimize failed, using original: $e');
      return OptimizedImage(bytes, fallbackContentType);
    }
  }
}

/// Inert [ImageOptimizer] for tests / callers that shouldn't touch the codec —
/// returns the input unchanged.
class NoopImageOptimizer implements ImageOptimizer {
  const NoopImageOptimizer();

  @override
  Future<OptimizedImage> optimize(
    Uint8List bytes, {
    int maxDimension = 512,
    String fallbackContentType = 'image/jpeg',
  }) async =>
      OptimizedImage(bytes, fallbackContentType);
}

/// The app-wide image optimizer (swap the binding for tests / alternate encoders).
final imageOptimizerProvider =
    Provider<ImageOptimizer>((ref) => const UiImageOptimizer());
