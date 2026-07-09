import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guards the offline-font guarantee: the Inter + Cairo font files must be
/// present in the asset bundle (declared in pubspec.yaml `fonts:`), so the app
/// never depends on the network to render text. A missing/renamed file would
/// silently regress offline rendering — this catches it in CI.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundled Inter font is present in the asset bundle', () async {
    final data = await rootBundle.load('assets/fonts/Inter.ttf');
    expect(data.lengthInBytes, greaterThan(10000));
  });

  test('bundled Cairo font is present in the asset bundle', () async {
    final data = await rootBundle.load('assets/fonts/Cairo.ttf');
    expect(data.lengthInBytes, greaterThan(10000));
  });
}
