import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';
import 'package:printing/printing.dart';

import '../../../core/services/ai/ai_exception.dart';
import '../domain/resume_ocr.dart';

/// [ResumeOcr] that reads a scanned/image-only PDF by rendering its pages to
/// images and transcribing them with Gemini's multimodal vision (via Firebase
/// AI Logic — the same backend the analyzer already uses, so no extra native
/// OCR dependency or model download is required).
///
/// Pipeline: `printing` rasterizes each page to a PNG on-device (PDFium), then a
/// single multimodal request asks the model to transcribe every page verbatim.
/// Robust for CVs produced by Adobe Scan, CamScanner, Microsoft Lens, or a
/// phone photo saved as PDF.
class GeminiPdfOcr implements ResumeOcr {
  GeminiPdfOcr({this.modelName = _defaultModel});

  /// Same fast, capable default the analysis call uses.
  static const String _defaultModel = 'gemini-2.5-flash';

  /// Cap pages so a huge scan can't blow up latency/cost. CVs are short.
  static const int _maxPages = 8;

  /// Render resolution — high enough for reliable OCR, low enough to stay light.
  static const double _dpi = 200;

  final String modelName;

  static const String _ocrPrompt =
      'These images are the pages of a scanned resume/CV, in order. Transcribe '
      'ALL of the text exactly as written, preserving the reading order and line '
      'breaks. Include every section, bullet, date, email, and number. Do not '
      'summarize, translate, correct, or add commentary — output only the raw '
      'transcribed text.';

  @override
  Future<String> extractText(Uint8List bytes) async {
    final images = await _rasterizePages(bytes);
    if (images.isEmpty) return '';

    try {
      final model = FirebaseAI.googleAI().generativeModel(model: modelName);
      final parts = <Part>[
        TextPart(_ocrPrompt),
        for (final png in images) InlineDataPart('image/png', png),
      ];
      final response = await model.generateContent([Content.multi(parts)]);
      return response.text?.trim() ?? '';
    } catch (e) {
      throw _mapError(e);
    }
  }

  /// Renders up to [_maxPages] pages to PNG bytes. Rasterization failures (a
  /// truly unrenderable PDF) yield an empty list so the caller shows the normal
  /// "couldn't read" error rather than a confusing OCR error.
  Future<List<Uint8List>> _rasterizePages(Uint8List bytes) async {
    try {
      final pngs = <Uint8List>[];
      await for (final page in Printing.raster(bytes, dpi: _dpi)) {
        pngs.add(await page.toPng());
        if (pngs.length >= _maxPages) break;
      }
      return pngs;
    } catch (e) {
      debugPrint('[GeminiPdfOcr] rasterization failed: $e');
      return const [];
    }
  }

  /// Maps a Firebase AI error to the shared [AiException] taxonomy so the UI can
  /// show a precise message (network, quota, not-configured) instead of a
  /// generic failure. Mirrors the classification in `FirebaseAiService`.
  AiException _mapError(Object error) {
    if (error is AiException) return error;
    final msg = error.toString().toLowerCase();
    if (error is InvalidApiKey ||
        msg.contains('not been enabled') ||
        msg.contains('not enabled') ||
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
}
