import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// Application name.
  ///
  /// In en, this message translates to:
  /// **'Career Bridge'**
  String get appName;

  /// No description provided for @pageNotFound.
  ///
  /// In en, this message translates to:
  /// **'Page not found'**
  String get pageNotFound;

  /// Subtitle shown on the splash screen.
  ///
  /// In en, this message translates to:
  /// **'Powered by Advanced AI'**
  String get splashTagline;

  /// No description provided for @languageSelectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose Your Language'**
  String get languageSelectionTitle;

  /// No description provided for @languageSelectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select your preferred language — you can change it anytime.'**
  String get languageSelectionSubtitle;

  /// No description provided for @languageSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search language'**
  String get languageSearchHint;

  /// No description provided for @popularLanguages.
  ///
  /// In en, this message translates to:
  /// **'Popular Languages'**
  String get popularLanguages;

  /// No description provided for @moreLanguages.
  ///
  /// In en, this message translates to:
  /// **'More Languages'**
  String get moreLanguages;

  /// No description provided for @languageComingSoon.
  ///
  /// In en, this message translates to:
  /// **'{language} — coming soon'**
  String languageComingSoon(String language);

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @countrySelectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose Your Country'**
  String get countrySelectionTitle;

  /// No description provided for @countrySelectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll tailor jobs and dialing codes to your region.'**
  String get countrySelectionSubtitle;

  /// No description provided for @countrySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search countries'**
  String get countrySearchHint;

  /// No description provided for @onboardingTitle1.
  ///
  /// In en, this message translates to:
  /// **'Find Your Dream Job'**
  String get onboardingTitle1;

  /// No description provided for @onboardingBody1.
  ///
  /// In en, this message translates to:
  /// **'Discover opportunities that match your skills.'**
  String get onboardingBody1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In en, this message translates to:
  /// **'Powered by Advanced AI'**
  String get onboardingTitle2;

  /// No description provided for @onboardingBody2.
  ///
  /// In en, this message translates to:
  /// **'AI Resume Analysis, AI Career Coach, AI Interview Preparation, and Smart Job Matching.'**
  String get onboardingBody2;

  /// No description provided for @onboardingFeatureResume.
  ///
  /// In en, this message translates to:
  /// **'AI Resume Analysis'**
  String get onboardingFeatureResume;

  /// No description provided for @onboardingFeatureCoach.
  ///
  /// In en, this message translates to:
  /// **'AI Career Coach'**
  String get onboardingFeatureCoach;

  /// No description provided for @onboardingFeatureInterview.
  ///
  /// In en, this message translates to:
  /// **'AI Interview Preparation'**
  String get onboardingFeatureInterview;

  /// No description provided for @onboardingFeatureMatching.
  ///
  /// In en, this message translates to:
  /// **'Smart Job Matching'**
  String get onboardingFeatureMatching;

  /// No description provided for @onboardingTitle3.
  ///
  /// In en, this message translates to:
  /// **'Build Your Future'**
  String get onboardingTitle3;

  /// No description provided for @onboardingBody3.
  ///
  /// In en, this message translates to:
  /// **'Join employers and talents from around the world.'**
  String get onboardingBody3;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @authPlaceholderTitle.
  ///
  /// In en, this message translates to:
  /// **'Authentication'**
  String get authPlaceholderTitle;

  /// No description provided for @authPlaceholderBody.
  ///
  /// In en, this message translates to:
  /// **'Sign in & sign up arrive in the next phase.'**
  String get authPlaceholderBody;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @settingsAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccount;

  /// No description provided for @settingsPreferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get settingsPreferences;

  /// No description provided for @settingsSupport.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsSupport;

  /// No description provided for @settingsProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get settingsProfile;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// No description provided for @settingsNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Job alerts and personalized updates'**
  String get settingsNotificationsSubtitle;

  /// No description provided for @settingsReplayOnboarding.
  ///
  /// In en, this message translates to:
  /// **'View intro again'**
  String get settingsReplayOnboarding;

  /// No description provided for @settingsReplayOnboardingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Revisit the welcome tour'**
  String get settingsReplayOnboardingSubtitle;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settingsVersion;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageArabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get languageArabic;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logout;

  /// No description provided for @logoutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get logoutConfirmTitle;

  /// No description provided for @logoutConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ll need to sign in again to continue.'**
  String get logoutConfirmBody;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get profileEmailLabel;

  /// No description provided for @profilePhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get profilePhoneLabel;

  /// No description provided for @profileRoleLabel.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get profileRoleLabel;

  /// No description provided for @profileMethodLabel.
  ///
  /// In en, this message translates to:
  /// **'Signed in with'**
  String get profileMethodLabel;

  /// No description provided for @profileNotSignedIn.
  ///
  /// In en, this message translates to:
  /// **'You\'re not signed in'**
  String get profileNotSignedIn;

  /// No description provided for @profileNotSignedInBody.
  ///
  /// In en, this message translates to:
  /// **'Sign in to view and manage your profile.'**
  String get profileNotSignedInBody;

  /// No description provided for @notProvided.
  ///
  /// In en, this message translates to:
  /// **'Not provided'**
  String get notProvided;

  /// No description provided for @profileEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get profileEdit;

  /// No description provided for @editProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfileTitle;

  /// No description provided for @profileChangePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get profileChangePhoto;

  /// No description provided for @profileNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get profileNameLabel;

  /// No description provided for @profileHeadlineLabel.
  ///
  /// In en, this message translates to:
  /// **'Headline'**
  String get profileHeadlineLabel;

  /// No description provided for @profileHeadlineHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Senior Flutter Engineer'**
  String get profileHeadlineHint;

  /// No description provided for @profileLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get profileLocationLabel;

  /// No description provided for @profileLocationHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Doha, Qatar'**
  String get profileLocationHint;

  /// No description provided for @profileBioLabel.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get profileBioLabel;

  /// No description provided for @profileBioHint.
  ///
  /// In en, this message translates to:
  /// **'A short summary about you'**
  String get profileBioHint;

  /// No description provided for @profileSkillsLabel.
  ///
  /// In en, this message translates to:
  /// **'Skills'**
  String get profileSkillsLabel;

  /// No description provided for @profileSkillsHint.
  ///
  /// In en, this message translates to:
  /// **'Add a skill'**
  String get profileSkillsHint;

  /// No description provided for @profileExperienceLabel.
  ///
  /// In en, this message translates to:
  /// **'Experience level'**
  String get profileExperienceLabel;

  /// No description provided for @profileExperienceHint.
  ///
  /// In en, this message translates to:
  /// **'Select your level'**
  String get profileExperienceHint;

  /// No description provided for @profilePreferredTitlesLabel.
  ///
  /// In en, this message translates to:
  /// **'Preferred job titles'**
  String get profilePreferredTitlesLabel;

  /// No description provided for @profilePreferredTitlesHint.
  ///
  /// In en, this message translates to:
  /// **'Add a role you\'re targeting'**
  String get profilePreferredTitlesHint;

  /// No description provided for @profileLinksLabel.
  ///
  /// In en, this message translates to:
  /// **'Links'**
  String get profileLinksLabel;

  /// No description provided for @profilePortfolioLabel.
  ///
  /// In en, this message translates to:
  /// **'Portfolio'**
  String get profilePortfolioLabel;

  /// No description provided for @profileGithubLabel.
  ///
  /// In en, this message translates to:
  /// **'GitHub'**
  String get profileGithubLabel;

  /// No description provided for @profileLinkedinLabel.
  ///
  /// In en, this message translates to:
  /// **'LinkedIn'**
  String get profileLinkedinLabel;

  /// No description provided for @profileLinkHint.
  ///
  /// In en, this message translates to:
  /// **'https://…'**
  String get profileLinkHint;

  /// No description provided for @profileFieldOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get profileFieldOptional;

  /// No description provided for @profileAddDetails.
  ///
  /// In en, this message translates to:
  /// **'Add details to help employers and AI features understand you better.'**
  String get profileAddDetails;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile saved'**
  String get profileSaved;

  /// No description provided for @profileSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save your profile. Please try again.'**
  String get profileSaveFailed;

  /// No description provided for @profilePhotoUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t upload your photo. Please try again.'**
  String get profilePhotoUploadFailed;

  /// No description provided for @profileChipAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get profileChipAdd;

  /// No description provided for @profileCompletionTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile completion'**
  String get profileCompletionTitle;

  /// No description provided for @profileCompletionPercent.
  ///
  /// In en, this message translates to:
  /// **'{percent}% complete'**
  String profileCompletionPercent(int percent);

  /// No description provided for @profileCompletionComplete.
  ///
  /// In en, this message translates to:
  /// **'Your profile is complete'**
  String get profileCompletionComplete;

  /// No description provided for @profileCompletionNudge.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile for better matches and recommendations.'**
  String get profileCompletionNudge;

  /// No description provided for @experienceEntry.
  ///
  /// In en, this message translates to:
  /// **'Entry'**
  String get experienceEntry;

  /// No description provided for @experienceJunior.
  ///
  /// In en, this message translates to:
  /// **'Junior'**
  String get experienceJunior;

  /// No description provided for @experienceMid.
  ///
  /// In en, this message translates to:
  /// **'Mid'**
  String get experienceMid;

  /// No description provided for @experienceSenior.
  ///
  /// In en, this message translates to:
  /// **'Senior'**
  String get experienceSenior;

  /// No description provided for @experienceLead.
  ///
  /// In en, this message translates to:
  /// **'Lead'**
  String get experienceLead;

  /// No description provided for @settingsChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get settingsChangePassword;

  /// No description provided for @settingsChangePasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update your account password'**
  String get settingsChangePasswordSubtitle;

  /// No description provided for @changePasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePasswordTitle;

  /// No description provided for @changePasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your current password, then choose a new one.'**
  String get changePasswordSubtitle;

  /// No description provided for @changePasswordCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get changePasswordCurrent;

  /// No description provided for @changePasswordNew.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get changePasswordNew;

  /// No description provided for @changePasswordConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get changePasswordConfirm;

  /// No description provided for @changePasswordSubmit.
  ///
  /// In en, this message translates to:
  /// **'Update password'**
  String get changePasswordSubmit;

  /// No description provided for @changePasswordSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password updated'**
  String get changePasswordSuccess;

  /// No description provided for @changePasswordEmptyFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all fields.'**
  String get changePasswordEmptyFields;

  /// No description provided for @changePasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'New password must be at least 6 characters.'**
  String get changePasswordTooShort;

  /// No description provided for @changePasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'New passwords don\'t match.'**
  String get changePasswordMismatch;

  /// No description provided for @notifyJobAlerts.
  ///
  /// In en, this message translates to:
  /// **'Job alerts'**
  String get notifyJobAlerts;

  /// No description provided for @notifyJobAlertsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'New roles that match you'**
  String get notifyJobAlertsSubtitle;

  /// No description provided for @notifyApplicationUpdates.
  ///
  /// In en, this message translates to:
  /// **'Application updates'**
  String get notifyApplicationUpdates;

  /// No description provided for @notifyApplicationUpdatesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Status changes on your applications'**
  String get notifyApplicationUpdatesSubtitle;

  /// No description provided for @notifyCoachTips.
  ///
  /// In en, this message translates to:
  /// **'Coach tips'**
  String get notifyCoachTips;

  /// No description provided for @notifyCoachTipsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Personalized career suggestions'**
  String get notifyCoachTipsSubtitle;

  /// No description provided for @cvBuilderTitle.
  ///
  /// In en, this message translates to:
  /// **'CV Builder'**
  String get cvBuilderTitle;

  /// No description provided for @cvBuilderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Build a professional CV from your profile'**
  String get cvBuilderSubtitle;

  /// No description provided for @cvNeedsProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to build your CV'**
  String get cvNeedsProfileTitle;

  /// No description provided for @cvNeedsProfileBody.
  ///
  /// In en, this message translates to:
  /// **'Your CV is built from your profile — sign in to continue.'**
  String get cvNeedsProfileBody;

  /// No description provided for @cvResetFromProfile.
  ///
  /// In en, this message translates to:
  /// **'Reset from profile'**
  String get cvResetFromProfile;

  /// No description provided for @cvContactSection.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get cvContactSection;

  /// No description provided for @cvFullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get cvFullName;

  /// No description provided for @cvHeadline.
  ///
  /// In en, this message translates to:
  /// **'Professional headline'**
  String get cvHeadline;

  /// No description provided for @cvEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get cvEmail;

  /// No description provided for @cvPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get cvPhone;

  /// No description provided for @cvLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get cvLocation;

  /// No description provided for @cvTargetRole.
  ///
  /// In en, this message translates to:
  /// **'Target role'**
  String get cvTargetRole;

  /// No description provided for @cvTargetRoleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Senior Flutter Engineer'**
  String get cvTargetRoleHint;

  /// No description provided for @cvSummarySection.
  ///
  /// In en, this message translates to:
  /// **'Professional summary'**
  String get cvSummarySection;

  /// No description provided for @cvSummaryHint.
  ///
  /// In en, this message translates to:
  /// **'A short pitch — or let AI write it for you'**
  String get cvSummaryHint;

  /// No description provided for @cvExperienceSection.
  ///
  /// In en, this message translates to:
  /// **'Experience'**
  String get cvExperienceSection;

  /// No description provided for @cvAddExperience.
  ///
  /// In en, this message translates to:
  /// **'Add experience'**
  String get cvAddExperience;

  /// No description provided for @cvRole.
  ///
  /// In en, this message translates to:
  /// **'Job title'**
  String get cvRole;

  /// No description provided for @cvCompany.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get cvCompany;

  /// No description provided for @cvStartDate.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get cvStartDate;

  /// No description provided for @cvEndDate.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get cvEndDate;

  /// No description provided for @cvCurrentRole.
  ///
  /// In en, this message translates to:
  /// **'I currently work here'**
  String get cvCurrentRole;

  /// No description provided for @cvHighlights.
  ///
  /// In en, this message translates to:
  /// **'Highlights'**
  String get cvHighlights;

  /// No description provided for @cvAddHighlight.
  ///
  /// In en, this message translates to:
  /// **'Add highlight'**
  String get cvAddHighlight;

  /// No description provided for @cvEducationSection.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get cvEducationSection;

  /// No description provided for @cvAddEducation.
  ///
  /// In en, this message translates to:
  /// **'Add education'**
  String get cvAddEducation;

  /// No description provided for @cvDegree.
  ///
  /// In en, this message translates to:
  /// **'Degree'**
  String get cvDegree;

  /// No description provided for @cvInstitution.
  ///
  /// In en, this message translates to:
  /// **'Institution'**
  String get cvInstitution;

  /// No description provided for @cvSkillsSection.
  ///
  /// In en, this message translates to:
  /// **'Skills'**
  String get cvSkillsSection;

  /// No description provided for @cvSkillHint.
  ///
  /// In en, this message translates to:
  /// **'Add a skill'**
  String get cvSkillHint;

  /// No description provided for @cvProjectsSection.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get cvProjectsSection;

  /// No description provided for @cvPresent.
  ///
  /// In en, this message translates to:
  /// **'Present'**
  String get cvPresent;

  /// No description provided for @cvLinksSection.
  ///
  /// In en, this message translates to:
  /// **'Links'**
  String get cvLinksSection;

  /// No description provided for @cvRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get cvRemove;

  /// No description provided for @cvEnhanceWithAi.
  ///
  /// In en, this message translates to:
  /// **'Enhance with AI'**
  String get cvEnhanceWithAi;

  /// No description provided for @cvEnhancing.
  ///
  /// In en, this message translates to:
  /// **'Enhancing your CV…'**
  String get cvEnhancing;

  /// No description provided for @cvEnhanced.
  ///
  /// In en, this message translates to:
  /// **'CV enhanced with AI'**
  String get cvEnhanced;

  /// No description provided for @cvPreviewExport.
  ///
  /// In en, this message translates to:
  /// **'Preview & export'**
  String get cvPreviewExport;

  /// No description provided for @cvTemplateSection.
  ///
  /// In en, this message translates to:
  /// **'Template'**
  String get cvTemplateSection;

  /// No description provided for @cvExportPdf.
  ///
  /// In en, this message translates to:
  /// **'Export PDF'**
  String get cvExportPdf;

  /// No description provided for @cvPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get cvPreviewTitle;

  /// No description provided for @cvGenerating.
  ///
  /// In en, this message translates to:
  /// **'Generating your PDF…'**
  String get cvGenerating;

  /// No description provided for @cvExportError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t generate the PDF. Please try again.'**
  String get cvExportError;

  /// No description provided for @cvEnhanceFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t enhance your CV. Please try again.'**
  String get cvEnhanceFailed;

  /// No description provided for @cvErrNetwork.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Check your network and try again.'**
  String get cvErrNetwork;

  /// No description provided for @cvErrQuota.
  ///
  /// In en, this message translates to:
  /// **'The AI service is busy right now. Please try again shortly.'**
  String get cvErrQuota;

  /// No description provided for @cvErrEmpty.
  ///
  /// In en, this message translates to:
  /// **'Add more detail to your CV, then try enhancing again.'**
  String get cvErrEmpty;

  /// No description provided for @cvEmptyPreview.
  ///
  /// In en, this message translates to:
  /// **'Add your details first to preview your CV.'**
  String get cvEmptyPreview;

  /// No description provided for @cvTemplateAts.
  ///
  /// In en, this message translates to:
  /// **'ATS'**
  String get cvTemplateAts;

  /// No description provided for @cvTemplateAtsDesc.
  ///
  /// In en, this message translates to:
  /// **'Clean, applicant-tracking-friendly'**
  String get cvTemplateAtsDesc;

  /// No description provided for @cvTemplateModern.
  ///
  /// In en, this message translates to:
  /// **'Modern'**
  String get cvTemplateModern;

  /// No description provided for @cvTemplateModernDesc.
  ///
  /// In en, this message translates to:
  /// **'Sleek, accented layout'**
  String get cvTemplateModernDesc;

  /// No description provided for @cvTemplateMinimal.
  ///
  /// In en, this message translates to:
  /// **'Minimal'**
  String get cvTemplateMinimal;

  /// No description provided for @cvTemplateMinimalDesc.
  ///
  /// In en, this message translates to:
  /// **'Simple and spacious'**
  String get cvTemplateMinimalDesc;

  /// No description provided for @cvTemplateHarvard.
  ///
  /// In en, this message translates to:
  /// **'Harvard'**
  String get cvTemplateHarvard;

  /// No description provided for @cvTemplateHarvardDesc.
  ///
  /// In en, this message translates to:
  /// **'Classic academic format'**
  String get cvTemplateHarvardDesc;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Career Bridge'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your AI-powered career partner'**
  String get welcomeSubtitle;

  /// No description provided for @continueWithEmail.
  ///
  /// In en, this message translates to:
  /// **'Continue with Email'**
  String get continueWithEmail;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @continueWithPhone.
  ///
  /// In en, this message translates to:
  /// **'Continue with Phone'**
  String get continueWithPhone;

  /// No description provided for @authOr.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get authOr;

  /// No description provided for @termsNote.
  ///
  /// In en, this message translates to:
  /// **'By continuing you agree to our Terms & Privacy Policy.'**
  String get termsNote;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @emailAuthTitleSignIn.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get emailAuthTitleSignIn;

  /// No description provided for @emailAuthTitleSignUp.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get emailAuthTitleSignUp;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @noAccountPrompt.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get noAccountPrompt;

  /// No description provided for @haveAccountPrompt.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get haveAccountPrompt;

  /// No description provided for @phoneAuthTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number'**
  String get phoneAuthTitle;

  /// No description provided for @phoneAuthSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll text you a 6-digit verification code.'**
  String get phoneAuthSubtitle;

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneLabel;

  /// No description provided for @sendCode.
  ///
  /// In en, this message translates to:
  /// **'Send Code'**
  String get sendCode;

  /// No description provided for @otpTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your number'**
  String get otpTitle;

  /// No description provided for @otpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code we just sent to'**
  String get otpSubtitle;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get resendCode;

  /// No description provided for @userTypeTitle.
  ///
  /// In en, this message translates to:
  /// **'How will you use Career Bridge?'**
  String get userTypeTitle;

  /// No description provided for @userTypeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You can change this anytime in settings.'**
  String get userTypeSubtitle;

  /// No description provided for @jobSeeker.
  ///
  /// In en, this message translates to:
  /// **'Job Seeker'**
  String get jobSeeker;

  /// No description provided for @jobSeekerDesc.
  ///
  /// In en, this message translates to:
  /// **'Find jobs matched to your skills.'**
  String get jobSeekerDesc;

  /// No description provided for @employer.
  ///
  /// In en, this message translates to:
  /// **'Employer'**
  String get employer;

  /// No description provided for @employerDesc.
  ///
  /// In en, this message translates to:
  /// **'Hire top talent for your company.'**
  String get employerDesc;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @homeWelcome.
  ///
  /// In en, this message translates to:
  /// **'You\'re all set!'**
  String get homeWelcome;

  /// No description provided for @homeComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Job features arrive in the next phase.'**
  String get homeComingSoon;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @homeGreeting.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get homeGreeting;

  /// No description provided for @homeToolkitTitle.
  ///
  /// In en, this message translates to:
  /// **'Your AI toolkit'**
  String get homeToolkitTitle;

  /// No description provided for @homeToolkitSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Powerful tools launching in the next phase.'**
  String get homeToolkitSubtitle;

  /// No description provided for @comingSoonBadge.
  ///
  /// In en, this message translates to:
  /// **'Soon'**
  String get comingSoonBadge;

  /// No description provided for @featResumeAnalyzer.
  ///
  /// In en, this message translates to:
  /// **'Resume Analyzer'**
  String get featResumeAnalyzer;

  /// No description provided for @featJobMatching.
  ///
  /// In en, this message translates to:
  /// **'AI Job Matching'**
  String get featJobMatching;

  /// No description provided for @featCareerCoach.
  ///
  /// In en, this message translates to:
  /// **'Career Coach'**
  String get featCareerCoach;

  /// No description provided for @featCvBuilder.
  ///
  /// In en, this message translates to:
  /// **'CV Builder'**
  String get featCvBuilder;

  /// No description provided for @featInterviewPrep.
  ///
  /// In en, this message translates to:
  /// **'Interview Prep'**
  String get featInterviewPrep;

  /// No description provided for @featRecommendations.
  ///
  /// In en, this message translates to:
  /// **'For You'**
  String get featRecommendations;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get fieldRequired;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get invalidEmail;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordTooShort;

  /// No description provided for @invalidOtp.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code'**
  String get invalidOtp;

  /// No description provided for @authFailed.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get authFailed;

  /// No description provided for @errInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password.'**
  String get errInvalidCredentials;

  /// No description provided for @errEmailInUse.
  ///
  /// In en, this message translates to:
  /// **'An account already exists for this email.'**
  String get errEmailInUse;

  /// No description provided for @errUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'No account found for this email.'**
  String get errUserNotFound;

  /// No description provided for @errWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Please choose a stronger password (6+ characters).'**
  String get errWeakPassword;

  /// No description provided for @errNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network error. Check your connection and try again.'**
  String get errNetwork;

  /// No description provided for @errTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please try again later.'**
  String get errTooManyRequests;

  /// No description provided for @errInvalidPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid phone number.'**
  String get errInvalidPhone;

  /// No description provided for @errInvalidOtpCode.
  ///
  /// In en, this message translates to:
  /// **'That code isn\'t correct. Please try again.'**
  String get errInvalidOtpCode;

  /// No description provided for @errOperationNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'This sign-in method isn\'t enabled yet.'**
  String get errOperationNotAllowed;

  /// No description provided for @errCancelled.
  ///
  /// In en, this message translates to:
  /// **'Sign-in was cancelled.'**
  String get errCancelled;

  /// No description provided for @passwordResetSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset link sent to your email.'**
  String get passwordResetSent;

  /// No description provided for @loadingSigningIn.
  ///
  /// In en, this message translates to:
  /// **'Signing you in…'**
  String get loadingSigningIn;

  /// No description provided for @loadingCreatingAccount.
  ///
  /// In en, this message translates to:
  /// **'Creating your account…'**
  String get loadingCreatingAccount;

  /// No description provided for @loadingSendingCode.
  ///
  /// In en, this message translates to:
  /// **'Sending code…'**
  String get loadingSendingCode;

  /// No description provided for @loadingVerifying.
  ///
  /// In en, this message translates to:
  /// **'Verifying…'**
  String get loadingVerifying;

  /// No description provided for @resumeAnalyzerTitle.
  ///
  /// In en, this message translates to:
  /// **'Resume Analyzer'**
  String get resumeAnalyzerTitle;

  /// No description provided for @resumeAnalyzerIntro.
  ///
  /// In en, this message translates to:
  /// **'Upload your resume as a PDF and get instant, AI-powered feedback.'**
  String get resumeAnalyzerIntro;

  /// No description provided for @resumeUploadTitle.
  ///
  /// In en, this message translates to:
  /// **'Upload your resume'**
  String get resumeUploadTitle;

  /// No description provided for @resumeUploadHint.
  ///
  /// In en, this message translates to:
  /// **'PDF file'**
  String get resumeUploadHint;

  /// No description provided for @resumeChoosePdf.
  ///
  /// In en, this message translates to:
  /// **'Choose PDF'**
  String get resumeChoosePdf;

  /// No description provided for @resumeAnalyzeAnother.
  ///
  /// In en, this message translates to:
  /// **'Analyze another resume'**
  String get resumeAnalyzeAnother;

  /// No description provided for @resumeAnalyzing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing your resume…'**
  String get resumeAnalyzing;

  /// No description provided for @resumeAnalyzingHint.
  ///
  /// In en, this message translates to:
  /// **'This usually takes a few seconds.'**
  String get resumeAnalyzingHint;

  /// No description provided for @resumeAtsScore.
  ///
  /// In en, this message translates to:
  /// **'ATS Score'**
  String get resumeAtsScore;

  /// No description provided for @resumeScoreExcellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get resumeScoreExcellent;

  /// No description provided for @resumeScoreGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get resumeScoreGood;

  /// No description provided for @resumeScoreFair.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get resumeScoreFair;

  /// No description provided for @resumeScoreNeedsWork.
  ///
  /// In en, this message translates to:
  /// **'Needs work'**
  String get resumeScoreNeedsWork;

  /// No description provided for @resumeSectionSummary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get resumeSectionSummary;

  /// No description provided for @resumeSectionStrengths.
  ///
  /// In en, this message translates to:
  /// **'Strengths'**
  String get resumeSectionStrengths;

  /// No description provided for @resumeSectionWeaknesses.
  ///
  /// In en, this message translates to:
  /// **'Weaknesses'**
  String get resumeSectionWeaknesses;

  /// No description provided for @resumeSectionMissingSkills.
  ///
  /// In en, this message translates to:
  /// **'Missing Skills'**
  String get resumeSectionMissingSkills;

  /// No description provided for @resumeSectionGrammar.
  ///
  /// In en, this message translates to:
  /// **'Grammar & Writing'**
  String get resumeSectionGrammar;

  /// No description provided for @resumeSectionSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Improvement Suggestions'**
  String get resumeSectionSuggestions;

  /// No description provided for @resumeGrammarFix.
  ///
  /// In en, this message translates to:
  /// **'Suggestion'**
  String get resumeGrammarFix;

  /// No description provided for @resumeRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get resumeRetry;

  /// No description provided for @resumeErrNoText.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t read any text from this PDF. If it\'s a scanned image, please upload a text-based PDF.'**
  String get resumeErrNoText;

  /// No description provided for @resumeErrExtraction.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t open this PDF. Please try another file.'**
  String get resumeErrExtraction;

  /// No description provided for @resumeErrTooLarge.
  ///
  /// In en, this message translates to:
  /// **'This file is too large. Please choose a smaller PDF.'**
  String get resumeErrTooLarge;

  /// No description provided for @resumeErrNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'AI isn\'t enabled yet. Enable Firebase AI Logic to use the analyzer.'**
  String get resumeErrNotConfigured;

  /// No description provided for @resumeErrNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network error. Check your connection and try again.'**
  String get resumeErrNetwork;

  /// No description provided for @resumeErrQuota.
  ///
  /// In en, this message translates to:
  /// **'The AI service is busy right now. Please try again shortly.'**
  String get resumeErrQuota;

  /// No description provided for @resumeErrInvalid.
  ///
  /// In en, this message translates to:
  /// **'The AI returned an unexpected result. Please try again.'**
  String get resumeErrInvalid;

  /// No description provided for @resumeErrBlocked.
  ///
  /// In en, this message translates to:
  /// **'This content couldn\'t be analyzed.'**
  String get resumeErrBlocked;

  /// No description provided for @resumeErrUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get resumeErrUnknown;

  /// No description provided for @jobMatchTitle.
  ///
  /// In en, this message translates to:
  /// **'Job Matching'**
  String get jobMatchTitle;

  /// No description provided for @jobMatchNeedsResumeTitle.
  ///
  /// In en, this message translates to:
  /// **'Match jobs to your resume'**
  String get jobMatchNeedsResumeTitle;

  /// No description provided for @jobMatchNeedsResumeBody.
  ///
  /// In en, this message translates to:
  /// **'Upload your resume and we\'ll rank jobs by how well they fit — with an AI explanation for each.'**
  String get jobMatchNeedsResumeBody;

  /// No description provided for @jobMatchUploadResume.
  ///
  /// In en, this message translates to:
  /// **'Upload resume'**
  String get jobMatchUploadResume;

  /// No description provided for @jobMatchMatching.
  ///
  /// In en, this message translates to:
  /// **'Finding your best matches…'**
  String get jobMatchMatching;

  /// No description provided for @jobMatchMatchingHint.
  ///
  /// In en, this message translates to:
  /// **'Ranking jobs against your resume.'**
  String get jobMatchMatchingHint;

  /// No description provided for @jobMatchAnalyzingResume.
  ///
  /// In en, this message translates to:
  /// **'Analyzing your resume…'**
  String get jobMatchAnalyzingResume;

  /// No description provided for @jobMatchAnalyzingResumeHint.
  ///
  /// In en, this message translates to:
  /// **'This usually takes a few seconds.'**
  String get jobMatchAnalyzingResumeHint;

  /// No description provided for @jobMatchResultsHeader.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 job ranked for you} other{{count} jobs ranked for you}}'**
  String jobMatchResultsHeader(int count);

  /// No description provided for @jobMatchUseAnother.
  ///
  /// In en, this message translates to:
  /// **'Match a different resume'**
  String get jobMatchUseAnother;

  /// No description provided for @jobMatchRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get jobMatchRetry;

  /// No description provided for @jobMatchMatchingSkills.
  ///
  /// In en, this message translates to:
  /// **'Matching skills'**
  String get jobMatchMatchingSkills;

  /// No description provided for @jobMatchMissingSkills.
  ///
  /// In en, this message translates to:
  /// **'Skills to add'**
  String get jobMatchMissingSkills;

  /// No description provided for @jobMatchStrong.
  ///
  /// In en, this message translates to:
  /// **'Strong match'**
  String get jobMatchStrong;

  /// No description provided for @jobMatchGood.
  ///
  /// In en, this message translates to:
  /// **'Good match'**
  String get jobMatchGood;

  /// No description provided for @jobMatchFair.
  ///
  /// In en, this message translates to:
  /// **'Fair match'**
  String get jobMatchFair;

  /// No description provided for @jobMatchWeak.
  ///
  /// In en, this message translates to:
  /// **'Low match'**
  String get jobMatchWeak;

  /// No description provided for @jobMatchErrNoJobs.
  ///
  /// In en, this message translates to:
  /// **'No jobs are available to match right now. Please try again later.'**
  String get jobMatchErrNoJobs;

  /// No description provided for @jobMatchErrNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'AI isn\'t enabled yet. Enable Firebase AI Logic to match jobs.'**
  String get jobMatchErrNotConfigured;

  /// No description provided for @jobMatchErrNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network error. Check your connection and try again.'**
  String get jobMatchErrNetwork;

  /// No description provided for @jobMatchErrQuota.
  ///
  /// In en, this message translates to:
  /// **'The AI service is busy right now. Please try again shortly.'**
  String get jobMatchErrQuota;

  /// No description provided for @jobMatchErrInvalid.
  ///
  /// In en, this message translates to:
  /// **'The AI returned an unexpected result. Please try again.'**
  String get jobMatchErrInvalid;

  /// No description provided for @jobMatchErrBlocked.
  ///
  /// In en, this message translates to:
  /// **'This content couldn\'t be analyzed.'**
  String get jobMatchErrBlocked;

  /// No description provided for @jobMatchErrUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get jobMatchErrUnknown;

  /// No description provided for @coachTitle.
  ///
  /// In en, this message translates to:
  /// **'Career Coach'**
  String get coachTitle;

  /// No description provided for @coachIntroTitle.
  ///
  /// In en, this message translates to:
  /// **'Your AI Career Coach'**
  String get coachIntroTitle;

  /// No description provided for @coachIntroBody.
  ///
  /// In en, this message translates to:
  /// **'Ask about career paths, learning roadmaps, interview prep, or how to grow your skills. Tailored to your resume when you\'ve analyzed one.'**
  String get coachIntroBody;

  /// No description provided for @coachInputHint.
  ///
  /// In en, this message translates to:
  /// **'Ask your career coach…'**
  String get coachInputHint;

  /// No description provided for @coachSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get coachSend;

  /// No description provided for @coachClear.
  ///
  /// In en, this message translates to:
  /// **'Clear chat'**
  String get coachClear;

  /// No description provided for @coachRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get coachRetry;

  /// No description provided for @coachPrompt1.
  ///
  /// In en, this message translates to:
  /// **'How can I improve my resume?'**
  String get coachPrompt1;

  /// No description provided for @coachPrompt2.
  ///
  /// In en, this message translates to:
  /// **'What skills should I learn next?'**
  String get coachPrompt2;

  /// No description provided for @coachPrompt3.
  ///
  /// In en, this message translates to:
  /// **'Help me prepare for an interview.'**
  String get coachPrompt3;

  /// No description provided for @coachPrompt4.
  ///
  /// In en, this message translates to:
  /// **'Suggest a learning roadmap for my career.'**
  String get coachPrompt4;

  /// No description provided for @coachErrNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'AI isn\'t enabled yet. Enable Firebase AI Logic to use the coach.'**
  String get coachErrNotConfigured;

  /// No description provided for @coachErrNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network error. Check your connection and try again.'**
  String get coachErrNetwork;

  /// No description provided for @coachErrQuota.
  ///
  /// In en, this message translates to:
  /// **'The AI service is busy right now. Please try again shortly.'**
  String get coachErrQuota;

  /// No description provided for @coachErrBlocked.
  ///
  /// In en, this message translates to:
  /// **'This message couldn\'t be answered.'**
  String get coachErrBlocked;

  /// No description provided for @coachErrEmpty.
  ///
  /// In en, this message translates to:
  /// **'The coach didn\'t respond. Please try again.'**
  String get coachErrEmpty;

  /// No description provided for @coachErrUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get coachErrUnknown;

  /// No description provided for @homeBrowseJobs.
  ///
  /// In en, this message translates to:
  /// **'Browse Jobs'**
  String get homeBrowseJobs;

  /// No description provided for @homeBrowseJobsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Search roles, see your matches, save favorites'**
  String get homeBrowseJobsSubtitle;

  /// No description provided for @jobsTitle.
  ///
  /// In en, this message translates to:
  /// **'Jobs'**
  String get jobsTitle;

  /// No description provided for @jobsTabAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get jobsTabAll;

  /// No description provided for @jobsTabMatches.
  ///
  /// In en, this message translates to:
  /// **'Best matches'**
  String get jobsTabMatches;

  /// No description provided for @jobsTabSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get jobsTabSaved;

  /// No description provided for @jobsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search jobs, companies, skills'**
  String get jobsSearchHint;

  /// No description provided for @jobsFilters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get jobsFilters;

  /// No description provided for @jobsClearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get jobsClearFilters;

  /// No description provided for @jobsRemoteOnly.
  ///
  /// In en, this message translates to:
  /// **'Remote only'**
  String get jobsRemoteOnly;

  /// No description provided for @jobsEmploymentType.
  ///
  /// In en, this message translates to:
  /// **'Employment type'**
  String get jobsEmploymentType;

  /// No description provided for @jobsSeniority.
  ///
  /// In en, this message translates to:
  /// **'Seniority'**
  String get jobsSeniority;

  /// No description provided for @jobsShowResults.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No results} =1{Show 1 result} other{Show {count} results}}'**
  String jobsShowResults(int count);

  /// No description provided for @jobsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 job} other{{count} jobs}}'**
  String jobsCount(int count);

  /// No description provided for @jobsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load jobs. Please try again.'**
  String get jobsLoadError;

  /// No description provided for @jobsNoResults.
  ///
  /// In en, this message translates to:
  /// **'No jobs match your search.'**
  String get jobsNoResults;

  /// No description provided for @jobsNoSaved.
  ///
  /// In en, this message translates to:
  /// **'No saved jobs yet. Tap the bookmark on a job to save it.'**
  String get jobsNoSaved;

  /// No description provided for @jobsMatchesNeedResume.
  ///
  /// In en, this message translates to:
  /// **'Analyze your resume to see your best-matched jobs.'**
  String get jobsMatchesNeedResume;

  /// No description provided for @jobsAnalyzeResume.
  ///
  /// In en, this message translates to:
  /// **'Analyze resume'**
  String get jobsAnalyzeResume;

  /// No description provided for @jobsSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get jobsSave;

  /// No description provided for @jobsUnsave.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get jobsUnsave;

  /// No description provided for @jobsApplied.
  ///
  /// In en, this message translates to:
  /// **'Applied'**
  String get jobsApplied;

  /// No description provided for @jobsDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Job details'**
  String get jobsDetailTitle;

  /// No description provided for @jobsNotFound.
  ///
  /// In en, this message translates to:
  /// **'This job is no longer available.'**
  String get jobsNotFound;

  /// No description provided for @jobsRemote.
  ///
  /// In en, this message translates to:
  /// **'Remote'**
  String get jobsRemote;

  /// No description provided for @jobsDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get jobsDescription;

  /// No description provided for @jobsRequiredSkills.
  ///
  /// In en, this message translates to:
  /// **'Required skills'**
  String get jobsRequiredSkills;

  /// No description provided for @jobsMatchNoResume.
  ///
  /// In en, this message translates to:
  /// **'See how well you match — analyze your resume first.'**
  String get jobsMatchNoResume;

  /// No description provided for @jobsMatchPrompt.
  ///
  /// In en, this message translates to:
  /// **'Check how well your resume matches this job.'**
  String get jobsMatchPrompt;

  /// No description provided for @jobsSeeMatch.
  ///
  /// In en, this message translates to:
  /// **'See match'**
  String get jobsSeeMatch;

  /// No description provided for @jobsMatchLoading.
  ///
  /// In en, this message translates to:
  /// **'Checking your match…'**
  String get jobsMatchLoading;

  /// No description provided for @jobsAskCoach.
  ///
  /// In en, this message translates to:
  /// **'Ask coach'**
  String get jobsAskCoach;

  /// No description provided for @jobsApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get jobsApply;

  /// No description provided for @jobsApplyConfirm.
  ///
  /// In en, this message translates to:
  /// **'Application submitted. Good luck!'**
  String get jobsApplyConfirm;

  /// No description provided for @jobsCoachSeed.
  ///
  /// In en, this message translates to:
  /// **'I\'m interested in the {title} role at {company}. How well does it fit my background, and how should I prepare?'**
  String jobsCoachSeed(String title, String company);

  /// No description provided for @jobsViewApplication.
  ///
  /// In en, this message translates to:
  /// **'View application'**
  String get jobsViewApplication;

  /// No description provided for @jobsMyApplications.
  ///
  /// In en, this message translates to:
  /// **'My applications'**
  String get jobsMyApplications;

  /// No description provided for @homeMyApplications.
  ///
  /// In en, this message translates to:
  /// **'My Applications'**
  String get homeMyApplications;

  /// No description provided for @homeMyApplicationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track your applications, status, and stats'**
  String get homeMyApplicationsSubtitle;

  /// No description provided for @appsTitle.
  ///
  /// In en, this message translates to:
  /// **'Applications'**
  String get appsTitle;

  /// No description provided for @appsTabApplications.
  ///
  /// In en, this message translates to:
  /// **'Applications'**
  String get appsTabApplications;

  /// No description provided for @appsTabSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get appsTabSaved;

  /// No description provided for @appsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search applications'**
  String get appsSearchHint;

  /// No description provided for @appsEmpty.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t applied to any jobs yet.'**
  String get appsEmpty;

  /// No description provided for @appsBrowseJobs.
  ///
  /// In en, this message translates to:
  /// **'Browse jobs'**
  String get appsBrowseJobs;

  /// No description provided for @appsNoResults.
  ///
  /// In en, this message translates to:
  /// **'No applications match your filters.'**
  String get appsNoResults;

  /// No description provided for @appsFilterByStatus.
  ///
  /// In en, this message translates to:
  /// **'Filter by status'**
  String get appsFilterByStatus;

  /// No description provided for @appsAppliedOn.
  ///
  /// In en, this message translates to:
  /// **'Applied {date}'**
  String appsAppliedOn(String date);

  /// No description provided for @appsDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Application'**
  String get appsDetailTitle;

  /// No description provided for @appsNotFound.
  ///
  /// In en, this message translates to:
  /// **'This application no longer exists.'**
  String get appsNotFound;

  /// No description provided for @appsUpdateStatus.
  ///
  /// In en, this message translates to:
  /// **'Update status'**
  String get appsUpdateStatus;

  /// No description provided for @appsHistory.
  ///
  /// In en, this message translates to:
  /// **'Status history'**
  String get appsHistory;

  /// No description provided for @appsViewJob.
  ///
  /// In en, this message translates to:
  /// **'View job'**
  String get appsViewJob;

  /// No description provided for @appsWithdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get appsWithdraw;

  /// No description provided for @appsWithdrawConfirm.
  ///
  /// In en, this message translates to:
  /// **'Withdraw this application? This can\'t be undone.'**
  String get appsWithdrawConfirm;

  /// No description provided for @appsPrepareInterview.
  ///
  /// In en, this message translates to:
  /// **'Prepare for your interview'**
  String get appsPrepareInterview;

  /// No description provided for @appsInterviewCoachSeed.
  ///
  /// In en, this message translates to:
  /// **'I have an interview for the {title} role at {company}. Help me prepare — likely questions and how to stand out.'**
  String appsInterviewCoachSeed(String title, String company);

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @statusReviewed.
  ///
  /// In en, this message translates to:
  /// **'Reviewed'**
  String get statusReviewed;

  /// No description provided for @statusInterview.
  ///
  /// In en, this message translates to:
  /// **'Interview'**
  String get statusInterview;

  /// No description provided for @statusAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get statusAccepted;

  /// No description provided for @statusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get statusRejected;

  /// No description provided for @statApplied.
  ///
  /// In en, this message translates to:
  /// **'Applied'**
  String get statApplied;

  /// No description provided for @statSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get statSaved;

  /// No description provided for @statInterviews.
  ///
  /// In en, this message translates to:
  /// **'Interviews'**
  String get statInterviews;

  /// No description provided for @statOffers.
  ///
  /// In en, this message translates to:
  /// **'Offers'**
  String get statOffers;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
