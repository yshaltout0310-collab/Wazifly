import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../localization/generated/app_localizations.dart';
import '../../features/auth/presentation/email_auth_screen.dart';
import '../../features/auth/presentation/email_verification_screen.dart';
import '../../features/auth/presentation/phone_verification_screen.dart';
import '../../features/auth/presentation/welcome_screen.dart';
import '../../features/security/presentation/app_lock_screen.dart';
import '../../features/security/presentation/security_settings_screen.dart';
import '../../features/country_selection/presentation/country_selection_screen.dart';
import '../../features/employer/presentation/company_profile_screen.dart';
import '../../features/employer/presentation/edit_company_screen.dart';
import '../../features/employer/presentation/employer_analytics_screen.dart';
import '../../features/employer/presentation/employer_applicant_detail_screen.dart';
import '../../features/employer/presentation/employer_applicants_screen.dart';
import '../../features/employer/presentation/employer_candidates_screen.dart';
import '../../features/employer/presentation/employer_home_screen.dart';
import '../../features/employer/presentation/employer_interview_screen.dart';
import '../../features/employer/presentation/employer_job_detail_screen.dart';
import '../../features/employer/presentation/employer_jobs_screen.dart';
import '../../features/employer/presentation/job_editor_screen.dart';
import '../../features/employer/presentation/job_preview_screen.dart';
import '../../features/applications/presentation/application_detail_screen.dart';
import '../../features/cv_builder/presentation/cv_builder_screen.dart';
import '../../features/cv_builder/presentation/cv_preview_screen.dart';
import '../../features/cv_repository/presentation/cv_detail_screen.dart';
import '../../features/cv_repository/presentation/cv_library_screen.dart';
import '../../features/applications/presentation/applications_screen.dart';
import '../../features/career_coach/presentation/career_coach_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/interview_prep/presentation/interview_history_screen.dart';
import '../../features/interview_prep/presentation/interview_prep_screen.dart';
import '../../features/interview_prep/presentation/interview_session_detail_screen.dart';
import '../../features/internships/presentation/internships_screen.dart';
import '../../features/job_matching/presentation/job_matching_screen.dart';
import '../../features/jobs/presentation/job_detail_screen.dart';
import '../../features/jobs/presentation/jobs_screen.dart';
import '../../features/learning/presentation/learning_interests_screen.dart';
import '../../features/language_selection/presentation/language_selection_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/profile/presentation/change_password_screen.dart';
import '../../features/profile/presentation/edit_profile_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/recommendations/presentation/recommendations_screen.dart';
import '../../features/resume_analyzer/presentation/resume_analyzer_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../shared/models/job.dart';
import '../../shared/models/job_posting.dart';
import '../../features/user_type/presentation/user_type_selection_screen.dart';
import 'route_names.dart';

/// Declarative navigation graph for the Phase 1 flow:
///
///   Splash → Language → Country → Onboarding → Welcome
///         → Email (sign in / sign up) → Verify email → User Type → Home
///
/// Screens advance with `context.goNamed(...)`; the splash chooses the entry
/// point from persisted state (onboarding, session, user type).
abstract final class AppRouter {
  AppRouter._();

