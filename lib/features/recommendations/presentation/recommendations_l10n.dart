import '../../../core/localization/generated/app_localizations.dart';
import '../application/recommendations_controller.dart';
import '../domain/recommendation_models.dart';

String recPriorityLabel(AppLocalizations l10n, RecPriority p) => switch (p) {
      RecPriority.high => l10n.recPriorityHigh,
      RecPriority.medium => l10n.recPriorityMedium,
      RecPriority.low => l10n.recPriorityLow,
    };

String recHorizonLabel(AppLocalizations l10n, RecHorizon h) => switch (h) {
      RecHorizon.thisWeek => l10n.recHorizonThisWeek,
      RecHorizon.nextMonth => l10n.recHorizonNextMonth,
      RecHorizon.next3Months => l10n.recHorizonNext3Months,
      RecHorizon.sixToTwelveMonths => l10n.recHorizon6to12,
    };

/// Call-to-action label for a next-best-action's button.
String recActionLabel(AppLocalizations l10n, NextActionType t) => switch (t) {
      NextActionType.analyzeResume => l10n.recActionAnalyzeResume,
      NextActionType.buildCv => l10n.recActionBuildCv,
      NextActionType.practiceInterview => l10n.recActionPracticeInterview,
      NextActionType.browseJobs => l10n.recActionBrowseJobs,
      NextActionType.reviewApplications => l10n.recActionReviewApplications,
      NextActionType.completeProfile => l10n.recActionCompleteProfile,
      NextActionType.applyToJob => l10n.recActionApplyToJob,
      NextActionType.learnSkill => l10n.recActionLearnSkill,
      NextActionType.none => '',
    };

String recFailureMessage(AppLocalizations l10n, RecommendationFailure f) =>
    switch (f) {
      RecommendationFailure.network => l10n.recErrNetwork,
      RecommendationFailure.quota => l10n.recErrQuota,
      RecommendationFailure.empty => l10n.recErrEmpty,
      RecommendationFailure.notConfigured ||
      RecommendationFailure.invalidResponse ||
      RecommendationFailure.unknown =>
        l10n.recErrGeneric,
    };
