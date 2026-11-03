import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the App Check attestation invariant for Firebase AI Logic.
///
/// `FirebaseAI.googleAI()` / `.vertexAI()` take `appCheck` as an *optional*
/// parameter and send no `X-Firebase-AppCheck` header when it is omitted, so an
/// unattested call site compiles and analyzes cleanly yet makes every AI request
/// fail against the (now mandatory) App Check enforcement with
/// `Firebase App Check token is invalid.`
///
/// Worse, `FirebaseAI` memoizes one instance per `'<appName>::googleai'` key, so
/// the *first* call wins: a single unattested call site anywhere poisons the
/// cache for the entire process, breaking the attested ones too. This test
/// therefore requires every call site to go through `attestedGoogleAi()`.
void main() {
  test('no lib/ file calls FirebaseAI.googleAI/vertexAI directly', () {
    final offenders = <String>[];

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      // The single sanctioned entry point, which supplies `appCheck`.
      if (entity.uri.pathSegments.last == 'firebase_ai_client.dart') continue;

      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        // Skip doc comments: they discuss the API without calling it.
        if (line.trimLeft().startsWith('//')) continue;
        if (line.contains('FirebaseAI.googleAI(') ||
            line.contains('FirebaseAI.vertexAI(')) {
          offenders.add('${entity.path}:${i + 1}');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'These call sites bypass attestedGoogleAi() and would send '
          'unattested Firebase AI Logic requests (and poison the shared '
          'FirebaseAI instance cache for the whole app): $offenders',
    );
  });

  test('the sanctioned entry point passes appCheck', () {
    final source =
        File('lib/core/services/ai/firebase_ai_client.dart').readAsStringSync();

    expect(
      source.contains('appCheck: FirebaseAppCheck.instance'),
      isTrue,
      reason: 'attestedGoogleAi() must pass the FirebaseAppCheck instance; '
          'without it firebase_ai sends no X-Firebase-AppCheck header.',
    );
  });
}
