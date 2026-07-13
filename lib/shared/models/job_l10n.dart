import '../../core/localization/generated/app_localizations.dart';

/// Localizes the seeker [Job]'s free-text controlled-vocabulary fields
/// (`employmentType`, `seniority`), which are stored as English seed strings, to
/// the active language so the chips read consistently in Arabic. Unknown values
/// fall back to the raw string.
String localizedEmploymentType(AppLocalizations l10n, String raw) {
  switch (raw.trim().toLowerCase()) {
    case 'full-time':
    case 'fulltime':
    case 'full time':
      return l10n.empTypeFullTime;
    case 'part-time':
    case 'parttime':
    case 'part time':
      return l10n.empTypePartTime;
    case 'contract':
      return l10n.empTypeContract;
    case 'internship':
      return l10n.empTypeInternship;
    case 'temporary':
      return l10n.empTypeTemporary;
    default:
      return raw;
  }
}

String localizedSeniority(AppLocalizations l10n, String raw) {
  switch (raw.trim().toLowerCase()) {
    case 'entry':
      return l10n.jobExpEntry;
    case 'junior':
      return l10n.jobExpJunior;
    case 'mid':
    case 'mid-level':
      return l10n.jobExpMid;
    case 'senior':
      return l10n.jobExpSenior;
    case 'lead':
      return l10n.jobExpLead;
    default:
      return raw;
  }
}
