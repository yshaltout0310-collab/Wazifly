import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Diagnostics must never contain credentials, attestation tokens, or CV text.
String redactServiceDiagnostic(Object value) => value
    .toString()
    .replaceAll(RegExp(r'AIza[0-9A-Za-z_-]{25,}'), '[api-key-redacted]')
    .replaceAll(RegExp(r'\b6[0-9A-Za-z_-]{39}\b'), '[site-key-redacted]')
    .replaceAll(
      RegExp(r'eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+'),
      '[token-redacted]',
    )
    .replaceAll(
      RegExp(r'([?&](?:key|token|api_key|access_token)=)[^&\s]+',
          caseSensitive: false),
      '[credential-query-redacted]',
    );

/// Logs only failure metadata, never request headers, prompts, PDFs or results.
///
/// Firebase AI's public exception API does not expose every HTTP status. Say
/// that explicitly instead of inventing one from a broad "network" category.
void logServiceFailure({
  required String service,
  required String operation,
  required Object error,
  required StackTrace stack,
}) {
  final firebase = error is FirebaseException ? error : null;
  final message = redactServiceDiagnostic(error);
  final status =
      RegExp(r'(?:HTTP\s+|Server Error \[)([45]\d\d)', caseSensitive: false)
          .firstMatch(message)
          ?.group(1);
  debugPrint('[$service] operation=$operation '
      'exception=${error.runtimeType} '
      'firebasePlugin=${firebase?.plugin ?? 'not_exposed'} '
      'firebaseCode=${firebase?.code ?? 'not_exposed'} '
      'httpStatus=${status ?? 'not_exposed_by_sdk'} '
      'message=${message.length > 1500 ? message.substring(0, 1500) : message}');
  final frames = redactServiceDiagnostic(stack).split('\n').take(10).join('\n');
  if (frames.isNotEmpty) debugPrint('[$service] stack=$frames');
}
