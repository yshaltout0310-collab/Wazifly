import '../../../core/localization/generated/app_localizations.dart';
import '../application/employer_jobs_controller.dart';
import '../application/employer_jobs_providers.dart';
import '../application/job_editor_controller.dart';
import '../domain/employment_type.dart';
import '../domain/job_experience.dart';
import '../domain/job_status.dart';
import '../domain/job_validation.dart';
import '../domain/salary_period.dart';

/// Localized labels for the employer job-management enums, kept in one place so
/// the My Jobs list, editor, preview, and detail read the same strings. Mirrors
/// `company_l10n.dart`.
extension JobStatusL10n on JobStatus {
  String label(AppLocalizations l10n) => switch (this) {
        JobStatus.draft => l10n.jobStatusDraft,
        JobStatus.published => l10n.jobStatusPublished,
        JobStatus.archived => l10n.jobStatusArchived,
        JobStatus.closed => l10n.jobStatusClosed,
      };
}

extension EmploymentTypeL10n on EmploymentType {
  String label(AppLocalizations l10n) => switch (this) {
        EmploymentType.fullTime => l10n.empTypeFullTime,
        EmploymentType.partTime => l10n.empTypePartTime,
        EmploymentType.contract => l10n.empTypeContract,
        EmploymentType.internship => l10n.empTypeInternship,
        EmploymentType.temporary => l10n.empTypeTemporary,
      };
}

extension JobExperienceL10n on JobExperience {
  String label(AppLocalizations l10n) => switch (this) {
        JobExperience.entry => l10n.jobExpEntry,
        JobExperience.junior => l10n.jobExpJunior,
        JobExperience.mid => l10n.jobExpMid,
        JobExperience.senior => l10n.jobExpSenior,
        JobExperience.lead => l10n.jobExpLead,
      };
}

extension SalaryPeriodL10n on SalaryPeriod {
  String label(AppLocalizations l10n) => switch (this) {
        SalaryPeriod.yearly => l10n.salaryYearly,
        SalaryPeriod.monthly => l10n.salaryMonthly,
        SalaryPeriod.hourly => l10n.salaryHourly,
      };
}

extension JobSortL10n on JobSort {
  String label(AppLocalizations l10n) => switch (this) {
        JobSort.updated => l10n.jobSortUpdated,
        JobSort.created => l10n.jobSortCreated,
        JobSort.title => l10n.jobSortTitle,
        JobSort.status => l10n.jobSortStatus,
      };
}

/// A validation error → message. Some errors ([JobError.required] /
/// [JobError.tooShort]) read differently per field, so the field is passed in.
String jobErrorMessage(AppLocalizations l10n, JobField field, JobError error) =>
    switch (error) {
      JobError.required => l10n.jobErrRequired,
      JobError.tooShort => field == JobField.description
          ? l10n.jobErrDescShort
          : l10n.jobErrTitleShort,
      JobError.addSkill => l10n.jobErrAddSkill,
      JobError.chooseExperience => l10n.jobErrChooseExperience,
      JobError.chooseType => l10n.jobErrChooseType,
      JobError.invalidSalary => l10n.jobErrInvalidSalary,
      JobError.invalidOpenings => l10n.jobErrInvalidOpenings,
      JobError.invalidDates => l10n.jobErrInvalidDates,
    };

/// A lifecycle-action failure → snackbar message.
String jobsActionFailureMessage(AppLocalizations l10n, JobsActionFailure f) =>
    switch (f) {
      JobsActionFailure.permission => l10n.jobErrPermission,
      JobsActionFailure.network => l10n.jobErrNetwork,
      JobsActionFailure.unknown => l10n.jobActionFailed,
    };

/// A job-editor failure → snackbar message.
String jobEditorFailureMessage(AppLocalizations l10n, JobEditorFailure f) =>
    switch (f) {
      JobEditorFailure.notSignedIn => l10n.companyErrNotSignedIn,
      JobEditorFailure.noCompany ||
      JobEditorFailure.saveFailed ||
      JobEditorFailure.unknown =>
        l10n.jobActionFailed,
    };