  /// Builds the app router. [observers] lets the bootstrap attach a
  /// vendor-neutral `AnalyticsRouteObserver` for screen-view tracking without the
  /// router knowing about analytics.
  static GoRouter create({List<NavigatorObserver> observers = const []}) =>
      GoRouter(
    initialLocation: RouteNames.splashPath,
    debugLogDiagnostics: true,
    observers: observers,
    routes: [
      GoRoute(
        path: RouteNames.splashPath,
        name: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RouteNames.languagePath,
        name: RouteNames.language,
        pageBuilder: _fade(const LanguageSelectionScreen()),
      ),
      GoRoute(
        path: RouteNames.countryPath,
        name: RouteNames.country,
        pageBuilder: _fade(const CountrySelectionScreen()),
      ),
      GoRoute(
        path: RouteNames.onboardingPath,
        name: RouteNames.onboarding,
        pageBuilder: _fade(const OnboardingScreen()),
      ),
      GoRoute(
        path: RouteNames.welcomePath,
        name: RouteNames.welcome,
        pageBuilder: _fade(const WelcomeScreen()),
      ),
      GoRoute(
        path: RouteNames.emailAuthPath,
        name: RouteNames.emailAuth,
        pageBuilder: _fade(const EmailAuthScreen()),
      ),
      GoRoute(
        path: RouteNames.verifyEmailPath,
        name: RouteNames.verifyEmail,
        pageBuilder: _fade(const EmailVerificationScreen()),
      ),
      GoRoute(
        path: RouteNames.appLockPath,
        name: RouteNames.appLock,
        pageBuilder: _fade(const AppLockScreen()),
      ),
      GoRoute(
        path: RouteNames.userTypePath,
        name: RouteNames.userType,
        pageBuilder: _fade(const UserTypeSelectionScreen()),
      ),
      GoRoute(
        path: RouteNames.homePath,
        name: RouteNames.home,
        pageBuilder: _fade(const HomeScreen()),
      ),
      GoRoute(
        path: RouteNames.resumeAnalyzerPath,
        name: RouteNames.resumeAnalyzer,
        pageBuilder: _fade(const ResumeAnalyzerScreen()),
      ),
      GoRoute(
        path: RouteNames.jobMatchingPath,
        name: RouteNames.jobMatching,
        pageBuilder: _fade(const JobMatchingScreen()),
      ),
      GoRoute(
        path: RouteNames.careerCoachPath,
        name: RouteNames.careerCoach,
        // Optional String `extra` seeds an initial user message (e.g. from a
        // job's "Ask the coach about this job").
        pageBuilder: (context, state) => _fadePage(
          CareerCoachScreen(seedPrompt: state.extra as String?),
          state,
        ),
      ),
      GoRoute(
        path: RouteNames.jobsPath,
        name: RouteNames.jobs,
        pageBuilder: _fade(const JobsScreen()),
      ),
      GoRoute(
        path: RouteNames.jobDetailPath,
        name: RouteNames.jobDetail,
        pageBuilder: (context, state) => _fadePage(
          JobDetailScreen(jobId: state.pathParameters['id'] ?? ''),
          state,
        ),
      ),
      GoRoute(
        path: RouteNames.cvBuilderPath,
        name: RouteNames.cvBuilder,
        // Optional String `extra` = the id of a stored CV to edit + save back.
        pageBuilder: (context, state) => _fadePage(
          CvBuilderScreen(cvId: state.extra as String?),
          state,
        ),
        routes: [
          GoRoute(
            path: 'preview',
            name: RouteNames.cvPreview,
            pageBuilder: _fade(const CvPreviewScreen()),
          ),
        ],
      ),
      GoRoute(
        path: RouteNames.cvLibraryPath,
        name: RouteNames.cvLibrary,
        pageBuilder: _fade(const CvLibraryScreen()),
        routes: [
          GoRoute(
            path: ':id',
            name: RouteNames.cvDetail,
            pageBuilder: (context, state) => _fadePage(
              CvDetailScreen(cvId: state.pathParameters['id'] ?? ''),
              state,
            ),
          ),
        ],
      ),
      GoRoute(
        path: RouteNames.interviewPrepPath,
        name: RouteNames.interviewPrep,
        // Optional `Job` extra tailors the interview to a specific job.
        pageBuilder: (context, state) => _fadePage(
          InterviewPrepScreen(job: state.extra is Job ? state.extra as Job : null),
          state,
        ),
        routes: [
          GoRoute(
            path: 'history',
            name: RouteNames.interviewHistory,
            pageBuilder: _fade(const InterviewHistoryScreen()),
            routes: [
              GoRoute(
                path: ':id',
                name: RouteNames.interviewSessionDetail,
                pageBuilder: (context, state) => _fadePage(
                  InterviewSessionDetailScreen(
                      sessionId: state.pathParameters['id'] ?? ''),
                  state,
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: RouteNames.applicationsPath,
        name: RouteNames.applications,
        pageBuilder: _fade(const ApplicationsScreen()),
      ),
      GoRoute(
        path: RouteNames.recommendationsPath,
        name: RouteNames.recommendations,
        pageBuilder: _fade(const RecommendationsScreen()),
      ),
      GoRoute(
        path: RouteNames.internshipsPath,
        name: RouteNames.internships,
        pageBuilder: _fade(const InternshipsScreen()),
      ),
      GoRoute(
        path: RouteNames.learningPath,
        name: RouteNames.learning,
        pageBuilder: _fade(const LearningInterestsScreen()),
      ),
      GoRoute(
        path: RouteNames.applicationDetailPath,
        name: RouteNames.applicationDetail,
        pageBuilder: (context, state) => _fadePage(
          ApplicationDetailScreen(
              applicationId: state.pathParameters['id'] ?? ''),
          state,
        ),
      ),
      GoRoute(
        path: RouteNames.employerHomePath,
        name: RouteNames.employerHome,
        pageBuilder: _fade(const EmployerHomeScreen()),
        routes: [
          GoRoute(
            path: 'company',
            name: RouteNames.companyProfile,
            pageBuilder: _fade(const CompanyProfileScreen()),
            routes: [
              GoRoute(
                path: 'edit',
                name: RouteNames.editCompany,
                pageBuilder: _fade(const EditCompanyScreen()),
              ),
            ],
          ),
          GoRoute(
            path: 'jobs',
            name: RouteNames.employerJobs,
            pageBuilder: _fade(const EmployerJobsScreen()),
            // Static children ('new'/'preview') are declared before ':id' so
            // they match ahead of the dynamic detail route.
            routes: [
              GoRoute(
                path: 'new',
                name: RouteNames.createJob,
                pageBuilder: _fade(const JobEditorScreen()),
              ),
              GoRoute(
                path: 'preview',
                name: RouteNames.jobPreview,
                pageBuilder: (context, state) => _fadePage(
                  JobPreviewScreen(posting: state.extra as JobPosting),
                  state,
                ),
              ),
              GoRoute(
                path: ':id',
                name: RouteNames.employerJobDetail,
                pageBuilder: (context, state) => _fadePage(
                  EmployerJobDetailScreen(
                      jobId: state.pathParameters['id'] ?? ''),
                  state,
                ),
                routes: [
                  GoRoute(
                    path: 'edit',
                    name: RouteNames.editJob,
                    pageBuilder: (context, state) => _fadePage(
                      JobEditorScreen(jobId: state.pathParameters['id']),
                      state,
                    ),
                  ),
                  GoRoute(
                    path: 'applicants',
                    name: RouteNames.employerJobApplicants,
                    pageBuilder: (context, state) => _fadePage(
                      EmployerApplicantsScreen(
                          jobId: state.pathParameters['id']),
                      state,
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: 'applicants',
            name: RouteNames.employerApplicants,
            pageBuilder: _fade(const EmployerApplicantsScreen()),
            routes: [
              GoRoute(
                path: ':appId',
                name: RouteNames.employerApplicantDetail,
                pageBuilder: (context, state) => _fadePage(
                  EmployerApplicantDetailScreen(
                      appId: state.pathParameters['appId'] ?? ''),
                  state,
                ),
              ),
            ],
          ),
          GoRoute(
            path: 'analytics',
            name: RouteNames.employerAnalytics,
            pageBuilder: _fade(const EmployerAnalyticsScreen()),
          ),
          GoRoute(
            path: 'interview',
            name: RouteNames.employerInterview,
            pageBuilder: _fade(const EmployerInterviewScreen()),
          ),
          GoRoute(
            path: 'candidates',
            name: RouteNames.employerCandidates,
            pageBuilder: _fade(const EmployerCandidatesScreen()),
          ),
        ],
      ),
      GoRoute(
        path: RouteNames.settingsPath,
        name: RouteNames.settings,
        pageBuilder: _fade(const SettingsScreen()),
        routes: [
          GoRoute(
            path: 'profile',
            name: RouteNames.profile,
            pageBuilder: _fade(const ProfileScreen()),
            routes: [
              GoRoute(
                path: 'edit',
                name: RouteNames.editProfile,
                pageBuilder: _fade(const EditProfileScreen()),
              ),
            ],
          ),
          GoRoute(
            path: 'change-password',
            name: RouteNames.changePassword,
            pageBuilder: _fade(const ChangePasswordScreen()),
          ),
          GoRoute(
            path: 'security',
            name: RouteNames.security,
            pageBuilder: _fade(const SecuritySettingsScreen()),
            routes: [
              GoRoute(
                path: 'phone',
                name: RouteNames.phoneVerify,
                pageBuilder: _fade(const PhoneVerificationScreen()),
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48),
            const SizedBox(height: 12),
            Text(AppLocalizations.of(context).pageNotFound),
          ],
        ),
      ),
    ),
  );

  static Page<void> Function(BuildContext, GoRouterState) _fade(Widget child) =>
      (context, state) => _fadePage(child, state);

  static Page<void> _fadePage(Widget child, GoRouterState state) =>
      CustomTransitionPage<void>(
        key: state.pageKey,
        // Propagate the route name to the page so the AnalyticsRouteObserver can
        // report a meaningful screen_view (CustomTransitionPage doesn't set this
        // automatically).
        name: state.name,
        child: child,
        transitionDuration: const Duration(milliseconds: 420),
        reverseTransitionDuration: const Duration(milliseconds: 320),
        transitionsBuilder: (context, animation, secondary, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: const Cubic(0.2, 0.0, 0.0, 1.0),
            reverseCurve: Curves.easeIn,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.035),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      );
}
