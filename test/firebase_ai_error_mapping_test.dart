import 'package:careerbridge/core/services/ai/ai_exception.dart';
import 'package:careerbridge/core/services/ai/firebase_ai_service.dart';
import 'package:careerbridge/core/services/service_diagnostics.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

AiException _map(Object error) => mapFirebaseAiError(
      error,
      StackTrace.empty,
      operation: 'test.generateJson',
      model: 'gemini-2.5-flash',
    );

void main() {
  setUp(() {
    final prior = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {};
    addTearDown(() => debugPrint = prior);
  });

  test('invalid App Check token is an attestation failure, not a network error',
      () {
    final result =
        _map(ServerException('Firebase App Check token is invalid.'));
    expect(result, isA<AiAttestationException>());
    expect(result.code, AiErrorCode.notConfigured);
  });

  test('App Check plugin code is retained in redacted diagnostics', () {
    final result =
        _map(FirebaseException(plugin: 'app-check', code: 'recaptcha-error'));
    expect(result, isA<AiAttestationException>());
    expect(result.rawMessage, contains('recaptcha-error'));
  });

  test('an arbitrary server validation error is not classified as network', () {
    expect(_map(ServerException('Invalid argument to generate content')).code,
        AiErrorCode.unknown);
  });

  test('quota and actual network/server availability failures remain distinct',
      () {
    expect(_map(ServerException('RESOURCE_EXHAUSTED: quota exceeded')).code,
        AiErrorCode.quota);
    expect(_map(ServerException('Server Error [503]: unavailable')).code,
        AiErrorCode.network);
    expect(_map(ServerException('Network timeout')).code, AiErrorCode.network);
  });

  test('diagnostics redact site keys, API keys and attestation tokens', () {
    final siteKey = '6${List.filled(39, 'z').join()}';
    final apiKey = 'AIza${List.filled(35, 'x').join()}';
    const token = 'eyJhbGciOiJub25lIn0.eyJzdWIiOiJ0ZXN0In0.signature';
    final result = redactServiceDiagnostic(
        'site=$siteKey api=$apiKey token=$token https://example.test/?key=$apiKey');
    expect(result, isNot(contains(siteKey)));
    expect(result, isNot(contains(apiKey)));
    expect(result, isNot(contains(token)));
    expect(result, contains('[site-key-redacted]'));
    expect(result, contains('[token-redacted]'));
  });
}
