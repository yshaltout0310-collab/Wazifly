import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/cv_builder_exception.dart';
import '../../domain/cv_data.dart';
import '../../domain/cv_pdf_generator.dart';
import '../../domain/cv_template.dart';
import '../templates/ats_template.dart';
import '../templates/harvard_template.dart';
import '../templates/minimal_template.dart';
import '../templates/modern_template.dart';
import '../templates/pdf_template.dart';
import 'cv_fonts.dart';

/// The template registry: every [CvTemplateId] maps to its [PdfTemplate].
/// Adding a template = a new [PdfTemplate] class + an entry here.
const Map<CvTemplateId, PdfTemplate> kCvTemplates = {
  CvTemplateId.ats: AtsTemplate(),
  CvTemplateId.modern: ModernTemplate(),
  CvTemplateId.minimal: MinimalTemplate(),
  CvTemplateId.harvard: HarvardTemplate(),
};

/// [CvPdfGenerator] backed by the `pdf` package (pure-Dart document build) with
/// `printing` supplying preview/share upstream. Maps each [CvTemplateId] to a
/// [PdfTemplate] via [kCvTemplates]; an unregistered id throws
/// [CvErrorCode.templateUnavailable] (a guard — every id ships a template).
class PdfCvGenerator implements CvPdfGenerator {
  PdfCvGenerator({CvFonts? fonts, Map<CvTemplateId, PdfTemplate>? templates})
      : _injectedFonts = fonts,
        _templates = templates ?? kCvTemplates;

  /// When null, fonts are loaded lazily (Google Fonts, cached). Tests inject
  /// [CvFonts.builtIn] to stay offline.
  final CvFonts? _injectedFonts;
  final Map<CvTemplateId, PdfTemplate> _templates;

  CvFonts? _cached;

  Future<CvFonts> _fonts() async =>
      _injectedFonts ?? (_cached ??= await CvFonts.load());

  @override
  Future<Uint8List> generate(
    CvData data, {
    required CvTemplateId templateId,
    required String languageCode,
    CvLabels? labels,
  }) async {
    final template = _templates[templateId];
    if (template == null) {
      throw const CvBuilderException(CvErrorCode.templateUnavailable);
    }
    try {
      final fonts = await _fonts();
      final doc = template.build(
        data,
        labels: labels ?? CvLabels.fallback,
        fonts: fonts,
        rtl: languageCode == 'ar',
      );
      return doc.save();
    } catch (e) {
      throw CvBuilderException(CvErrorCode.generationFailed, e.toString());
    }
  }
}

/// The app-wide CV PDF generator (swap this binding for a different backend).
final cvPdfGeneratorProvider =
    Provider<CvPdfGenerator>((ref) => PdfCvGenerator());
