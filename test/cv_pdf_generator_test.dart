import 'package:careerbridge/features/cv_builder/data/pdf/cv_fonts.dart';
import 'package:careerbridge/features/cv_builder/data/pdf/pdf_cv_generator.dart';
import 'package:careerbridge/features/cv_builder/domain/cv_builder_exception.dart';
import 'package:careerbridge/features/cv_builder/domain/cv_data.dart';
import 'package:careerbridge/features/cv_builder/domain/cv_template.dart';
import 'package:flutter_test/flutter_test.dart';

// Built-in (offline) fonts so the generator never hits the network in tests.
final _generator = PdfCvGenerator(fonts: CvFonts.builtIn());

const _cv = CvData(
  fullName: 'Sarah Ahmed',
  headline: 'Senior Flutter Engineer',
  email: 'sarah@cb.app',
  phone: '+974 5000 0000',
  location: 'Doha, Qatar',
  githubUrl: 'github.com/sarah',
  summary: 'Mobile engineer with 6 years building production Flutter apps.',
  experiences: [
    CvExperience(
      role: 'Senior Flutter Engineer',
      company: 'Northwind Apps',
      startDate: '2021',
      current: true,
      bullets: ['Led the migration to Riverpod', 'Cut cold-start by 35%'],
    ),
  ],
  education: [
    CvEducation(
      degree: 'BSc Computer Science',
      institution: 'Qatar University',
      startYear: '2014',
      endYear: '2018',
    ),
  ],
  skills: ['Flutter', 'Dart', 'Firebase'],
);

void main() {
  test('generates a non-empty PDF for the ATS template (EN)', () async {
    final bytes = await _generator.generate(_cv,
        templateId: CvTemplateId.ats, languageCode: 'en');
    expect(bytes, isNotEmpty);
    // PDF files start with the "%PDF" magic bytes.
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });

  test('generates a PDF for the ATS template with RTL layout (AR path)',
      () async {
    // ASCII content keeps built-in fonts happy while still exercising the
    // rtl/textDirection code path (real Arabic glyphs are verified live).
    final bytes = await _generator.generate(_cv,
        templateId: CvTemplateId.ats, languageCode: 'ar');
    expect(bytes, isNotEmpty);
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });

  test('empty CV still generates (no throw)', () async {
    final bytes = await _generator.generate(const CvData(),
        templateId: CvTemplateId.ats, languageCode: 'en');
    expect(bytes, isNotEmpty);
  });

  test('a coming-soon template throws templateUnavailable', () async {
    expect(
      () => _generator.generate(_cv,
          templateId: CvTemplateId.modern, languageCode: 'en'),
      throwsA(isA<CvBuilderException>().having(
          (e) => e.code, 'code', CvErrorCode.templateUnavailable)),
    );
  });
}
