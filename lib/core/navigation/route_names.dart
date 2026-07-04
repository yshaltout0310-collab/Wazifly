/// Named routes + their paths, kept in one place to avoid stringly-typed bugs.
abstract final class RouteNames {
  RouteNames._();

  static const String splash = 'splash';
  static const String language = 'language';
  static const String country = 'country';
  static const String onboarding = 'onboarding';
  static const String welcome = 'welcome';
  static const String emailAuth = 'emailAuth';
  static const String phoneAuth = 'phoneAuth';
  static const String otp = 'otp';
  static const String userType = 'userType';
  static const String home = 'home';
  static const String settings = 'settings';
  static const String profile = 'profile';
  static const String editProfile = 'editProfile';
  static const String changePassword = 'changePassword';
  static const String resumeAnalyzer = 'resumeAnalyzer';
  static const String jobMatching = 'jobMatching';
  static const String careerCoach = 'careerCoach';
  static const String jobs = 'jobs';
  static const String jobDetail = 'jobDetail';
  static const String applications = 'applications';
  static const String applicationDetail = 'applicationDetail';

  static const String splashPath = '/';
  static const String languagePath = '/language';
  static const String countryPath = '/country';
  static const String onboardingPath = '/onboarding';
  static const String welcomePath = '/welcome';
  static const String emailAuthPath = '/auth/email';
  static const String phoneAuthPath = '/auth/phone';
  static const String otpPath = '/auth/otp';
  static const String userTypePath = '/user-type';
  static const String homePath = '/home';
  static const String settingsPath = '/settings';
  static const String profilePath = '/settings/profile';
  static const String editProfilePath = '/settings/profile/edit';
  static const String changePasswordPath = '/settings/change-password';
  static const String resumeAnalyzerPath = '/resume-analyzer';
  static const String jobMatchingPath = '/job-matching';
  static const String careerCoachPath = '/career-coach';
  static const String jobsPath = '/jobs';
  static const String jobDetailPath = '/jobs/:id';
  static const String applicationsPath = '/applications';
  static const String applicationDetailPath = '/applications/:id';
}
