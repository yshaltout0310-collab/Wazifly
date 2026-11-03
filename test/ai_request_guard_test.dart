import 'dart:async';

import 'package:careerbridge/core/services/ai/ai_exception.dart';
import 'package:careerbridge/core/services/ai/ai_request_guard.dart';
import 'package:careerbridge/core/services/app_check/app_check_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _AppCheck implements AppCheckService {
  final activation = Completer<bool>();
  final token = Completer<String?>();
  int tokenCalls = 0;

  @override
  Future<bool> activate() => activation.future;

  @override
  Future<String?> getToken({bool forceRefresh = false}) {
    tokenCalls++;
    return token.future;
  }
}

void main() {
  test('protected action waits for both activation and token acquisition',
      () async {
    final service = _AppCheck();
    final guard = AiRequestGuard(service);
    var actionCalls = 0;
    final result = guard.run(() async {
      actionCalls++;
      return 'real transport may now run';
    });

    await Future<void>.delayed(Duration.zero);
    expect(actionCalls, 0);
    expect(service.tokenCalls, 0);
    service.activation.complete(true);
    await Future<void>.delayed(Duration.zero);
    expect(service.tokenCalls, 1);
    expect(actionCalls, 0);
    service.token.complete('test-token-not-logged');
    expect(await result, 'real transport may now run');
    expect(actionCalls, 1);
  });

  test('failed activation prevents the protected request', () async {
    final service = _AppCheck()..activation.complete(false);
    var called = false;
    await expectLater(
      AiRequestGuard(service).run(() async => called = true),
      throwsA(isA<AiAttestationException>()),
    );
    expect(called, isFalse);
    expect(service.tokenCalls, 0);
  });

  for (final token in <String?>[null, '']) {
    test('missing or empty token prevents the protected request ($token)',
        () async {
      final service = _AppCheck()
        ..activation.complete(true)
        ..token.complete(token);
      var called = false;
      await expectLater(
        AiRequestGuard(service).run(() async => called = true),
        throwsA(isA<AiAttestationException>()),
      );
      expect(called, isFalse);
    });
  }
}
