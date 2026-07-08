/// Keys used for key/value persistence (SharedPreferences).
abstract final class StorageKeys {
  StorageKeys._();

  static const String themeMode = 'pref_theme_mode';
  static const String languageCode = 'pref_language_code';
  static const String selectedCountry = 'pref_selected_country';
  static const String onboardingCompleted = 'pref_onboarding_completed';

  static const String userType = 'pref_user_type';

  /// Master push-notifications opt-in (kept for backward compatibility).
  static const String notificationsEnabled = 'pref_notifications_enabled';

  /// Granular notification categories (gated by the master toggle).
  static const String notifyJobAlerts = 'pref_notify_job_alerts';
  static const String notifyApplicationUpdates = 'pref_notify_application_updates';
  static const String notifyCoachTips = 'pref_notify_coach_tips';

  /// Analytics collection consent (opt-out foundation; defaults enabled).
  static const String analyticsConsent = 'pref_analytics_consent';
}
