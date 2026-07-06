import '../../../core/localization/generated/app_localizations.dart';
import '../../../shared/models/application.dart';
import '../application/employer_applicants_controller.dart';
import '../application/employer_applicants_providers.dart';
import '../application/employer_notes_controller.dart';

/// Localized labels for the applicants enums, kept in one place (mirrors
/// `employer_jobs_l10n.dart`). Status labels themselves reuse the shared
/// `applicationStatusLabel` (promoted to `shared/widgets`).
extension ApplicantSortL10n on ApplicantSort {
  String label(AppLocalizations l10n) => switch (this) {
        ApplicantSort.recent => l10n.applicantSortRecent,
        ApplicantSort.matchScore => l10n.applicantSortMatch,
        ApplicantSort.name => l10n.applicantSortName,
        ApplicantSort.status => l10n.applicantSortStatus,
      };
}

extension ApplicationSourceL10n on ApplicationSource {
  String label(AppLocalizations l10n) => switch (this) {
        ApplicationSource.careerBridge => l10n.sourceCareerBridge,
        ApplicationSource.referral => l10n.sourceReferral,
        ApplicationSource.externalImport => l10n.sourceExternalImport,
        ApplicationSource.companyWebsite => l10n.sourceCompanyWebsite,
      };
}

/// Applicant-action failures reuse the generic employer failure strings.
String applicantsActionFailureMessage(
        AppLocalizations l10n, ApplicantsActionFailure f) =>
    switch (f) {
      ApplicantsActionFailure.permission => l10n.jobErrPermission,
      ApplicantsActionFailure.network => l10n.jobErrNetwork,
      ApplicantsActionFailure.unknown => l10n.jobActionFailed,
    };

String notesActionFailureMessage(AppLocalizations l10n, NotesActionFailure f) =>
    switch (f) {
      NotesActionFailure.permission => l10n.jobErrPermission,
      NotesActionFailure.network => l10n.jobErrNetwork,
      NotesActionFailure.unknown => l10n.jobActionFailed,
    };
