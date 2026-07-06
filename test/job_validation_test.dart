import 'package:careerbridge/features/employer/domain/employment_type.dart';
import 'package:careerbridge/features/employer/domain/job_experience.dart';
import 'package:careerbridge/features/employer/domain/job_validation.dart';
import 'package:careerbridge/shared/models/job_posting.dart';
import 'package:flutter_test/flutter_test.dart';

JobPosting _base() => const JobPosting(id: 'j1', companyId: 'c1', ownerUid: 'c1');

/// A fully publishable posting.
JobPosting _publishable() => _base().copyWith(
      title: 'Senior Flutter Engineer',
      description:
          'We are hiring a senior Flutter engineer to build our mobile apps.',
      requiredSkills: const ['Flutter', 'Dart'],
      experience: JobExperience.senior,
      employmentType: EmploymentType.fullTime,
      location: 'Doha, Qatar',
    );

void main() {
  group('forDraft', () {
    test('a title alone is a valid draft', () {
      expect(JobValidator.forDraft(_base().copyWith(title: 'Role')).isValid,
          isTrue);
    });

    test('an empty title fails as required', () {
      final result = JobValidator.forDraft(_base());
      expect(result.isValid, isFalse);
      expect(result[JobField.title], JobError.required);
    });

    test('a 2-char title is too short', () {
      expect(JobValidator.forDraft(_base().copyWith(title: 'Hi'))[JobField.title],
          JobError.tooShort);
    });

    test('a draft still rejects invalid optional values', () {
      final result = JobValidator.forDraft(_base().copyWith(
        title: 'Role',
        salary: const SalaryRange(min: 200, max: 100),
        openings: 0,
      ));
      expect(result[JobField.salary], JobError.invalidSalary);
      expect(result[JobField.openings], JobError.invalidOpenings);
    });
  });

  group('forPublish', () {
    test('a complete posting is valid', () {
      expect(JobValidator.forPublish(_publishable()).isValid, isTrue);
    });

    test('reports every missing required field', () {
      final result = JobValidator.forPublish(_base().copyWith(title: 'Role'));
      expect(result[JobField.description], JobError.tooShort);
      expect(result[JobField.skills], JobError.addSkill);
      expect(result[JobField.experience], JobError.chooseExperience);
      expect(result[JobField.employmentType], JobError.chooseType);
      expect(result[JobField.location], JobError.required);
    });

    test('flags a short description', () {
      final result =
          JobValidator.forPublish(_publishable().copyWith(description: 'Short'));
      expect(result[JobField.description], JobError.tooShort);
    });

    test('flags expiration before opening', () {
      final result = JobValidator.forPublish(_publishable().copyWith(
        opensAt: DateTime(2026, 8, 1),
        expiresAt: DateTime(2026, 7, 1),
      ));
      expect(result[JobField.availability], JobError.invalidDates);
    });

    test('accepts valid availability dates', () {
      final result = JobValidator.forPublish(_publishable().copyWith(
        opensAt: DateTime(2026, 7, 1),
        expiresAt: DateTime(2026, 8, 1),
      ));
      expect(result.isValid, isTrue);
    });
  });
}
