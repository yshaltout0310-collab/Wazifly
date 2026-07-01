import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';

import 'ai_exception.dart';
import 'ai_service.dart';

/// [AiService] backed by **Firebase AI Logic** using the Gemini Developer API
/// backend (`FirebaseAI.googleAI()`).
///
/// No API key is shipped in the client — requests are authenticated through the
/// Firebase app. Swapping to the Vertex AI backend later is a one-line change
/// (`FirebaseAI.vertexAI()`); swapping providers entirely means writing a new
/// [AiService] and rebinding `aiServiceProvider`.
class FirebaseAiService implements AiService {
  FirebaseAiService({this.modelName = defaultModel});

  /// Fast, low-cost, capable default. Overridable per instance.
  static const String defaultModel = 'gemini-2.5-flash';

  final String modelName;

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
    return _guard(() async {
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
    return _guard(() async {
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
    final stream = _model(systemInstruction: systemInstruction)
        .generateContentStream([Content.text(prompt)]);
    try {
      await for (final chunk in stream) {
        final text = chunk.text;
        if (text != null && text.isNotEmpty) yield text;
      }
    } catch (e) {
      throw _map(e);
    }
  }

  /// Runs [action], normalizing any error into an [AiException].
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (e) {
      throw _map(e);
    }
  }

  AiException _map(Object error) {
    if (error is AiException) return error;
    debugPrint('[FirebaseAiService] error (${error.runtimeType}): $error');

    if (error is InvalidApiKey) {
      return AiException(AiErrorCode.notConfigured, error.toString());
    }
    // ServiceApiNotEnabled / QuotaExceeded are subtypes of FirebaseAIException
    // but not exported by the SDK, so refine by message.
    if (error is FirebaseAIException || error is ServerException) {
      final msg = error.toString().toLowerCase();
      if (msg.contains('not been enabled') ||
          msg.contains('not enabled') ||
          msg.contains('has not been used') ||
          msg.contains('service_disabled') ||
          msg.contains('firebasevertexai') ||
          msg.contains('firebase ai') ||
          msg.contains('permission') ||
          msg.contains('403') ||
          msg.contains('api key')) {
        return AiException(AiErrorCode.notConfigured, error.toString());
      }
      if (msg.contains('quota') ||
          msg.contains('rate') ||
          msg.contains('resource_exhausted') ||
          msg.contains('429')) {
        return AiException(AiErrorCode.quota, error.toString());
      }
      if (error is ServerException ||
          msg.contains('unavailable') ||
          msg.contains('network') ||
          msg.contains('timeout') ||
          msg.contains('socket')) {
        return AiException(AiErrorCode.network, error.toString());
      }
      return AiException(AiErrorCode.unknown, error.toString());
    }
    return AiException(AiErrorCode.unknown, error.toString());
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
