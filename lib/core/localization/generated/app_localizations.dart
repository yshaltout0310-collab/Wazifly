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

  /// No description provided for @interviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Interview Prep'**
  String get interviewTitle;

  /// No description provided for @interviewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Practice with AI and get scored feedback'**
  String get interviewSubtitle;

  /// No description provided for @interviewChooseType.
  ///
  /// In en, this message translates to:
  /// **'Choose an interview type'**
  String get interviewChooseType;

  /// No description provided for @interviewTypeHr.
  ///
  /// In en, this message translates to:
  /// **'HR'**
  String get interviewTypeHr;

  /// No description provided for @interviewTypeHrDesc.
  ///
  /// In en, this message translates to:
  /// **'Motivation, fit, and career goals'**
  String get interviewTypeHrDesc;

  /// No description provided for @interviewTypeTechnical.
  ///
  /// In en, this message translates to:
  /// **'Technical'**
  String get interviewTypeTechnical;

  /// No description provided for @interviewTypeTechnicalDesc.
  ///
  /// In en, this message translates to:
  /// **'Role-specific skills and problem-solving'**
  String get interviewTypeTechnicalDesc;

  /// No description provided for @interviewTypeBehavioral.
  ///
  /// In en, this message translates to:
  /// **'Behavioral'**
  String get interviewTypeBehavioral;

  /// No description provided for @interviewTypeBehavioralDesc.
  ///
  /// In en, this message translates to:
  /// **'Real situations, STAR method'**
  String get interviewTypeBehavioralDesc;

  /// No description provided for @interviewRoleLabel.
  ///
  /// In en, this message translates to:
  /// **'Target role'**
  String get interviewRoleLabel;

  /// No description provided for @interviewNoRole.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get interviewNoRole;

  /// No description provided for @interviewPersonalized.
  ///
  /// In en, this message translates to:
  /// **'Personalized from your profile, resume, and CV'**
  String get interviewPersonalized;

  /// No description provided for @interviewGenericHint.
  ///
  /// In en, this message translates to:
  /// **'Add a resume or CV for more tailored questions'**
  String get interviewGenericHint;

  /// No description provided for @interviewForJob.
  ///
  /// In en, this message translates to:
  /// **'Tailored to this job'**
  String get interviewForJob;

  /// No description provided for @interviewStart.
  ///
  /// In en, this message translates to:
  /// **'Start interview'**
  String get interviewStart;

  /// No description provided for @interviewGenerating.
  ///
  /// In en, this message translates to:
  /// **'Preparing your questions…'**
  String get interviewGenerating;

  /// No description provided for @interviewQuestionOf.
  ///
  /// In en, this message translates to:
  /// **'Question {current} of {total}'**
  String interviewQuestionOf(int current, int total);

  /// No description provided for @interviewFocusLabel.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get interviewFocusLabel;

  /// No description provided for @interviewYourAnswer.
  ///
  /// In en, this message translates to:
  /// **'Your answer'**
  String get interviewYourAnswer;

  /// No description provided for @interviewAnswerHint.
  ///
  /// In en, this message translates to:
  /// **'Type your answer as you would say it…'**
  String get interviewAnswerHint;

  /// No description provided for @interviewSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit answer'**
  String get interviewSubmit;

  /// No description provided for @interviewEvaluating.
  ///
  /// In en, this message translates to:
  /// **'Evaluating your answer…'**
  String get interviewEvaluating;

  /// No description provided for @interviewNext.
  ///
  /// In en, this message translates to:
  /// **'Next question'**
  String get interviewNext;

  /// No description provided for @interviewFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish & get results'**
  String get interviewFinish;

  /// No description provided for @interviewFeedbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get interviewFeedbackTitle;

  /// No description provided for @interviewSampleAnswer.
  ///
  /// In en, this message translates to:
  /// **'Sample strong answer'**
  String get interviewSampleAnswer;

  /// No description provided for @interviewStrengthsLabel.
  ///
  /// In en, this message translates to:
  /// **'Strengths'**
  String get interviewStrengthsLabel;

  /// No description provided for @interviewImprovementsLabel.
  ///
  /// In en, this message translates to:
  /// **'To improve'**
  String get interviewImprovementsLabel;

  /// No description provided for @interviewScoreOverall.
  ///
  /// In en, this message translates to:
  /// **'Overall'**
  String get interviewScoreOverall;

  /// No description provided for @interviewScoreCommunication.
  ///
  /// In en, this message translates to:
  /// **'Communication'**
  String get interviewScoreCommunication;

  /// No description provided for @interviewScoreTechnical.
  ///
  /// In en, this message translates to:
  /// **'Technical accuracy'**
  String get interviewScoreTechnical;

  /// No description provided for @interviewScoreConfidence.
  ///
  /// In en, this message translates to:
  /// **'Confidence'**
  String get interviewScoreConfidence;

  /// No description provided for @interviewScoreClarity.
  ///
  /// In en, this message translates to:
  /// **'Clarity'**
  String get interviewScoreClarity;

  /// No description provided for @interviewSummarizing.
  ///
  /// In en, this message translates to:
  /// **'Preparing your debrief…'**
  String get interviewSummarizing;

  /// No description provided for @interviewSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Your interview results'**
  String get interviewSummaryTitle;

  /// No description provided for @interviewOverallFeedback.
  ///
  /// In en, this message translates to:
  /// **'Overall feedback'**
  String get interviewOverallFeedback;

  /// No description provided for @interviewKeyStrengths.
  ///
  /// In en, this message translates to:
  /// **'Key strengths'**
  String get interviewKeyStrengths;

  /// No description provided for @interviewImprovementSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Improvement suggestions'**
  String get interviewImprovementSuggestions;

  /// No description provided for @interviewImprovementPlan.
  ///
  /// In en, this message translates to:
  /// **'Your improvement plan'**
  String get interviewImprovementPlan;

  /// No description provided for @interviewDiscussCoach.
  ///
  /// In en, this message translates to:
  /// **'Discuss with the coach'**
  String get interviewDiscussCoach;

  /// No description provided for @interviewPracticeAgain.
  ///
  /// In en, this message translates to:
  /// **'Practice again'**
  String get interviewPracticeAgain;

  /// No description provided for @interviewCoachSeed.
  ///
  /// In en, this message translates to:
  /// **'I just practiced a {type} interview for {role}. Help me improve my answers and confidence.'**
  String interviewCoachSeed(String type, String role);

  /// No description provided for @interviewHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Interview history'**
  String get interviewHistoryTitle;

  /// No description provided for @interviewHistoryAction.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get interviewHistoryAction;

  /// No description provided for @interviewHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No practice interviews yet. Start one to see it here.'**
  String get interviewHistoryEmpty;

  /// No description provided for @interviewQuestionsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 question} other{{count} questions}}'**
  String interviewQuestionsCount(int count);

  /// No description provided for @interviewDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Interview'**
  String get interviewDetailTitle;

  /// No description provided for @interviewNotFound.
  ///
  /// In en, this message translates to:
  /// **'This interview no longer exists.'**
  String get interviewNotFound;

  /// No description provided for @interviewInProgressBadge.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get interviewInProgressBadge;

  /// No description provided for @interviewPracticeForJob.
  ///
  /// In en, this message translates to:
  /// **'Practice interview'**
  String get interviewPracticeForJob;

  /// No description provided for @interviewRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get interviewRetry;

  /// No description provided for @interviewErrNoQuestions.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t generate questions. Please try again.'**
  String get interviewErrNoQuestions;

  /// No description provided for @interviewErrEmptyEval.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t evaluate that answer. Try rephrasing it.'**
  String get interviewErrEmptyEval;

  /// No description provided for @interviewErrNetwork.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Check your network and try again.'**
  String get interviewErrNetwork;

  /// No description provided for @interviewErrQuota.
  ///
  /// In en, this message translates to:
  /// **'The AI service is busy right now. Please try again shortly.'**
  String get interviewErrQuota;

  /// No description provided for @interviewErrGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get interviewErrGeneric;

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

  /// No description provided for @recTitle.
  ///
  /// In en, this message translates to:
  /// **'For You'**
  String get recTitle;

  /// No description provided for @recSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Personalized recommendations based on everything you\'ve shared.'**
  String get recSubtitle;

  /// No description provided for @recLoading.
  ///
  /// In en, this message translates to:
  /// **'Personalizing your recommendations…'**
  String get recLoading;

  /// No description provided for @recRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get recRefresh;

  /// No description provided for @recRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get recRetry;

  /// No description provided for @recUpToDate.
  ///
  /// In en, this message translates to:
  /// **'You\'re all set — your recommendations are already up to date.'**
  String get recUpToDate;

  /// No description provided for @recNudge.
  ///
  /// In en, this message translates to:
  /// **'Add your skills, analyze a resume, or build a CV to unlock sharper recommendations.'**
  String get recNudge;

  /// No description provided for @recUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated {date}'**
  String recUpdated(String date);

  /// No description provided for @recConfidence.
  ///
  /// In en, this message translates to:
  /// **'{percent}% match'**
  String recConfidence(int percent);

  /// No description provided for @recViewJob.
  ///
  /// In en, this message translates to:
  /// **'View job'**
  String get recViewJob;

  /// No description provided for @recJobsTitle.
  ///
  /// In en, this message translates to:
  /// **'Recommended jobs'**
  String get recJobsTitle;

  /// No description provided for @recSkillsTitle.
  ///
  /// In en, this message translates to:
  /// **'Skills to learn'**
  String get recSkillsTitle;

  /// No description provided for @recCertsTitle.
  ///
  /// In en, this message translates to:
  /// **'Certifications'**
  String get recCertsTitle;

  /// No description provided for @recCoursesTitle.
  ///
  /// In en, this message translates to:
  /// **'Courses'**
  String get recCoursesTitle;

  /// No description provided for @recRoadmapTitle.
  ///
  /// In en, this message translates to:
  /// **'Career roadmap'**
  String get recRoadmapTitle;

  /// No description provided for @recActionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Next best actions'**
  String get recActionsTitle;

  /// No description provided for @recPriorityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get recPriorityHigh;

  /// No description provided for @recPriorityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get recPriorityMedium;

  /// No description provided for @recPriorityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get recPriorityLow;

  /// No description provided for @recHorizonThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get recHorizonThisWeek;

  /// No description provided for @recHorizonNextMonth.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get recHorizonNextMonth;

  /// No description provided for @recHorizonNext3Months.
  ///
  /// In en, this message translates to:
  /// **'Next 3 months'**
  String get recHorizonNext3Months;

  /// No description provided for @recHorizon6to12.
  ///
  /// In en, this message translates to:
  /// **'6–12 months'**
  String get recHorizon6to12;

  /// No description provided for @recActionAnalyzeResume.
  ///
  /// In en, this message translates to:
  /// **'Analyze resume'**
  String get recActionAnalyzeResume;

  /// No description provided for @recActionBuildCv.
  ///
  /// In en, this message translates to:
  /// **'Build CV'**
  String get recActionBuildCv;

  /// No description provided for @recActionPracticeInterview.
  ///
  /// In en, this message translates to:
  /// **'Practice interview'**
  String get recActionPracticeInterview;

  /// No description provided for @recActionBrowseJobs.
  ///
  /// In en, this message translates to:
  /// **'Browse jobs'**
  String get recActionBrowseJobs;

  /// No description provided for @recActionReviewApplications.
  ///
  /// In en, this message translates to:
  /// **'Review applications'**
  String get recActionReviewApplications;

  /// No description provided for @recActionCompleteProfile.
  ///
  /// In en, this message translates to:
  /// **'Complete profile'**
  String get recActionCompleteProfile;

  /// No description provided for @recActionApplyToJob.
  ///
  /// In en, this message translates to:
  /// **'Apply now'**
  String get recActionApplyToJob;

  /// No description provided for @recActionLearnSkill.
  ///
  /// In en, this message translates to:
  /// **'Start learning'**
  String get recActionLearnSkill;

  /// No description provided for @recErrGeneric.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t generate your recommendations. Please try again.'**
  String get recErrGeneric;

  /// No description provided for @recErrNetwork.
  ///
  /// In en, this message translates to:
  /// **'You appear to be offline. Check your connection and try again.'**
  String get recErrNetwork;

  /// No description provided for @recErrQuota.
  ///
  /// In en, this message translates to:
  /// **'The AI service is busy right now. Please try again in a moment.'**
  String get recErrQuota;

  /// No description provided for @recErrEmpty.
  ///
  /// In en, this message translates to:
  /// **'We don\'t have enough to recommend yet. Add more to your profile and try again.'**
  String get recErrEmpty;

  /// No description provided for @employerCompanyFallback.
  ///
  /// In en, this message translates to:
  /// **'Your company'**
  String get employerCompanyFallback;

  /// No description provided for @employerCompanyProfile.
  ///
  /// In en, this message translates to:
  /// **'Company profile'**
  String get employerCompanyProfile;

  /// No description provided for @employerCompanyProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View and edit your company details'**
  String get employerCompanyProfileSubtitle;

  /// No description provided for @employerToolsTitle.
  ///
  /// In en, this message translates to:
  /// **'Recruiting tools'**
  String get employerToolsTitle;

  /// No description provided for @employerToolsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Powerful hiring tools launching soon.'**
  String get employerToolsSubtitle;

  /// No description provided for @employerPostJob.
  ///
  /// In en, this message translates to:
  /// **'Post a Job'**
  String get employerPostJob;

  /// No description provided for @employerApplicants.
  ///
  /// In en, this message translates to:
  /// **'Applicants'**
  String get employerApplicants;

  /// No description provided for @employerInterviews.
  ///
  /// In en, this message translates to:
  /// **'Interviews'**
  String get employerInterviews;

  /// No description provided for @employerCandidates.
  ///
  /// In en, this message translates to:
  /// **'Candidates'**
  String get employerCandidates;

  /// No description provided for @employerStatActiveJobs.
  ///
  /// In en, this message translates to:
  /// **'Active jobs'**
  String get employerStatActiveJobs;

  /// No description provided for @employerStatApplications.
  ///
  /// In en, this message translates to:
  /// **'Applications'**
  String get employerStatApplications;

  /// No description provided for @employerStatInterviews.
  ///
  /// In en, this message translates to:
  /// **'Interviews'**
  String get employerStatInterviews;

  /// No description provided for @employerStatHires.
  ///
  /// In en, this message translates to:
  /// **'Hires'**
  String get employerStatHires;

  /// No description provided for @companyCompletionTitle.
  ///
  /// In en, this message translates to:
  /// **'Company profile'**
  String get companyCompletionTitle;

  /// No description provided for @companyCompletionNudge.
  ///
  /// In en, this message translates to:
  /// **'Complete your company profile to attract candidates.'**
  String get companyCompletionNudge;

  /// No description provided for @companyCompletionComplete.
  ///
  /// In en, this message translates to:
  /// **'Your company profile looks great!'**
  String get companyCompletionComplete;

  /// No description provided for @companyProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Company profile'**
  String get companyProfileTitle;

  /// No description provided for @companyEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit company'**
  String get companyEdit;

  /// No description provided for @editCompanyTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit company'**
  String get editCompanyTitle;

  /// No description provided for @companySaved.
  ///
  /// In en, this message translates to:
  /// **'Company profile saved'**
  String get companySaved;

  /// No description provided for @companyNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Company name'**
  String get companyNameLabel;

  /// No description provided for @companyNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Acme Corporation'**
  String get companyNameHint;

  /// No description provided for @companyLogoLabel.
  ///
  /// In en, this message translates to:
  /// **'Company logo'**
  String get companyLogoLabel;

  /// No description provided for @companyChangeLogo.
  ///
  /// In en, this message translates to:
  /// **'Add logo'**
  String get companyChangeLogo;

  /// No description provided for @companyIndustryLabel.
  ///
  /// In en, this message translates to:
  /// **'Industry'**
  String get companyIndustryLabel;

  /// No description provided for @companySizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Company size'**
  String get companySizeLabel;

  /// No description provided for @companyWebsiteLabel.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get companyWebsiteLabel;

  /// No description provided for @companyWebsiteHint.
  ///
  /// In en, this message translates to:
  /// **'https://example.com'**
  String get companyWebsiteHint;

  /// No description provided for @companyHqLabel.
  ///
  /// In en, this message translates to:
  /// **'Headquarters'**
  String get companyHqLabel;

  /// No description provided for @companyHqHint.
  ///
  /// In en, this message translates to:
  /// **'City, Country'**
  String get companyHqHint;

  /// No description provided for @companyDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get companyDescriptionLabel;

  /// No description provided for @companyDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'What your company does'**
  String get companyDescriptionHint;

  /// No description provided for @companyContactLabel.
  ///
  /// In en, this message translates to:
  /// **'Contact information'**
  String get companyContactLabel;

  /// No description provided for @companyContactEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Contact email'**
  String get companyContactEmailLabel;

  /// No description provided for @companyContactPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Contact phone'**
  String get companyContactPhoneLabel;

  /// No description provided for @companyLinksLabel.
  ///
  /// In en, this message translates to:
  /// **'Social links'**
  String get companyLinksLabel;

  /// No description provided for @companyLinkedinLabel.
  ///
  /// In en, this message translates to:
  /// **'LinkedIn'**
  String get companyLinkedinLabel;

  /// No description provided for @companyXLabel.
  ///
  /// In en, this message translates to:
  /// **'X (Twitter)'**
  String get companyXLabel;

  /// No description provided for @companyFacebookLabel.
  ///
  /// In en, this message translates to:
  /// **'Facebook'**
  String get companyFacebookLabel;

  /// No description provided for @companyErrNotSignedIn.
  ///
  /// In en, this message translates to:
  /// **'You need to be signed in to manage your company.'**
  String get companyErrNotSignedIn;

  /// No description provided for @companyErrGeneric.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t save your company. Please try again.'**
  String get companyErrGeneric;

  /// No description provided for @companyLogoUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t upload your logo. Please try again.'**
  String get companyLogoUploadFailed;

  /// No description provided for @industryTechnology.
  ///
  /// In en, this message translates to:
  /// **'Technology'**
  String get industryTechnology;

  /// No description provided for @industryFinance.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get industryFinance;

  /// No description provided for @industryHealthcare.
  ///
  /// In en, this message translates to:
  /// **'Healthcare'**
  String get industryHealthcare;

  /// No description provided for @industryEducation.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get industryEducation;

  /// No description provided for @industryRetail.
  ///
  /// In en, this message translates to:
  /// **'Retail'**
  String get industryRetail;

  /// No description provided for @industryManufacturing.
  ///
  /// In en, this message translates to:
  /// **'Manufacturing'**
  String get industryManufacturing;

  /// No description provided for @industryConstruction.
  ///
  /// In en, this message translates to:
  /// **'Construction'**
  String get industryConstruction;

  /// No description provided for @industryHospitality.
  ///
  /// In en, this message translates to:
  /// **'Hospitality'**
  String get industryHospitality;

  /// No description provided for @industryMedia.
  ///
  /// In en, this message translates to:
  /// **'Media'**
  String get industryMedia;

  /// No description provided for @industryEnergy.
  ///
  /// In en, this message translates to:
  /// **'Energy'**
  String get industryEnergy;

  /// No description provided for @industryTransportation.
  ///
  /// In en, this message translates to:
  /// **'Transportation'**
  String get industryTransportation;

  /// No description provided for @industryGovernment.
  ///
  /// In en, this message translates to:
  /// **'Government'**
  String get industryGovernment;

  /// No description provided for @industryNonprofit.
  ///
  /// In en, this message translates to:
  /// **'Non-profit'**
  String get industryNonprofit;

  /// No description provided for @industryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get industryOther;

  /// No description provided for @companySize1to10.
  ///
  /// In en, this message translates to:
  /// **'1–10 employees'**
  String get companySize1to10;

  /// No description provided for @companySize11to50.
  ///
  /// In en, this message translates to:
  /// **'11–50 employees'**
  String get companySize11to50;

  /// No description provided for @companySize51to200.
  ///
  /// In en, this message translates to:
  /// **'51–200 employees'**
  String get companySize51to200;

  /// No description provided for @companySize201to500.
  ///
  /// In en, this message translates to:
  /// **'201–500 employees'**
  String get companySize201to500;

  /// No description provided for @companySize501to1000.
  ///
  /// In en, this message translates to:
  /// **'501–1000 employees'**
  String get companySize501to1000;

  /// No description provided for @companySize1000plus.
  ///
  /// In en, this message translates to:
  /// **'1000+ employees'**
  String get companySize1000plus;

  /// No description provided for @employerManageJobs.
  ///
  /// In en, this message translates to:
  /// **'Manage jobs'**
  String get employerManageJobs;

  /// No description provided for @employerManageJobsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create and manage your job postings'**
  String get employerManageJobsSubtitle;

  /// No description provided for @jobStatusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get jobStatusDraft;

  /// No description provided for @jobStatusPublished.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get jobStatusPublished;

  /// No description provided for @jobStatusArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get jobStatusArchived;

  /// No description provided for @jobStatusClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get jobStatusClosed;

  /// No description provided for @empTypeFullTime.
  ///
  /// In en, this message translates to:
  /// **'Full-time'**
  String get empTypeFullTime;

  /// No description provided for @empTypePartTime.
  ///
  /// In en, this message translates to:
  /// **'Part-time'**
  String get empTypePartTime;

  /// No description provided for @empTypeContract.
  ///
  /// In en, this message translates to:
  /// **'Contract'**
  String get empTypeContract;

  /// No description provided for @empTypeInternship.
  ///
  /// In en, this message translates to:
  /// **'Internship'**
  String get empTypeInternship;

  /// No description provided for @empTypeTemporary.
  ///
  /// In en, this message translates to:
  /// **'Temporary'**
  String get empTypeTemporary;

  /// No description provided for @jobExpEntry.
  ///
  /// In en, this message translates to:
  /// **'Entry'**
  String get jobExpEntry;

  /// No description provided for @jobExpJunior.
  ///
  /// In en, this message translates to:
  /// **'Junior'**
  String get jobExpJunior;

  /// No description provided for @jobExpMid.
  ///
  /// In en, this message translates to:
  /// **'Mid'**
  String get jobExpMid;

  /// No description provided for @jobExpSenior.
  ///
  /// In en, this message translates to:
  /// **'Senior'**
  String get jobExpSenior;

  /// No description provided for @jobExpLead.
  ///
  /// In en, this message translates to:
  /// **'Lead'**
  String get jobExpLead;

  /// No description provided for @salaryYearly.
  ///
  /// In en, this message translates to:
  /// **'per year'**
  String get salaryYearly;

  /// No description provided for @salaryMonthly.
  ///
  /// In en, this message translates to:
  /// **'per month'**
  String get salaryMonthly;

  /// No description provided for @salaryHourly.
  ///
  /// In en, this message translates to:
  /// **'per hour'**
  String get salaryHourly;

  /// No description provided for @employerJobsTitle.
  ///
  /// In en, this message translates to:
  /// **'My jobs'**
  String get employerJobsTitle;

  /// No description provided for @employerJobsEmpty.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t posted any jobs yet.'**
  String get employerJobsEmpty;

  /// No description provided for @employerJobsEmptyCta.
  ///
  /// In en, this message translates to:
  /// **'Post your first job'**
  String get employerJobsEmptyCta;

  /// No description provided for @employerJobsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search your jobs'**
  String get employerJobsSearchHint;

  /// No description provided for @employerJobsNoResults.
  ///
  /// In en, this message translates to:
  /// **'No jobs match your filters.'**
  String get employerJobsNoResults;

  /// No description provided for @employerJobsFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get employerJobsFilterAll;

  /// No description provided for @employerJobsSort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get employerJobsSort;

  /// No description provided for @jobSortUpdated.
  ///
  /// In en, this message translates to:
  /// **'Recently updated'**
  String get jobSortUpdated;

  /// No description provided for @jobSortCreated.
  ///
  /// In en, this message translates to:
  /// **'Recently created'**
  String get jobSortCreated;

  /// No description provided for @jobSortTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get jobSortTitle;

  /// No description provided for @jobSortStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get jobSortStatus;

  /// No description provided for @createJobTitle.
  ///
  /// In en, this message translates to:
  /// **'Post a job'**
  String get createJobTitle;

  /// No description provided for @editJobTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit job'**
  String get editJobTitle;

  /// No description provided for @jobTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Job title'**
  String get jobTitleLabel;

  /// No description provided for @jobTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Senior Flutter Engineer'**
  String get jobTitleHint;

  /// No description provided for @jobDescLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get jobDescLabel;

  /// No description provided for @jobDescHint.
  ///
  /// In en, this message translates to:
  /// **'Describe the role, responsibilities, and requirements'**
  String get jobDescHint;

  /// No description provided for @jobSkillsLabel.
  ///
  /// In en, this message translates to:
  /// **'Required skills'**
  String get jobSkillsLabel;

  /// No description provided for @jobSkillsHint.
  ///
  /// In en, this message translates to:
  /// **'Add a skill'**
  String get jobSkillsHint;

  /// No description provided for @jobExperienceLabel.
  ///
  /// In en, this message translates to:
  /// **'Experience level'**
  String get jobExperienceLabel;

  /// No description provided for @jobEmploymentTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Employment type'**
  String get jobEmploymentTypeLabel;

  /// No description provided for @jobLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get jobLocationLabel;

  /// No description provided for @jobLocationHint.
  ///
  /// In en, this message translates to:
  /// **'City, Country'**
  String get jobLocationHint;

  /// No description provided for @jobRemoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Remote'**
  String get jobRemoteLabel;

  /// No description provided for @jobOpeningsLabel.
  ///
  /// In en, this message translates to:
  /// **'Open positions'**
  String get jobOpeningsLabel;

  /// No description provided for @jobOpeningsHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 3'**
  String get jobOpeningsHint;

  /// No description provided for @jobSalaryLabel.
  ///
  /// In en, this message translates to:
  /// **'Salary (optional)'**
  String get jobSalaryLabel;

  /// No description provided for @jobSalaryMin.
  ///
  /// In en, this message translates to:
  /// **'Min'**
  String get jobSalaryMin;

  /// No description provided for @jobSalaryMax.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get jobSalaryMax;

  /// No description provided for @jobSalaryCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get jobSalaryCurrency;

  /// No description provided for @jobSalaryPeriod.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get jobSalaryPeriod;

  /// No description provided for @jobAvailabilityLabel.
  ///
  /// In en, this message translates to:
  /// **'Availability (optional)'**
  String get jobAvailabilityLabel;

  /// No description provided for @jobOpensAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Opening date'**
  String get jobOpensAtLabel;

  /// No description provided for @jobExpiresAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Expiration date'**
  String get jobExpiresAtLabel;

  /// No description provided for @jobDateNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get jobDateNotSet;

  /// No description provided for @jobClearDate.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get jobClearDate;

  /// No description provided for @jobSaveDraft.
  ///
  /// In en, this message translates to:
  /// **'Save draft'**
  String get jobSaveDraft;

  /// No description provided for @jobPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get jobPreview;

  /// No description provided for @jobPublish.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get jobPublish;

  /// No description provided for @jobDraftSaved.
  ///
  /// In en, this message translates to:
  /// **'Draft saved'**
  String get jobDraftSaved;

  /// No description provided for @jobAutosaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get jobAutosaving;

  /// No description provided for @jobAutosaved.
  ///
  /// In en, this message translates to:
  /// **'Saved {time}'**
  String jobAutosaved(String time);

  /// No description provided for @jobErrRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get jobErrRequired;

  /// No description provided for @jobErrTitleShort.
  ///
  /// In en, this message translates to:
  /// **'At least 3 characters'**
  String get jobErrTitleShort;

  /// No description provided for @jobErrDescShort.
  ///
  /// In en, this message translates to:
  /// **'At least 30 characters'**
  String get jobErrDescShort;

  /// No description provided for @jobErrAddSkill.
  ///
  /// In en, this message translates to:
  /// **'Add at least one skill'**
  String get jobErrAddSkill;

  /// No description provided for @jobErrChooseExperience.
  ///
  /// In en, this message translates to:
  /// **'Choose an experience level'**
  String get jobErrChooseExperience;

  /// No description provided for @jobErrChooseType.
  ///
  /// In en, this message translates to:
  /// **'Choose an employment type'**
  String get jobErrChooseType;

  /// No description provided for @jobErrInvalidSalary.
  ///
  /// In en, this message translates to:
  /// **'Minimum must be ≤ maximum'**
  String get jobErrInvalidSalary;

  /// No description provided for @jobErrInvalidOpenings.
  ///
  /// In en, this message translates to:
  /// **'Must be at least 1'**
  String get jobErrInvalidOpenings;

  /// No description provided for @jobErrInvalidDates.
  ///
  /// In en, this message translates to:
  /// **'Expiration must be after the opening date'**
  String get jobErrInvalidDates;

  /// No description provided for @jobErrFixFields.
  ///
  /// In en, this message translates to:
  /// **'Please fix the highlighted fields.'**
  String get jobErrFixFields;

  /// No description provided for @jobUnsavedTitle.
  ///
  /// In en, this message translates to:
  /// **'Unsaved changes'**
  String get jobUnsavedTitle;

  /// No description provided for @jobUnsavedBody.
  ///
  /// In en, this message translates to:
  /// **'Save this job as a draft before leaving?'**
  String get jobUnsavedBody;

  /// No description provided for @jobUnsavedSave.
  ///
  /// In en, this message translates to:
  /// **'Save draft'**
  String get jobUnsavedSave;

  /// No description provided for @jobUnsavedDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get jobUnsavedDiscard;

  /// No description provided for @jobUnsavedCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get jobUnsavedCancel;

  /// No description provided for @jobPreviewBanner.
  ///
  /// In en, this message translates to:
  /// **'Preview — how job seekers see this job'**
  String get jobPreviewBanner;

  /// No description provided for @jobPublishConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Publish this job?'**
  String get jobPublishConfirmTitle;

  /// No description provided for @jobPublishConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'It will be visible to job seekers.'**
  String get jobPublishConfirmBody;

  /// No description provided for @jobPublishConfirmCta.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get jobPublishConfirmCta;

  /// No description provided for @jobPublished.
  ///
  /// In en, this message translates to:
  /// **'Job published'**
  String get jobPublished;

  /// No description provided for @jobActionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get jobActionEdit;

  /// No description provided for @jobActionDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get jobActionDuplicate;

  /// No description provided for @jobActionPublish.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get jobActionPublish;

  /// No description provided for @jobActionArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get jobActionArchive;

  /// No description provided for @jobActionClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get jobActionClose;

  /// No description provided for @jobActionReopen.
  ///
  /// In en, this message translates to:
  /// **'Reopen'**
  String get jobActionReopen;

  /// No description provided for @jobActionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get jobActionDelete;

  /// No description provided for @jobActionPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get jobActionPreview;

  /// No description provided for @jobDuplicated.
  ///
  /// In en, this message translates to:
  /// **'Job duplicated'**
  String get jobDuplicated;

  /// No description provided for @jobArchivedMsg.
  ///
  /// In en, this message translates to:
  /// **'Job archived'**
  String get jobArchivedMsg;

  /// No description provided for @jobClosedMsg.
  ///
  /// In en, this message translates to:
  /// **'Job closed'**
  String get jobClosedMsg;

  /// No description provided for @jobReopenedMsg.
  ///
  /// In en, this message translates to:
  /// **'Job reopened'**
  String get jobReopenedMsg;

  /// No description provided for @jobDeletedMsg.
  ///
  /// In en, this message translates to:
  /// **'Job deleted'**
  String get jobDeletedMsg;

  /// No description provided for @jobDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this job?'**
  String get jobDeleteConfirmTitle;

  /// No description provided for @jobDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'It\'s removed from your list, but existing applications and history are kept.'**
  String get jobDeleteConfirmBody;

  /// No description provided for @jobArchiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Archive job'**
  String get jobArchiveTitle;

  /// No description provided for @jobArchiveReasonHint.
  ///
  /// In en, this message translates to:
  /// **'Reason (optional)'**
  String get jobArchiveReasonHint;

  /// No description provided for @jobErrPermission.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to do that.'**
  String get jobErrPermission;

  /// No description provided for @jobErrNetwork.
  ///
  /// In en, this message translates to:
  /// **'You appear to be offline. Please try again.'**
  String get jobErrNetwork;

  /// No description provided for @jobActionFailed.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get jobActionFailed;

  /// No description provided for @jobMetricsViews.
  ///
  /// In en, this message translates to:
  /// **'Views'**
  String get jobMetricsViews;

  /// No description provided for @jobMetricsApplications.
  ///
  /// In en, this message translates to:
  /// **'Applications'**
  String get jobMetricsApplications;

  /// No description provided for @jobOpeningsValue.
  ///
  /// In en, this message translates to:
  /// **'{count} open positions'**
  String jobOpeningsValue(int count);

  /// No description provided for @jobPublishedOn.
  ///
  /// In en, this message translates to:
  /// **'Published {date}'**
  String jobPublishedOn(String date);

  /// No description provided for @jobUpdatedOn.
  ///
  /// In en, this message translates to:
  /// **'Updated {date}'**
  String jobUpdatedOn(String date);

  /// No description provided for @jobArchiveReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Archive reason'**
  String get jobArchiveReasonLabel;

  /// No description provided for @jobDetailApplicantsSoon.
  ///
  /// In en, this message translates to:
  /// **'Applicants — coming soon'**
  String get jobDetailApplicantsSoon;

  /// No description provided for @employerApplicantsTitle.
  ///
  /// In en, this message translates to:
  /// **'Applicants'**
  String get employerApplicantsTitle;

  /// No description provided for @employerApplicantsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review and manage applicants'**
  String get employerApplicantsSubtitle;

  /// No description provided for @employerApplicantsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search applicants'**
  String get employerApplicantsSearchHint;

  /// No description provided for @employerApplicantsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No applicants yet.'**
  String get employerApplicantsEmpty;

  /// No description provided for @employerApplicantsEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Applicants appear here as job seekers apply to your published jobs.'**
  String get employerApplicantsEmptyHint;

  /// No description provided for @employerApplicantsNoResults.
  ///
  /// In en, this message translates to:
  /// **'No applicants match your filters.'**
  String get employerApplicantsNoResults;

  /// No description provided for @employerApplicantsFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get employerApplicantsFilterAll;

  /// No description provided for @applicantsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No applicants yet} =1{1 applicant} other{{count} applicants}}'**
  String applicantsCount(int count);

  /// No description provided for @applicantsStatTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get applicantsStatTotal;

  /// No description provided for @applicantsStatNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get applicantsStatNew;

  /// No description provided for @applicantSortRecent.
  ///
  /// In en, this message translates to:
  /// **'Most recent'**
  String get applicantSortRecent;

  /// No description provided for @applicantSortMatch.
  ///
  /// In en, this message translates to:
  /// **'Match score'**
  String get applicantSortMatch;

  /// No description provided for @applicantSortName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get applicantSortName;

  /// No description provided for @applicantSortStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get applicantSortStatus;

  /// No description provided for @applicantActionReview.
  ///
  /// In en, this message translates to:
  /// **'Move to Review'**
  String get applicantActionReview;

  /// No description provided for @applicantActionInterview.
  ///
  /// In en, this message translates to:
  /// **'Move to Interview'**
  String get applicantActionInterview;

  /// No description provided for @applicantActionAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get applicantActionAccept;

  /// No description provided for @applicantActionReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get applicantActionReject;

  /// No description provided for @applicantActionReopen.
  ///
  /// In en, this message translates to:
  /// **'Reopen'**
  String get applicantActionReopen;

  /// No description provided for @applicantAcceptTitle.
  ///
  /// In en, this message translates to:
  /// **'Accept this applicant?'**
  String get applicantAcceptTitle;

  /// No description provided for @applicantAcceptBody.
  ///
  /// In en, this message translates to:
  /// **'They\'ll be moved to Accepted.'**
  String get applicantAcceptBody;

  /// No description provided for @applicantRejectTitle.
  ///
  /// In en, this message translates to:
  /// **'Reject applicant'**
  String get applicantRejectTitle;

  /// No description provided for @applicantRejectReasonHint.
  ///
  /// In en, this message translates to:
  /// **'Reason (optional, private)'**
  String get applicantRejectReasonHint;

  /// No description provided for @applicantReopenTitle.
  ///
  /// In en, this message translates to:
  /// **'Reopen applicant?'**
  String get applicantReopenTitle;

  /// No description provided for @applicantReopenBody.
  ///
  /// In en, this message translates to:
  /// **'They\'ll be moved back to Review.'**
  String get applicantReopenBody;

  /// No description provided for @applicantMovedReview.
  ///
  /// In en, this message translates to:
  /// **'Moved to Review'**
  String get applicantMovedReview;

  /// No description provided for @applicantMovedInterview.
  ///
  /// In en, this message translates to:
  /// **'Moved to Interview'**
  String get applicantMovedInterview;

  /// No description provided for @applicantAccepted.
  ///
  /// In en, this message translates to:
  /// **'Applicant accepted'**
  String get applicantAccepted;

  /// No description provided for @applicantRejected.
  ///
  /// In en, this message translates to:
  /// **'Applicant rejected'**
  String get applicantRejected;

  /// No description provided for @applicantReopened.
  ///
  /// In en, this message translates to:
  /// **'Applicant reopened'**
  String get applicantReopened;

  /// No description provided for @applicantSectionMatch.
  ///
  /// In en, this message translates to:
  /// **'AI match'**
  String get applicantSectionMatch;

  /// No description provided for @applicantSectionResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get applicantSectionResume;

  /// No description provided for @applicantSectionResumeAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Resume analysis'**
  String get applicantSectionResumeAnalysis;

  /// No description provided for @applicantSectionTimeline.
  ///
  /// In en, this message translates to:
  /// **'Application timeline'**
  String get applicantSectionTimeline;

  /// No description provided for @applicantSectionInterview.
  ///
  /// In en, this message translates to:
  /// **'Interview readiness'**
  String get applicantSectionInterview;

  /// No description provided for @applicantSectionNotes.
  ///
  /// In en, this message translates to:
  /// **'Private notes'**
  String get applicantSectionNotes;

  /// No description provided for @applicantSectionSkills.
  ///
  /// In en, this message translates to:
  /// **'Skills'**
  String get applicantSectionSkills;

  /// No description provided for @applicantSectionLinks.
  ///
  /// In en, this message translates to:
  /// **'Links'**
  String get applicantSectionLinks;

  /// No description provided for @applicantMatchPercent.
  ///
  /// In en, this message translates to:
  /// **'{score}% match'**
  String applicantMatchPercent(int score);

  /// No description provided for @applicantMatchMatching.
  ///
  /// In en, this message translates to:
  /// **'Matching skills'**
  String get applicantMatchMatching;

  /// No description provided for @applicantMatchMissing.
  ///
  /// In en, this message translates to:
  /// **'Missing skills'**
  String get applicantMatchMissing;

  /// No description provided for @applicantNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No match score captured yet.'**
  String get applicantNoMatch;

  /// No description provided for @applicantAtsScore.
  ///
  /// In en, this message translates to:
  /// **'ATS score'**
  String get applicantAtsScore;

  /// No description provided for @applicantNoResumeAnalysis.
  ///
  /// In en, this message translates to:
  /// **'No resume analysis captured yet.'**
  String get applicantNoResumeAnalysis;

  /// No description provided for @applicantResumeView.
  ///
  /// In en, this message translates to:
  /// **'View resume'**
  String get applicantResumeView;

  /// No description provided for @applicantResumeDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get applicantResumeDownload;

  /// No description provided for @applicantResumeUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Resume file not available.'**
  String get applicantResumeUnavailable;

  /// No description provided for @applicantInterviewSessions.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No interview practice yet} =1{1 practice session} other{{count} practice sessions}}'**
  String applicantInterviewSessions(int count);

  /// No description provided for @applicantInterviewBest.
  ///
  /// In en, this message translates to:
  /// **'Best score {score}'**
  String applicantInterviewBest(int score);

  /// No description provided for @applicantNoProfile.
  ///
  /// In en, this message translates to:
  /// **'This applicant hasn\'t shared profile details.'**
  String get applicantNoProfile;

  /// No description provided for @applicantAppliedOn.
  ///
  /// In en, this message translates to:
  /// **'Applied {date}'**
  String applicantAppliedOn(String date);

  /// No description provided for @applicantVia.
  ///
  /// In en, this message translates to:
  /// **'via {source}'**
  String applicantVia(String source);

  /// No description provided for @sourceCareerBridge.
  ///
  /// In en, this message translates to:
  /// **'CareerBridge'**
  String get sourceCareerBridge;

  /// No description provided for @sourceReferral.
  ///
  /// In en, this message translates to:
  /// **'Referral'**
  String get sourceReferral;

  /// No description provided for @sourceExternalImport.
  ///
  /// In en, this message translates to:
  /// **'External import'**
  String get sourceExternalImport;

  /// No description provided for @sourceCompanyWebsite.
  ///
  /// In en, this message translates to:
  /// **'Company website'**
  String get sourceCompanyWebsite;

  /// No description provided for @notesPrivateHint.
  ///
  /// In en, this message translates to:
  /// **'Only you can see these notes.'**
  String get notesPrivateHint;

  /// No description provided for @notesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No notes yet.'**
  String get notesEmpty;

  /// No description provided for @noteAdd.
  ///
  /// In en, this message translates to:
  /// **'Add a note'**
  String get noteAdd;

  /// No description provided for @noteHint.
  ///
  /// In en, this message translates to:
  /// **'Write a private note…'**
  String get noteHint;

  /// No description provided for @noteSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get noteSave;

  /// No description provided for @noteEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get noteEdit;

  /// No description provided for @noteDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get noteDelete;

  /// No description provided for @noteEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit note'**
  String get noteEditTitle;

  /// No description provided for @noteDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete note?'**
  String get noteDeleteTitle;

  /// No description provided for @noteDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'This can\'t be undone.'**
  String get noteDeleteBody;

  /// No description provided for @noteEditedTag.
  ///
  /// In en, this message translates to:
  /// **'edited'**
  String get noteEditedTag;

  /// No description provided for @noteAddedMsg.
  ///
  /// In en, this message translates to:
  /// **'Note added'**
  String get noteAddedMsg;

  /// No description provided for @noteUpdatedMsg.
  ///
  /// In en, this message translates to:
  /// **'Note updated'**
  String get noteUpdatedMsg;

  /// No description provided for @noteDeletedMsg.
  ///
  /// In en, this message translates to:
  /// **'Note deleted'**
  String get noteDeletedMsg;

  /// No description provided for @employerAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics & insights'**
  String get employerAnalytics;

  /// No description provided for @employerAnalyticsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track your hiring performance'**
  String get employerAnalyticsSubtitle;

  /// No description provided for @analyticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analyticsTitle;

  /// No description provided for @analyticsRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get analyticsRefresh;

  /// No description provided for @analyticsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No analytics yet'**
  String get analyticsEmptyTitle;

  /// No description provided for @analyticsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Analytics appear once you post jobs and receive applicants.'**
  String get analyticsEmptyBody;

  /// No description provided for @analyticsPostJob.
  ///
  /// In en, this message translates to:
  /// **'Post a job'**
  String get analyticsPostJob;

  /// No description provided for @analyticsMetricsNote.
  ///
  /// In en, this message translates to:
  /// **'Metrics are based on applications received. Job view tracking is coming soon.'**
  String get analyticsMetricsNote;

  /// No description provided for @analyticsOverviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get analyticsOverviewTitle;

  /// No description provided for @analyticsKpiActiveJobs.
  ///
  /// In en, this message translates to:
  /// **'Active jobs'**
  String get analyticsKpiActiveJobs;

  /// No description provided for @analyticsKpiApplicants.
  ///
  /// In en, this message translates to:
  /// **'Applicants'**
  String get analyticsKpiApplicants;

  /// No description provided for @analyticsKpiInterviews.
  ///
  /// In en, this message translates to:
  /// **'Interviews'**
  String get analyticsKpiInterviews;

  /// No description provided for @analyticsKpiHires.
  ///
  /// In en, this message translates to:
  /// **'Hires'**
  String get analyticsKpiHires;

  /// No description provided for @analyticsKpiHireRate.
  ///
  /// In en, this message translates to:
  /// **'Hire rate'**
  String get analyticsKpiHireRate;

  /// No description provided for @analyticsKpiAvgMatch.
  ///
  /// In en, this message translates to:
  /// **'Avg. match'**
  String get analyticsKpiAvgMatch;

  /// No description provided for @analyticsFunnelTitle.
  ///
  /// In en, this message translates to:
  /// **'Application funnel'**
  String get analyticsFunnelTitle;

  /// No description provided for @analyticsFunnelApplied.
  ///
  /// In en, this message translates to:
  /// **'Applied'**
  String get analyticsFunnelApplied;

  /// No description provided for @analyticsFunnelReviewed.
  ///
  /// In en, this message translates to:
  /// **'Reviewed'**
  String get analyticsFunnelReviewed;

  /// No description provided for @analyticsFunnelInterview.
  ///
  /// In en, this message translates to:
  /// **'Interview'**
  String get analyticsFunnelInterview;

  /// No description provided for @analyticsFunnelHired.
  ///
  /// In en, this message translates to:
  /// **'Hired'**
  String get analyticsFunnelHired;

  /// No description provided for @analyticsRejectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No rejections} =1{1 rejected} other{{count} rejected}}'**
  String analyticsRejectedCount(int count);

  /// No description provided for @analyticsShareOfApplicants.
  ///
  /// In en, this message translates to:
  /// **'{percent}% of applicants'**
  String analyticsShareOfApplicants(int percent);

  /// No description provided for @analyticsTopJobsTitle.
  ///
  /// In en, this message translates to:
  /// **'Top jobs'**
  String get analyticsTopJobsTitle;

  /// No description provided for @analyticsJobApplicants.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No applicants} =1{1 applicant} other{{count} applicants}}'**
  String analyticsJobApplicants(int count);

  /// No description provided for @analyticsPercentHired.
  ///
  /// In en, this message translates to:
  /// **'{percent}% hired'**
  String analyticsPercentHired(int percent);

  /// No description provided for @analyticsNoJobData.
  ///
  /// In en, this message translates to:
  /// **'No applicants for your jobs yet.'**
  String get analyticsNoJobData;

  /// No description provided for @analyticsTimeToHireTitle.
  ///
  /// In en, this message translates to:
  /// **'Time to hire'**
  String get analyticsTimeToHireTitle;

  /// No description provided for @analyticsAvgTimeToHire.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get analyticsAvgTimeToHire;

  /// No description provided for @analyticsMedianTimeToHire.
  ///
  /// In en, this message translates to:
  /// **'Median'**
  String get analyticsMedianTimeToHire;

  /// No description provided for @analyticsFastestHire.
  ///
  /// In en, this message translates to:
  /// **'Fastest'**
  String get analyticsFastestHire;

  /// No description provided for @analyticsAvgInPipeline.
  ///
  /// In en, this message translates to:
  /// **'Avg. wait (open)'**
  String get analyticsAvgInPipeline;

  /// No description provided for @analyticsDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{—} =1{1 day} other{{count} days}}'**
  String analyticsDays(int count);

  /// No description provided for @analyticsOpenCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{None open} =1{1 open} other{{count} open}}'**
  String analyticsOpenCount(int count);

  /// No description provided for @analyticsNoHiresYet.
  ///
  /// In en, this message translates to:
  /// **'No hires yet to measure time-to-hire.'**
  String get analyticsNoHiresYet;

  /// No description provided for @analyticsQualityTitle.
  ///
  /// In en, this message translates to:
  /// **'Applicant quality'**
  String get analyticsQualityTitle;

  /// No description provided for @analyticsMatchDistribution.
  ///
  /// In en, this message translates to:
  /// **'AI match distribution'**
  String get analyticsMatchDistribution;

  /// No description provided for @analyticsBandStrong.
  ///
  /// In en, this message translates to:
  /// **'Strong (80+)'**
  String get analyticsBandStrong;

  /// No description provided for @analyticsBandGood.
  ///
  /// In en, this message translates to:
  /// **'Good (60–79)'**
  String get analyticsBandGood;

  /// No description provided for @analyticsBandFair.
  ///
  /// In en, this message translates to:
  /// **'Fair (40–59)'**
  String get analyticsBandFair;

  /// No description provided for @analyticsBandWeak.
  ///
  /// In en, this message translates to:
  /// **'Weak (<40)'**
  String get analyticsBandWeak;

  /// No description provided for @analyticsAvgAts.
  ///
  /// In en, this message translates to:
  /// **'Avg. resume ATS'**
  String get analyticsAvgAts;

  /// No description provided for @analyticsTopSkillsTitle.
  ///
  /// In en, this message translates to:
  /// **'Top applicant skills'**
  String get analyticsTopSkillsTitle;

  /// No description provided for @analyticsNoQualityData.
  ///
  /// In en, this message translates to:
  /// **'No AI match data on applicants yet.'**
  String get analyticsNoQualityData;

  /// No description provided for @analyticsTrendTitle.
  ///
  /// In en, this message translates to:
  /// **'Applications over time'**
  String get analyticsTrendTitle;

  /// No description provided for @analyticsTrendLast7.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{None in the last 7 days} =1{1 in the last 7 days} other{{count} in the last 7 days}}'**
  String analyticsTrendLast7(int count);

  /// No description provided for @analyticsNoTrendData.
  ///
  /// In en, this message translates to:
  /// **'No applications yet.'**
  String get analyticsNoTrendData;

  /// No description provided for @insightsTitle.
  ///
  /// In en, this message translates to:
  /// **'AI recruiter insights'**
  String get insightsTitle;

  /// No description provided for @insightsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Let AI analyze your hiring funnel and suggest improvements.'**
  String get insightsSubtitle;

  /// No description provided for @insightsGenerate.
  ///
  /// In en, this message translates to:
  /// **'Generate insights'**
  String get insightsGenerate;

  /// No description provided for @insightsLoading.
  ///
  /// In en, this message translates to:
  /// **'Analyzing your hiring data…'**
  String get insightsLoading;

  /// No description provided for @insightsRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get insightsRefresh;

  /// No description provided for @insightsRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get insightsRetry;

  /// No description provided for @insightsUpToDate.
  ///
  /// In en, this message translates to:
  /// **'Insights are already up to date.'**
  String get insightsUpToDate;

  /// No description provided for @insightsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Insights become available once you have applicants.'**
  String get insightsUnavailable;

  /// No description provided for @insightsStrengthsTitle.
  ///
  /// In en, this message translates to:
  /// **'What\'s working'**
  String get insightsStrengthsTitle;

  /// No description provided for @insightsBottlenecksTitle.
  ///
  /// In en, this message translates to:
  /// **'Bottlenecks'**
  String get insightsBottlenecksTitle;

  /// No description provided for @insightsActionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Suggested actions'**
  String get insightsActionsTitle;

  /// No description provided for @insightsUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated {date}'**
  String insightsUpdated(String date);

  /// No description provided for @insightsPriorityHigh.
  ///
  /// In en, this message translates to:
  /// **'High priority'**
  String get insightsPriorityHigh;

  /// No description provided for @insightsPriorityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium priority'**
  String get insightsPriorityMedium;

  /// No description provided for @insightsPriorityLow.
  ///
  /// In en, this message translates to:
  /// **'Low priority'**
  String get insightsPriorityLow;

  /// No description provided for @insightsErrNetwork.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach the AI service. Check your connection and try again.'**
  String get insightsErrNetwork;

  /// No description provided for @insightsErrQuota.
  ///
  /// In en, this message translates to:
  /// **'The AI service is busy right now. Please try again shortly.'**
  String get insightsErrQuota;

  /// No description provided for @insightsErrEmpty.
  ///
  /// In en, this message translates to:
  /// **'Not enough data yet to generate insights.'**
  String get insightsErrEmpty;

  /// No description provided for @insightsErrGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong generating insights. Please try again.'**
  String get insightsErrGeneric;

  /// No description provided for @uploadInProgress.
  ///
  /// In en, this message translates to:
  /// **'Uploading…'**
  String get uploadInProgress;

  /// No description provided for @profileRemovePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get profileRemovePhoto;

  /// No description provided for @profileRemovePhotoTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove photo?'**
  String get profileRemovePhotoTitle;

  /// No description provided for @profileRemovePhotoBody.
  ///
  /// In en, this message translates to:
  /// **'Your profile photo will be deleted.'**
  String get profileRemovePhotoBody;

  /// No description provided for @companyRemoveLogo.
  ///
  /// In en, this message translates to:
  /// **'Remove logo'**
  String get companyRemoveLogo;

  /// No description provided for @companyRemoveLogoTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove logo?'**
  String get companyRemoveLogoTitle;

  /// No description provided for @companyRemoveLogoBody.
  ///
  /// In en, this message translates to:
  /// **'Your company logo will be deleted.'**
  String get companyRemoveLogoBody;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @offlineBannerMessage.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline — showing saved data'**
  String get offlineBannerMessage;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get commonLoading;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get commonRetry;

  /// No description provided for @commonShowPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get commonShowPassword;

  /// No description provided for @commonHidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get commonHidePassword;

  /// No description provided for @errRequiresRecentLogin.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again to continue.'**
  String get errRequiresRecentLogin;

  /// No description provided for @errPhoneAlreadyInUse.
  ///
  /// In en, this message translates to:
  /// **'This phone number is already linked to another account.'**
  String get errPhoneAlreadyInUse;

  /// No description provided for @errPhoneAlreadyLinked.
  ///
  /// In en, this message translates to:
  /// **'A phone number is already linked to this account.'**
  String get errPhoneAlreadyLinked;

  /// No description provided for @otpResendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend code in {time}'**
  String otpResendIn(String time);

  /// No description provided for @securityTitle.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get securityTitle;

  /// No description provided for @securitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Biometric login and phone verification'**
  String get securitySubtitle;

  /// No description provided for @securityBiometricSection.
  ///
  /// In en, this message translates to:
  /// **'Biometric login'**
  String get securityBiometricSection;

  /// No description provided for @securityBiometricTitle.
  ///
  /// In en, this message translates to:
  /// **'Biometric login'**
  String get securityBiometricTitle;

  /// No description provided for @securityBiometricSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use Face ID or fingerprint to unlock the app'**
  String get securityBiometricSubtitle;

  /// No description provided for @securityBiometricNotEnrolled.
  ///
  /// In en, this message translates to:
  /// **'Set up a fingerprint or face unlock in your device settings to use this.'**
  String get securityBiometricNotEnrolled;

  /// No description provided for @securityBiometricUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Biometric login isn\'t available on this device.'**
  String get securityBiometricUnavailable;

  /// No description provided for @securityRemoveDevice.
  ///
  /// In en, this message translates to:
  /// **'Remove trusted device'**
  String get securityRemoveDevice;

  /// No description provided for @securityRemoveDeviceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Turn off biometric login on this device'**
  String get securityRemoveDeviceSubtitle;

  /// No description provided for @securityRemoveDeviceTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove trusted device?'**
  String get securityRemoveDeviceTitle;

  /// No description provided for @securityRemoveDeviceBody.
  ///
  /// In en, this message translates to:
  /// **'Biometric login will be turned off on this device. You can enable it again anytime.'**
  String get securityRemoveDeviceBody;

  /// No description provided for @securityDeviceRemovedSnack.
  ///
  /// In en, this message translates to:
  /// **'Trusted device removed.'**
  String get securityDeviceRemovedSnack;

  /// No description provided for @securityPhoneSection.
  ///
  /// In en, this message translates to:
  /// **'Phone verification'**
  String get securityPhoneSection;

  /// No description provided for @securityVerifyPhoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify phone number'**
  String get securityVerifyPhoneTitle;

  /// No description provided for @securityVerifyPhoneSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add a verified phone number to strengthen your account security.'**
  String get securityVerifyPhoneSubtitle;

  /// No description provided for @securityPhoneVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get securityPhoneVerified;

  /// No description provided for @securityPhoneNotVerified.
  ///
  /// In en, this message translates to:
  /// **'Add a verified phone number to your account'**
  String get securityPhoneNotVerified;

  /// No description provided for @phoneLinkedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Phone number verified and linked.'**
  String get phoneLinkedSuccess;

  /// No description provided for @biometricPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable faster sign-in?'**
  String get biometricPromptTitle;

  /// No description provided for @biometricPromptBody.
  ///
  /// In en, this message translates to:
  /// **'Use Face ID or your fingerprint to sign in next time — quicker and just as secure.'**
  String get biometricPromptBody;

  /// No description provided for @biometricEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get biometricEnable;

  /// No description provided for @biometricNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get biometricNotNow;

  /// No description provided for @biometricEnabledSnack.
  ///
  /// In en, this message translates to:
  /// **'Biometric login enabled.'**
  String get biometricEnabledSnack;

  /// No description provided for @biometricDisabledSnack.
  ///
  /// In en, this message translates to:
  /// **'Biometric login disabled.'**
  String get biometricDisabledSnack;

  /// No description provided for @biometricFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t verify. Please try again.'**
  String get biometricFailed;

  /// No description provided for @biometricReasonEnable.
  ///
  /// In en, this message translates to:
  /// **'Confirm it\'s you to enable biometric login'**
  String get biometricReasonEnable;

  /// No description provided for @biometricReasonUnlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock Career Bridge'**
  String get biometricReasonUnlock;

  /// No description provided for @appLockTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get appLockTitle;

  /// No description provided for @appLockSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock to continue'**
  String get appLockSubtitle;

  /// No description provided for @appLockFailed.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed. Try again or sign in another way.'**
  String get appLockFailed;

  /// No description provided for @appLockRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get appLockRetry;

  /// No description provided for @appLockSignInAnother.
  ///
  /// In en, this message translates to:
  /// **'Sign in another way'**
  String get appLockSignInAnother;
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
