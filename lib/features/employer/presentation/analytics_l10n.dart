import '../../../core/localization/generated/app_localizations.dart';
import '../application/recruiter_insights_controller.dart';
import '../domain/analytics/employer_analytics.dart';
import '../domain/analytics/recruiter_insights.dart';

/// Localized label for an AI match band.
String matchBandLabel(AppLocalizations l10n, MatchBand band) => switch (band) {
      MatchBand.strong => l10n.analyticsBandStrong,
      MatchBand.good => l10n.analyticsBandGood,
      MatchBand.fair => l10n.analyticsBandFair,
      MatchBand.weak => l10n.analyticsBandWeak,
    };

/// Localized "High/Medium/Low priority" label for a suggested action.
String insightPriorityLabel(AppLocalizations l10n, InsightPriority p) =>
    switch (p) {
      InsightPriority.high => l10n.insightsPriorityHigh,
      InsightPriority.medium => l10n.insightsPriorityMedium,
      InsightPriority.low => l10n.insightsPriorityLow,
    };

/// Localized message for a recruiter-insights failure.
String insightsFailureMessage(
        AppLocalizations l10n, RecruiterInsightsFailure f) =>
    switch (f) {
      RecruiterInsightsFailure.network => l10n.insightsErrNetwork,
      RecruiterInsightsFailure.quota => l10n.insightsErrQuota,
      RecruiterInsightsFailure.empty => l10n.insightsErrEmpty,
      RecruiterInsightsFailure.notConfigured ||
      RecruiterInsightsFailure.invalidResponse ||
      RecruiterInsightsFailure.unknown =>
        l10n.insightsErrGeneric,
    };
