import 'dart:typed_data';

/// Optical-character-recognition fallback for the résumé analyzer.
///
/// A scanned CV (Adobe Scan, CamScanner, Microsoft Lens, a photographed page)
/// has no selectable text layer, so [PdfTextExtractor] returns (near-)nothing.
/// When that happens the repository falls back to a [ResumeOcr], which renders
/// the pages to images and reads the text off them.
///
/// An interface (not a concrete class) so the repository depends on the
/// capability, not on any particular OCR/vision backend — the concrete
/// implementation lives in `data/` and a fake is trivial to supply in tests.
abstract interface class ResumeOcr {
  /// Returns the text recognized from the (image-only) PDF [bytes], or an
  /// empty/near-empty string when nothing could be read. Never returns null.
  Future<String> extractText(Uint8List bytes);
}
