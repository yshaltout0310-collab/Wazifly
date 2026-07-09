/// Canonical analytics event + parameter names, in one place to avoid
/// stringly-typed drift (mirrors `RouteNames`). All names are snake_case, ≤ 40
/// chars, and avoid Firebase-reserved prefixes — enforced by a test.
abstract final class AnalyticsEvents {
  AnalyticsEvents._();

  // --- Seeker actions ---
  static const String jobApply = 'job_apply';
  static const String jobSave = 'job_save';
  static const String resumeAnalyze = 'resume_analyze';
  static const String cvExport = 'cv_export';
  static const String interviewComplete = 'interview_complete';
  static const String recommendationsRefresh = 'recommendations_refresh';
  static const String careerCoachMessage = 'career_coach_message';

  // --- Employer actions ---
  static const String jobPublish = 'job_publish';
  static const String jobArchive = 'job_archive';
  static const String applicantStatusChange = 'applicant_status_change';
  static const String recruiterInsightsGenerate = 'recruiter_insights_generate';

  // --- Media ---
  static const String profilePhotoUpload = 'profile_photo_upload';
  static const String companyLogoUpload = 'company_logo_upload';

  // --- Security (audit foundation) ---
  /// A security-sensitive event (auth failure, permission-denied, rule
  /// violation, App Check failure) — dimensioned by `event_type`. Logged via
  /// `SecurityAuditLog`, never directly by features.
  static const String securityEvent = 'security_event';

  /// All events, for validation tests.
  static const List<String> all = [
    jobApply,
    jobSave,
    resumeAnalyze,
    cvExport,
    interviewComplete,
    recommendationsRefresh,
    careerCoachMessage,
    jobPublish,
    jobArchive,
    applicantStatusChange,
    recruiterInsightsGenerate,
    profilePhotoUpload,
    companyLogoUpload,
    securityEvent,
  ];
}

/// Canonical analytics parameter keys.
abstract final class AnalyticsParams {
  AnalyticsParams._();

  static const String jobId = 'job_id';
  static const String status = 'status';
  static const String type = 'type';
  static const String accountType = 'account_type';
  static const String source = 'source';

  /// Security-event category (a `SecurityEventType.wireName`).
  static const String eventType = 'event_type';

  /// Short, non-PII descriptor for a security event (e.g. an error code).
  static const String reason = 'reason';
}

/// Canonical user-property names.
abstract final class AnalyticsUserProperties {
  AnalyticsUserProperties._();

  static const String accountType = 'account_type';
}
