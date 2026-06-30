/// Keys used for key/value persistence (SharedPreferences).
abstract final class StorageKeys {
  StorageKeys._();

  static const String themeMode = 'pref_theme_mode';
  static const String languageCode = 'pref_language_code';
  static const String selectedCountry = 'pref_selected_country';
  static const String onboardingCompleted = 'pref_onboarding_completed';

  static const String userType = 'pref_user_type';
  static const String notificationsEnabled = 'pref_notifications_enabled';
}
