/// Stable, provider-agnostic AI error codes the UI can localize.
enum AiErrorCode {
  /// The provider is not enabled/configured (e.g. Firebase AI Logic off).
  notConfigured,

  /// Network failure reaching the model.
  network,

  /// Rate limited or out of quota.
  quota,

  /// The model returned an empty or unusable response.
  emptyResponse,

  /// The model's response could not be parsed into the expected shape.
  invalidResponse,

  /// Content blocked by safety filters.
  blocked,

  unknown,
}

/// Error thrown by the AI layer, carrying a stable [code] so the presentation
/// layer can show a localized message independent of the underlying provider.
class AiException implements Exception {
  const AiException(this.code, [this.rawMessage]);

  final AiErrorCode code;
  final String? rawMessage;

  @override
  String toString() => 'AiException(${code.name}): $rawMessage';
}
