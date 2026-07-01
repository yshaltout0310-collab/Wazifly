import 'dart:typed_data';

import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;

import '../domain/pdf_text_extractor.dart';
import '../domain/resume_analyzer_exception.dart';

/// [PdfTextExtractor] backed by Syncfusion's pure-Dart PDF library, so it works
/// on-device and inside unit tests without a platform channel.
class SyncfusionPdfTextExtractor implements PdfTextExtractor {
  const SyncfusionPdfTextExtractor();

  @override
  Future<String> extract(Uint8List bytes) async {
    sf.PdfDocument? document;
    try {
      document = sf.PdfDocument(inputBytes: bytes);
      return sf.PdfTextExtractor(document).extractText();
    } catch (e) {
      throw ResumeAnalyzerException(
          ResumeErrorCode.extractionFailed, e.toString());
    } finally {
      document?.dispose();
    }
  }
}
