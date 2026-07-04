import '../../../core/localization/generated/app_localizations.dart';
import '../application/interview_controller.dart';
import '../domain/interview_models.dart';

String interviewTypeName(AppLocalizations l10n, InterviewType type) =>
    switch (type) {
      InterviewType.hr => l10n.interviewTypeHr,
      InterviewType.technical => l10n.interviewTypeTechnical,
      InterviewType.behavioral => l10n.interviewTypeBehavioral,
    };

String interviewTypeDesc(AppLocalizations l10n, InterviewType type) =>
    switch (type) {
      InterviewType.hr => l10n.interviewTypeHrDesc,
      InterviewType.technical => l10n.interviewTypeTechnicalDesc,
      InterviewType.behavioral => l10n.interviewTypeBehavioralDesc,
    };

String interviewFailureMessage(AppLocalizations l10n, InterviewFailure f) =>
    switch (f) {
      InterviewFailure.noQuestions => l10n.interviewErrNoQuestions,
      InterviewFailure.emptyEvaluation => l10n.interviewErrEmptyEval,
      InterviewFailure.network => l10n.interviewErrNetwork,
      InterviewFailure.quota => l10n.interviewErrQuota,
      InterviewFailure.notConfigured ||
      InterviewFailure.invalidResponse ||
      InterviewFailure.unknown =>
        l10n.interviewErrGeneric,
    };

/// The 4 sub-dimension (label, value) pairs — overall is shown separately as a
/// gauge.
List<({String label, int value})> interviewScoreBars(
  AppLocalizations l10n,
  InterviewScores s,
) =>
    [
      (label: l10n.interviewScoreCommunication, value: s.communication),
      (label: l10n.interviewScoreTechnical, value: s.technicalAccuracy),
      (label: l10n.interviewScoreConfidence, value: s.confidence),
      (label: l10n.interviewScoreClarity, value: s.clarity),
    ];
