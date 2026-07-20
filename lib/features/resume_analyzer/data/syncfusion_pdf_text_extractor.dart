import 'dart:typed_data';

import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;

import '../domain/pdf_text_extractor.dart';
import '../domain/resume_analyzer_exception.dart';

/// [PdfTextExtractor] backed by Syncfusion's pure-Dart PDF library, so it works
/// on-device and inside unit tests without a platform channel.
///
/// Uses **layout-aware** extraction (`layoutText: true`). The default
/// `extractText()` walks the raw glyph runs and emits (roughly) one token per
/// line — it splits words and numbers ("2025" → "202"/"5", "The" → "T"/"he")
/// and discards the physical line/section structure. That shredded token soup
/// both hides the resume's real structure from the model and manufactures fake
/// date errors. Layout mode reflows the glyphs into readable lines with correct
/// spacing, which is what a human (and the model) actually reads.
class SyncfusionPdfTextExtractor implements PdfTextExtractor {
  const SyncfusionPdfTextExtractor();

  /// If layout extraction collapses to almost nothing (rare malformed PDFs),
  /// fall back to the raw extractor rather than returning an empty string.
  static const int _layoutMinChars = 20;

  @override
  Future<String> extract(Uint8List bytes) async {
    sf.PdfDocument? document;
    try {
      document = sf.PdfDocument(inputBytes: bytes);
      final extractor = sf.PdfTextExtractor(document);
      final layout = extractor.extractText(layoutText: true);
      final chosen = layout.trim().length >= _layoutMinChars
          ? layout
          : extractor.extractText();
      return _normalize(chosen);
    } catch (e) {
      throw ResumeAnalyzerException(
          ResumeErrorCode.extractionFailed, e.toString());
    } finally {
      document?.dispose();
    }
  }

  /// Light tidy-up: strip trailing whitespace per line and collapse runs of
  /// blank lines to a single blank line, so the text handed to the model is
  /// compact without altering wording or reading order.
  static String _normalize(String raw) {
    final lines = raw.replaceAll('\r\n', '\n').split('\n');
    final out = <String>[];
    var blankRun = 0;
    for (final line in lines) {
      final trimmed = line.replaceFirst(RegExp(r'\s+$'), '');
      if (trimmed.trim().isEmpty) {
        blankRun++;
        if (blankRun <= 1) out.add('');
      } else {
        blankRun = 0;
        out.add(trimmed);
      }
    }
    return out.join('\n').trim();
  }
}
