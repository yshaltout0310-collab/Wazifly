import 'package:careerbridge/shared/models/job.dart';
import 'package:flutter_test/flutter_test.dart';

Job _job({String? titleAr, String? descriptionAr, String? locationAr}) => Job(
      id: 'j1',
      title: 'Flutter Engineer',
      company: 'Acme',
      location: 'Doha, Qatar',
      employmentType: 'Full-time',
      seniority: 'Mid',
      description: 'Build apps.',
      requiredSkills: const ['Flutter'],
      remote: false,
      titleAr: titleAr,
      descriptionAr: descriptionAr,
      locationAr: locationAr,
    );

void main() {
  group('Job localized fields', () {
    test('uses the Arabic variant when lang is ar and it exists', () {
      final j = _job(
        titleAr: 'مهندس Flutter',
        descriptionAr: 'ابنِ التطبيقات.',
        locationAr: 'الدوحة، قطر',
      );
      expect(j.titleFor('ar'), 'مهندس Flutter');
      expect(j.descriptionFor('ar'), 'ابنِ التطبيقات.');
      expect(j.locationFor('ar'), 'الدوحة، قطر');
    });

    test('falls back to English when the Arabic field is missing', () {
      final j = _job(); // no Arabic fields
      expect(j.titleFor('ar'), 'Flutter Engineer');
      expect(j.descriptionFor('ar'), 'Build apps.');
      expect(j.locationFor('ar'), 'Doha, Qatar');
    });

    test('always uses English for the en locale', () {
      final j = _job(titleAr: 'مهندس Flutter');
      expect(j.titleFor('en'), 'Flutter Engineer');
    });

    test('fromJson parses the Arabic fields (and snake_case)', () {
      final j = Job.fromJson(const {
        'id': 'j2',
        'title': 'Data Engineer',
        'title_ar': 'مهندس بيانات',
        'company': 'Nile',
        'location': 'Cairo, Egypt',
        'descriptionAr': 'وصف',
        'description': 'desc',
      });
      expect(j.titleFor('ar'), 'مهندس بيانات');
      expect(j.descriptionFor('ar'), 'وصف');
      // No locationAr provided -> English fallback.
      expect(j.locationFor('ar'), 'Cairo, Egypt');
    });
  });
}
