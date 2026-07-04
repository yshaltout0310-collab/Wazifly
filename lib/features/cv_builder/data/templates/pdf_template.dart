import 'package:pdf/widgets.dart' as pw;

import '../../domain/cv_data.dart';
import '../../domain/cv_pdf_generator.dart';
import '../pdf/cv_fonts.dart';

/// A PDF template builder. Each [CvTemplateId] that is implemented has one of
/// these; the generator maps id → template. Adding a template later is just a
/// new class here + a registry entry — no changes elsewhere.
abstract interface class PdfTemplate {
  pw.Document build(
    CvData data, {
    required CvLabels labels,
    required CvFonts fonts,
    required bool rtl,
  });
}
