import 'package:careerbridge/shared/widgets/app_network_image.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AppImage.provider wraps NetworkImage in a downsizing ResizeImage',
      (tester) async {
    late ImageProvider<Object> provider;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(devicePixelRatio: 3.0),
        child: Builder(builder: (context) {
          provider = AppImage.provider(
            'https://example.com/photo.jpg',
            context: context,
            logicalSize: 100,
          );
          return const SizedBox();
        }),
      ),
    );

    expect(provider, isA<ResizeImage>());
    final resize = provider as ResizeImage;
    // 100 logical px × 3.0 device pixel ratio → 300 physical px cache width.
    expect(resize.width, 300);
    expect(resize.allowUpscaling, isFalse);
    expect(resize.imageProvider, isA<NetworkImage>());
    expect((resize.imageProvider as NetworkImage).url,
        'https://example.com/photo.jpg');
  });
}
