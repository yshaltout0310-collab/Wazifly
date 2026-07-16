import 'package:careerbridge/features/cv_builder/data/pdf/cv_fonts.dart';
import 'package:careerbridge/features/cv_builder/data/pdf/pdf_cv_generator.dart';
import 'package:careerbridge/features/cv_builder/domain/cv_builder_exception.dart';
import 'package:careerbridge/features/cv_builder/domain/cv_data.dart';
import 'package:careerbridge/features/cv_builder/domain/cv_pdf_generator.dart';
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

/// A CV long enough to spill past one page — guards the templates that flow
/// content in columns (Modern uses `Partitions`, which must span pages rather
/// than overflow the page box).
CvData _longCv() => CvData(
      fullName: 'Sarah Ahmed',
      headline: 'Senior Flutter Engineer',
      email: 'sarah@cb.app',
      phone: '+974 5000 0000',
      location: 'Doha, Qatar',
      portfolioUrl: 'https://sarah.dev/portfolio/work/case-studies/mobile',
      githubUrl: 'github.com/sarah',
      linkedinUrl: 'linkedin.com/in/sarah-ahmed',
      summary: 'Mobile engineer with 6 years building production apps. ' * 6,
      experiences: [
        for (var i = 0; i < 8; i++)
          CvExperience(
            role: 'Senior Flutter Engineer',
            company: 'Northwind Apps $i',
            location: 'Doha, Qatar',
            startDate: '201$i',
            endDate: '202$i',
            bullets: const [
              'Led the migration to Riverpod and cut rebuilds sharply.',
              'Cut cold-start by 35% across the fleet.',
              'Owned the PostgreSQL and SQL reporting pipeline.',
            ],
          ),
      ],
      education: [
        for (var i = 0; i < 4; i++)
          const CvEducation(
            degree: 'BSc Computer Science',
            institution: 'Qatar University',
            startYear: '2014',
            endYear: '2018',
            details: 'Graduated with honours; focus on distributed systems.',
          ),
      ],
      skills: const [
        'Flutter', 'Dart', 'Firebase', 'SQL', 'Python', 'PostgreSQL',
        'Node.js', 'CI/CD', 'Riverpod', 'Testing', 'REST', 'GraphQL',
      ],
      projects: const [
        CvProject(
          name: 'Career Bridge',
          description: 'An AI job platform built with Flutter and Firebase.',
          link: 'https://github.com/sarah/career-bridge/tree/main/docs',
        ),
      ],
    );

void main() {
  // Every catalogued template must actually render — the catalog drives the
  // picker, so an unimplemented entry would be selectable but fail on export.
  for (final meta in cvTemplateCatalog) {
    final id = meta.id;

    test('generates a non-empty PDF for ${id.name} (EN)', () async {
      final bytes =
          await _generator.generate(_cv, templateId: id, languageCode: 'en');
      expect(bytes, isNotEmpty);
      // PDF files start with the "%PDF" magic bytes.
      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    });

    test('generates a PDF for ${id.name} with RTL layout (AR path)', () async {
      // ASCII content keeps built-in fonts happy while still exercising the
      // rtl/textDirection code path (real Arabic glyphs are verified live).
      final bytes =
          await _generator.generate(_cv, templateId: id, languageCode: 'ar');
      expect(bytes, isNotEmpty);
      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    });

    test('empty CV still generates for ${id.name} (no throw)', () async {
      final bytes = await _generator.generate(const CvData(),
          templateId: id, languageCode: 'en');
      expect(bytes, isNotEmpty);
    });

    test('multi-page CV generates for ${id.name} without overflowing',
        () async {
      for (final lang in ['en', 'ar']) {
        final bytes = await _generator.generate(_longCv(),
            templateId: id, languageCode: lang);
        expect(bytes, isNotEmpty, reason: '${id.name} / $lang');
      }
    });
  }

  test('every catalogued template id has a registered PDF template', () {
    for (final meta in cvTemplateCatalog) {
      expect(kCvTemplates[meta.id], isNotNull, reason: meta.id.name);
    }
    // And the catalog covers the whole enum — no id can be selected without
    // appearing in the picker.
    expect(cvTemplateCatalog.map((m) => m.id).toSet(), CvTemplateId.values.toSet());
  });

  test('an unregistered template id throws templateUnavailable', () async {
    // The generator's defensive guard: injecting an empty registry stands in
    // for an id that has no template.
    final bare = PdfCvGenerator(fonts: CvFonts.builtIn(), templates: const {});
    expect(
      () => bare.generate(_cv,
          templateId: CvTemplateId.modern, languageCode: 'en'),
      throwsA(isA<CvBuilderException>().having(
          (e) => e.code, 'code', CvErrorCode.templateUnavailable)),
    );
  });

  test('templates differ — each id produces its own layout', () async {
    final sizes = <CvTemplateId, int>{};
    for (final meta in cvTemplateCatalog) {
      final bytes = await _generator.generate(_cv,
          templateId: meta.id, languageCode: 'en', labels: CvLabels.fallback);
      sizes[meta.id] = bytes.length;
    }
    // Distinct layouts produce distinct documents; identical byte counts across
    // all four would mean the id is being ignored and one template reused.
    expect(sizes.values.toSet().length, greaterThan(1));
  });
}
