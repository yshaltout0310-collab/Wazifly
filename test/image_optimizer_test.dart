import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:careerbridge/core/services/cloud_storage/image_optimizer.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// Encodes a solid-colour [w]×[h] PNG using dart:ui (engine required — run
/// inside `tester.runAsync`).
Future<Uint8List> _png(int w, int h) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
    Paint()..color = const Color(0xFF0E9F6E),
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(w, h);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('NoopImageOptimizer returns the input bytes unchanged', () async {
    final bytes = Uint8List.fromList([1, 2, 3, 4]);
    final result = await const NoopImageOptimizer()
        .optimize(bytes, fallbackContentType: 'image/jpeg');
    expect(result.bytes, same(bytes));
    expect(result.contentType, 'image/jpeg');
  });

  testWidgets('UiImageOptimizer returns original bytes on undecodable input',
      (tester) async {
    await tester.runAsync(() async {
      final garbage = Uint8List.fromList([9, 9, 9, 9, 9]);
      final result = await const UiImageOptimizer()
          .optimize(garbage, fallbackContentType: 'image/jpeg');
      expect(result.bytes, same(garbage));
      expect(result.contentType, 'image/jpeg');
    });
  });

  testWidgets('UiImageOptimizer leaves an image within the cap unchanged',
      (tester) async {
    await tester.runAsync(() async {
      final png = await _png(10, 10);
      final result = await const UiImageOptimizer()
          .optimize(png, maxDimension: 512, fallbackContentType: 'image/png');
      expect(result.bytes, same(png)); // already small → untouched
      expect(result.contentType, 'image/png');
    });
  });

  testWidgets('UiImageOptimizer never enlarges and returns decodable bytes',
      (tester) async {
    await tester.runAsync(() async {
      final png = await _png(1200, 800);
      final result =
          await const UiImageOptimizer().optimize(png, maxDimension: 256);
      // Contract: never larger than the input...
      expect(result.bytes.lengthInBytes, lessThanOrEqualTo(png.lengthInBytes));
      // ...and still a valid, decodable image.
      final codec = await ui.instantiateImageCodec(result.bytes);
      final frame = await codec.getNextFrame();
      expect(frame.image.width, greaterThan(0));
      frame.image.dispose();
      codec.dispose();
    });
  });
}
