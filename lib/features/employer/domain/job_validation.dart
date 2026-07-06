import '../../../shared/models/job_posting.dart';

/// The editable job fields the validator reports on (drives inline errors).
enum JobField {
  title,
  description,
  skills,
  experience,
  employmentType,
  location,
  salary,
  openings,
  availability,
}

/// A stable, localizable validation error the presentation layer maps to a
/// message.
enum JobError {
  required,
  tooShort,
  addSkill,
  chooseExperience,
  chooseType,
  invalidSalary,
  invalidOpenings,
  invalidDates,
}

/// The outcome of validating a posting — a per-field error map.
class JobValidationResult {
  const JobValidationResult(this.errors);

  final Map<JobField, JobError> errors;

  static const JobValidationResult valid = JobValidationResult({});

  bool get isValid => errors.isEmpty;
  JobError? operator [](JobField field) => errors[field];
}

/// Pure, Flutter-free validation for a [JobPosting].
///
/// Two tiers: [forDraft] (lenient — a draft only needs a title) and [forPublish]
/// (complete — everything a live posting requires, plus validity of the optional
/// salary / openings / availability fields). Kept pure so it is fully
/// unit-testable and reusable by any future editor surface.
abstract final class JobValidator {
  JobValidator._();

  static const int minTitle = 3;
  static const int minDescription = 30;

  static JobValidationResult forDraft(JobPosting p) {
    final errors = <JobField, JobError>{};
    _title(p, errors);
    // Even a draft shouldn't persist invalid optional values.
    _optionals(p, errors);
    return JobValidationResult(errors);
  }

  static JobValidationResult forPublish(JobPosting p) {
    final errors = <JobField, JobError>{};
    _title(p, errors);
    if (p.description.trim().length < minDescription) {
      errors[JobField.description] = JobError.tooShort;
    }
    if (p.requiredSkills.isEmpty) errors[JobField.skills] = JobError.addSkill;
    if (p.experience == null) {
      errors[JobField.experience] = JobError.chooseExperience;
    }
    if (p.employmentType == null) {
      errors[JobField.employmentType] = JobError.chooseType;
    }
    if (p.location.trim().isEmpty) errors[JobField.location] = JobError.required;
    _optionals(p, errors);
    return JobValidationResult(errors);
  }

  static void _title(JobPosting p, Map<JobField, JobError> errors) {
    final t = p.title.trim();
    if (t.isEmpty) {
      errors[JobField.title] = JobError.required;
    } else if (t.length < minTitle) {
      errors[JobField.title] = JobError.tooShort;
    }
  }

  static void _optionals(JobPosting p, Map<JobField, JobError> errors) {
    if (p.salary != null && !p.salary!.isEmpty && !p.salary!.isValid) {
      errors[JobField.salary] = JobError.invalidSalary;
    }
    if (p.openings != null && p.openings! < 1) {
      errors[JobField.openings] = JobError.invalidOpenings;
    }
    if (p.opensAt != null &&
        p.expiresAt != null &&
        p.expiresAt!.isBefore(p.opensAt!)) {
      errors[JobField.availability] = JobError.invalidDates;
    }
  }
}
