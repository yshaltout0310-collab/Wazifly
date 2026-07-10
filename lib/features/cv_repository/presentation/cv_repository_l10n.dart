import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/services/cv_repository/cv_document.dart';
import '../application/cv_ai_controller.dart';
import '../domain/cv_repository_failure.dart';

/// Maps a [CvActionFailure] to a localized message.
String cvActionFailureMessage(AppLocalizations l10n, CvActionFailure f) =>
    switch (f) {
      CvActionFailure.lastActiveCv => l10n.cvLastActiveBody,
      CvActionFailure.notConfigured => l10n.cvErrNotConfigured,
      CvActionFailure.importNoText => l10n.cvErrImportNoText,
      CvActionFailure.importFailed => l10n.cvErrImportFailed,
      CvActionFailure.network => l10n.cvErrNetwork,
      CvActionFailure.quota => l10n.cvErrQuota,
      CvActionFailure.invalidResponse => l10n.cvErrInvalid,
      CvActionFailure.unknown => l10n.cvErrUnknown,
    };

/// Maps a [CvAiFailure] to a localized message.
String cvAiFailureMessage(AppLocalizations l10n, CvAiFailure f) => switch (f) {
      CvAiFailure.needsAnalysis => l10n.cvAiNeedAnalysis,
      CvAiFailure.notConfigured => l10n.cvErrNotConfigured,
      CvAiFailure.network => l10n.cvErrNetwork,
      CvAiFailure.quota => l10n.cvErrQuota,
      CvAiFailure.invalidResponse => l10n.cvErrInvalid,
      CvAiFailure.unknown => l10n.cvErrUnknown,
    };

/// "Last used today" / "Last used 3 days ago" / "Not used yet".
String cvLastUsedLabel(AppLocalizations l10n, DateTime? lastUsed,
    {DateTime? now}) {
  if (lastUsed == null) return l10n.cvLastUsedNever;
  final days = (now ?? DateTime.now()).difference(lastUsed).inDays;
  if (days <= 0) return l10n.cvLastUsedToday;
  return l10n.cvLastUsedAgo(days);
}

String cvSourceLabel(AppLocalizations l10n, CvSource source) => switch (source) {
      CvSource.built => l10n.cvSourceBuilt,
      CvSource.imported => l10n.cvSourceImported,
    };
