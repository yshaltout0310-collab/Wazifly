import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_core/firebase_core.dart';

import '../app_check/app_check_service.dart';
import '../service_diagnostics.dart';
import 'ai_exception.dart';
import 'ai_message.dart';
import 'ai_request_guard.dart';
import 'ai_service.dart';

/// [AiService] backed by **Firebase AI Logic** using the Gemini Developer API
/// backend (`FirebaseAI.googleAI()`).
///
/// No API key is shipped in the client — requests are authenticated through the
/// Firebase app. Swapping to the Vertex AI backend later is a one-line change
/// (`FirebaseAI.vertexAI()`); swapping providers entirely means writing a new
/// [AiService] and rebinding `aiServiceProvider`.
class FirebaseAiService implements AiService {
  FirebaseAiService({
    required AppCheckService appCheck,
    this.modelName = defaultModel,
  }) : _attestation = AiRequestGuard(appCheck);

  /// Fast, low-cost, capable default. Overridable per instance.
  static const String defaultModel = 'gemini-2.5-flash';

  final String modelName;
  final AiRequestGuard _attestation;

  GenerativeModel _model({bool jsonMode = false, String? systemInstruction}) {
    return FirebaseAI.googleAI().generativeModel(
      model: modelName,
      systemInstruction:
          systemInstruction == null ? null : Content.system(systemInstruction),
      generationConfig: GenerationConfig(
        responseMimeType: jsonMode ? 'application/json' : null,
      ),
    );
  }

  @override
  Future<String> generateText(String prompt, {String? systemInstruction}) {
    return _guard('generateText', () async {
      final response = await _model(systemInstruction: systemInstruction)
          .generateContent([Content.text(prompt)]);
      final text = response.text?.trim();
      if (text == null || text.isEmpty) {
        throw const AiException(AiErrorCode.emptyResponse);
      }
      return text;
    });
  }

  @override
  Future<Map<String, dynamic>> generateJson(
    String prompt, {
    String? systemInstruction,
  }) {
    return _guard('generateJson', () async {
      final response =
          await _model(jsonMode: true, systemInstruction: systemInstruction)
              .generateContent([Content.text(prompt)]);
      final text = response.text?.trim();
      if (text == null || text.isEmpty) {
        throw const AiException(AiErrorCode.emptyResponse);
      }
      try {
        final decoded = jsonDecode(_stripCodeFence(text));
        if (decoded is Map<String, dynamic>) return decoded;
        throw const AiException(AiErrorCode.invalidResponse);
      } on FormatException catch (e) {
        throw AiException(AiErrorCode.invalidResponse, e.message);
      }
    });
  }

  @override
  Stream<String> streamText(String prompt, {String? systemInstruction}) async* {
    try {
      await _attestation.ensureAttested();
      final stream = _model(systemInstruction: systemInstruction)
          .generateContentStream([Content.text(prompt)]);
      await for (final chunk in stream) {
        final text = chunk.text;
        if (text != null && text.isNotEmpty) yield text;
      }
    } catch (error, stack) {
      throw mapFirebaseAiError(error, stack,
          operation: 'streamText', model: modelName);
    }
  }

  @override
  Stream<String> streamChat(
    List<AiMessage> history, {
    String? systemInstruction,
  }) async* {
    // Map the provider-neutral turns to Gemini Content (user vs model roles).
    final contents = [
      for (final m in history)
        m.role == AiRole.model
            ? Content.model([TextPart(m.text)])
            : Content.text(m.text),
    ];
    try {
      await _attestation.ensureAttested();
      final stream = _model(systemInstruction: systemInstruction)
          .generateContentStream(contents);
      await for (final chunk in stream) {
        final text = chunk.text;
        if (text != null && text.isNotEmpty) yield text;
      }
    } catch (error, stack) {
      throw mapFirebaseAiError(error, stack,
          operation: 'streamChat', model: modelName);
    }
  }

  /// Runs [action], normalizing any error into an [AiException].
  Future<T> _guard<T>(String operation, Future<T> Function() action) async {
    try {
      return await _attestation.run(action);
    } catch (error, stack) {
      throw mapFirebaseAiError(error, stack,
          operation: operation, model: modelName);
    }
  }

  /// Some models wrap JSON in ```json fences despite `application/json`; strip
  /// them defensively before decoding.
  String _stripCodeFence(String text) {
    var t = text.trim();
    if (t.startsWith('```')) {
      t = t.replaceFirst(RegExp(r'^```[a-zA-Z]*\n?'), '');
      if (t.endsWith('```')) t = t.substring(0, t.length - 3);
    }
    return t.trim();
  }
}

/// Shared by text analysis and multimodal OCR. A provider ServerException can
/// mean invalid attestation or input, not just a connection failure.
AiException mapFirebaseAiError(
  Object error,
  StackTrace stack, {
  required String operation,
  required String model,
}) {
  logServiceFailure(
      service: 'FirebaseAiService',
      operation: '$operation model=$model',
      error: error,
      stack: stack);
  if (error is AiException) return error;
  final message = redactServiceDiagnostic(error);
  final lower = message.toLowerCase();
  if ((error is FirebaseException && error.plugin == 'app-check') ||
      lower.contains('app check') ||
      lower.contains('appcheck') ||
      lower.contains('recaptcha')) {
    return AiAttestationException(message);
  }
  if (error is InvalidApiKey ||
      lower.contains('not been enabled') ||
      lower.contains('not enabled') ||
      lower.contains('has not been used') ||
      lower.contains('service_disabled') ||
      lower.contains('permission') ||
      lower.contains('403') ||
      lower.contains('api key')) {
    return AiException(AiErrorCode.notConfigured, message);
  }
  if (lower.contains('quota') ||
      RegExp(r'\brate[ -]?limit').hasMatch(lower) ||
      lower.contains('resource_exhausted') ||
      lower.contains('429')) {
    return AiException(AiErrorCode.quota, message);
  }
  if (lower.contains('unavailable') ||
      lower.contains('network') ||
      lower.contains('timeout') ||
      lower.contains('socket') ||
      RegExp(r'server error \[5\d\d\]').hasMatch(lower)) {
    return AiException(AiErrorCode.network, message);
  }
  return AiException(AiErrorCode.unknown, message);
}
