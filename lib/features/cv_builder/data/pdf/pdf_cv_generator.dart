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
import '../templates/pdf_text.dart';
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
      final resolvedLabels = labels ?? CvLabels.fallback;
      // The base font must follow the CONTENT, not the app language: an Arabic
      // CV written while the app is in English still needs the Arabic face, or
      // pdf's shaping/bidi pass runs against a Latin font and garbles it.
      final fonts = (await _fonts())
          .withPreferArabic(_containsArabic(data, resolvedLabels));
      final doc = template.build(
        data,
        labels: resolvedLabels,
        fonts: fonts,
        rtl: languageCode == 'ar',
      );
      return doc.save();
    } catch (e) {
      throw CvBuilderException(CvErrorCode.generationFailed, e.toString());
    }
  }

  /// True if anything that will be printed — the user's content or the localized
  /// section labels — contains Arabic.
  static bool _containsArabic(CvData d, CvLabels l) {
    final parts = <String>[
      d.fullName, d.headline, d.email, d.phone, d.location,
      d.portfolioUrl, d.githubUrl, d.linkedinUrl, d.summary,
      ...d.skills,
      for (final e in d.experiences) ...[
        e.role, e.company, e.location, e.startDate, e.endDate, ...e.bullets,
      ],
      for (final e in d.education) ...[
        e.degree, e.institution, e.location, e.startYear, e.endYear, e.details,
      ],
      for (final p in d.projects) ...[p.name, p.description, p.link],
      l.summary, l.experience, l.education, l.skills, l.projects,
      l.contact, l.links, l.present,
    ];
    return parts.any(PdfText.hasArabic);
  }
}

/// The app-wide CV PDF generator (swap this binding for a different backend).
final cvPdfGeneratorProvider =
    Provider<CvPdfGenerator>((ref) => PdfCvGenerator());
