import 'dart:typed_data';

/// Extracts plain text from a PDF's bytes.
///
/// An interface (not a concrete class) so the resume repository depends on the
/// capability, not on the PDF library — the Syncfusion implementation lives in
/// `data/` and a fake is trivial to supply in tests.
abstract interface class PdfTextExtractor {
  /// Returns the concatenated text of [bytes]. May return an empty/near-empty
  /// string for scanned (image-only) PDFs; callers decide how to treat that.
  Future<String> extract(Uint8List bytes);
}
