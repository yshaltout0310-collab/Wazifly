import 'dart:typed_data';

import 'cv_data.dart';
import 'cv_template.dart';

/// Localized section labels handed to the PDF templates, so a template never
/// imports Flutter localization — the presentation layer resolves the strings
/// and passes this plain value object down.
class CvLabels {
  const CvLabels({
    required this.summary,
    required this.experience,
    required this.education,
    required this.skills,
    required this.projects,
    required this.links,
    required this.present,
  });

  final String summary;
  final String experience;
  final String education;
  final String skills;
  final String projects;
  final String links;
  final String present;

  /// Neutral English fallback (used in tests / before l10n is available).
  static const fallback = CvLabels(
    summary: 'Summary',
    experience: 'Experience',
    education: 'Education',
    skills: 'Skills',
    projects: 'Projects',
    links: 'Links',
    present: 'Present',
  );
}

/// Turns a [CvData] into PDF bytes for a chosen template + language.
///
/// This is the swap seam: the app depends only on this interface, so the PDF
/// backend (the `pdf`/`printing` implementation today, Syncfusion tomorrow) can
/// change without touching feature code. Throws [CvBuilderException] on failure.
abstract interface class CvPdfGenerator {
  Future<Uint8List> generate(
    CvData data, {
    required CvTemplateId templateId,
    required String languageCode,
    CvLabels? labels,
  });
}
