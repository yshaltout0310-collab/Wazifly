import '../app_check/app_check_service.dart';
import '../service_diagnostics.dart';
import 'ai_exception.dart';

/// Startup stays non-blocking, but protected AI operations must be attested.
/// This guard never substitutes a debug/placeholder token or sends an
/// unattested request when activation or token acquisition fails.
class AiRequestGuard {
  const AiRequestGuard(this._appCheck);

  final AppCheckService _appCheck;

  Future<void> ensureAttested() async {
    try {
      if (!await _appCheck.activate().timeout(const Duration(seconds: 30))) {
        throw const AiAttestationException('App Check activation failed.');
      }
      final token =
          await _appCheck.getToken().timeout(const Duration(seconds: 30));
      if (token == null || token.isEmpty) {
        throw const AiAttestationException(
            'App Check did not provide an attestation token.');
      }
    } catch (error) {
      if (error is AiAttestationException) rethrow;
      throw AiAttestationException(redactServiceDiagnostic(error));
    }
  }

  Future<T> run<T>(Future<T> Function() action) async {
    await ensureAttested();
    return action();
  }
}
