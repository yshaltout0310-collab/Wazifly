import 'package:careerbridge/core/services/ai/ai_exception.dart';
import 'package:careerbridge/core/services/ai/firebase_ai_service.dart';
import 'package:careerbridge/core/services/app_check/app_check_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _DeniedAppCheck implements AppCheckService {
  @override
  Future<bool> activate() async => false;

  @override
  Future<String?> getToken({bool forceRefresh = false}) async => null;
}

void main() {
  test(
      'all protected AI entry points reject unattested requests before Firebase',
      () async {
    // Firebase is deliberately not initialized. If any entry point constructs
    // or invokes the model before attestation, this fails with a different
    // error rather than our explicit security-verification exception.
    final service = FirebaseAiService(appCheck: _DeniedAppCheck());
    final attestationFailure = throwsA(isA<AiAttestationException>());
    await expectLater(service.generateText('test'), attestationFailure);
    await expectLater(service.generateJson('test'), attestationFailure);
    await expectLater(service.streamText('test').toList(), attestationFailure);
    await expectLater(service.streamChat([]).toList(), attestationFailure);
  });
}
