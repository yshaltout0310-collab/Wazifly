import 'package:careerbridge/core/localization/generated/app_localizations.dart';
import 'package:careerbridge/core/localization/locale_controller.dart';
import 'package:careerbridge/core/navigation/route_names.dart';
import 'package:careerbridge/core/services/company/company_repository.dart';
import 'package:careerbridge/core/services/company/in_memory_company_repository.dart';
import 'package:careerbridge/core/services/jobs/employer_jobs_repository.dart';
import 'package:careerbridge/core/services/jobs/in_memory_employer_jobs_repository.dart';
import 'package:careerbridge/core/theme/app_theme.dart';
import 'package:careerbridge/features/auth/application/auth_providers.dart';
import 'package:careerbridge/features/employer/application/employer_jobs_controller.dart';
import 'package:careerbridge/features/employer/application/job_editor_controller.dart';
import 'package:careerbridge/features/employer/domain/employment_type.dart';
import 'package:careerbridge/features/employer/domain/job_experience.dart';
import 'package:careerbridge/features/employer/domain/job_status.dart';
import 'package:careerbridge/features/employer/presentation/job_action_handler.dart';
import 'package:careerbridge/features/employer/presentation/job_actions.dart';
import 'package:careerbridge/features/employer/presentation/job_editor_screen.dart';
import 'package:careerbridge/shared/models/app_user.dart';
import 'package:careerbridge/shared/models/company.dart';
import 'package:careerbridge/shared/models/job_posting.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'support/fake_auth.dart';

/// Guards the publish path.
///
/// The defect: **nothing published**. The editor's "Publish" button validated,
/// saved a *draft*, and navigated to Preview; `JobAction.publish` fell through
/// to `JobAction.preview` and only navigated. The status transition lived
/// solely in the Preview screen's confirmation, so an employer who tapped
/// Publish and did not then confirm on Preview was left with a `draft`.
///
/// That one defect produced four separate-looking reports: Publish appears not
/// to work, published jobs are missing from Manage Jobs, seekers cannot find
/// them (the seeker query is `status == 'published'`), and the Active Jobs
/// dashboard count stays at zero.

const _user = AppUser(uid: 'c1', method: AuthMethod.email, email: 'a@b.co');

/// A draft that passes `JobValidator.forPublish`.
JobPosting _completeDraft() => JobPosting(
      id: 'j1',
      companyId: 'c1',
      ownerUid: 'c1',
      companyName: 'Acme',
      title: 'Flutter Engineer',
      description:
          'Build and ship delightful cross-platform mobile apps with Flutter.',
      requiredSkills: const ['Flutter', 'Dart'],
      location: 'Doha',
      employmentType: EmploymentType.fullTime,
      experience: JobExperience.senior,
      status: JobStatus.draft,
      updatedAt: DateTime(2026, 7, 1),
    );

/// A draft with only a title — saveable, but not fit to go live.
JobPosting _incompleteDraft() => JobPosting(
      id: 'j2',
      companyId: 'c1',
      ownerUid: 'c1',
      title: 'Untitled role',
      status: JobStatus.draft,
      updatedAt: DateTime(2026, 7, 1),
    );

List<Override> _overrides(EmployerJobsRepository repo) => [
      authRepositoryProvider.overrideWithValue(FakeAuthRepository(user: _user)),
      companyRepositoryProvider.overrideWithValue(InMemoryCompanyRepository(
          seed: [Company.empty('c1').copyWith(name: 'Acme')])),
      employerJobsRepositoryProvider.overrideWithValue(repo),
    ];

Widget _app(GoRouter router, List<Override> overrides) => ProviderScope(
      overrides: overrides,
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('en'),
        theme: AppTheme.light(const Locale('en')),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: supportedLocales,
      ),
    );

/// Stand-ins for the destinations the publish paths navigate to, so a wrong
/// navigation is observable rather than a crash.
GoRoute _stub(String path, String name, String marker) => GoRoute(
      path: path,
      name: name,
      builder: (_, __) => Scaffold(body: Center(child: Text(marker))),
    );

/// Fires a [JobAction] through [runJobAction] from a real router context.
class _ActionHarness extends ConsumerWidget {
  const _ActionHarness({required this.job, required this.action});

  final JobPosting job;
  final JobAction action;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => runJobAction(context, ref, job, action),
            child: const Text('go'),
          ),
        ),
      );
}

void main() {
  group('EmployerJobsController._transition', () {
    test('reports staleStatus instead of silently doing nothing', () async {
      final live = _completeDraft().copyWith(status: JobStatus.published);
      final repo = InMemoryEmployerJobsRepository(seed: [live]);
      final container = ProviderContainer(overrides: _overrides(repo));
      addTearDown(container.dispose);

      // published -> published is not a legal transition.
      await container
          .read(employerJobsControllerProvider.notifier)
          .publish(live);

      expect(
        container.read(employerJobsControllerProvider).failure,
        JobsActionFailure.staleStatus,
        reason: 'a dead button with no feedback is what was reported as '
            '"Publish does not work"',
      );
    });
  });

  group('JobAction.publish', () {
    testWidgets('publishes directly, without going through Preview',
        (tester) async {
      final repo = InMemoryEmployerJobsRepository(seed: [_completeDraft()]);
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => _ActionHarness(
                job: _completeDraft(), action: JobAction.publish),
          ),
          _stub('/preview', RouteNames.jobPreview, 'PREVIEW'),
          _stub('/edit/:id', RouteNames.editJob, 'EDITOR'),
        ],
      );

      await tester.pumpWidget(_app(router, _overrides(repo)));
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      // Confirmation happens in place — not on the Preview screen.
      expect(find.text('PREVIEW'), findsNothing);
      expect(find.text(l10n.jobPublishConfirmTitle), findsOne);

      await tester.tap(find.text(l10n.jobPublishConfirmCta));
      await tester.pumpAndSettle();

      expect((await repo.fetchJob('j1'))?.status, JobStatus.published);
    });

    testWidgets('refuses an incomplete draft and sends it to the editor',
        (tester) async {
      final repo = InMemoryEmployerJobsRepository(seed: [_incompleteDraft()]);
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => _ActionHarness(
                job: _incompleteDraft(), action: JobAction.publish),
          ),
          _stub('/preview', RouteNames.jobPreview, 'PREVIEW'),
          _stub('/edit/:id', RouteNames.editJob, 'EDITOR'),
        ],
      );

      await tester.pumpWidget(_app(router, _overrides(repo)));
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(find.text(l10n.jobErrFixFields), findsOne);
      expect(find.text('EDITOR'), findsOne);
      expect(
        (await repo.fetchJob('j2'))?.status,
        JobStatus.draft,
        reason: 'a posting with no description, skills, experience, type or '
            'location must not reach seekers',
      );
    });

    testWidgets('Preview still only previews', (tester) async {
      final repo = InMemoryEmployerJobsRepository(seed: [_completeDraft()]);
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => _ActionHarness(
                job: _completeDraft(), action: JobAction.preview),
          ),
          _stub('/preview', RouteNames.jobPreview, 'PREVIEW'),
          _stub('/edit/:id', RouteNames.editJob, 'EDITOR'),
        ],
      );

      await tester.pumpWidget(_app(router, _overrides(repo)));
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      expect(find.text('PREVIEW'), findsOne);
      expect((await repo.fetchJob('j1'))?.status, JobStatus.draft);
    });
  });

  group('job editor Publish button', () {
    testWidgets('publishes the saved posting instead of only previewing',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final draft = _completeDraft();
      final repo = InMemoryEmployerJobsRepository(seed: [draft]);
      final router = GoRouter(
        initialLocation: '/edit/j1',
        routes: [
          GoRoute(
            path: '/edit/:id',
            name: RouteNames.editJob,
            builder: (_, state) =>
                JobEditorScreen(jobId: state.pathParameters['id']),
          ),
          _stub('/jobs', RouteNames.employerJobs, 'MY JOBS'),
          _stub('/preview', RouteNames.jobPreview, 'PREVIEW'),
        ],
      );

      await tester.pumpWidget(_app(router, [
        ..._overrides(repo),
        // The editor seeds synchronously from employerJobByIdProvider, which is
        // still empty on the first frame, so seed its state directly.
        jobEditorControllerProvider.overrideWith(
          (ref, _) => JobEditorController.seeded(
            ref,
            JobEditorState(draft: draft, isNew: false, savedSnapshot: draft),
          ),
        ),
      ]));
      await tester.pumpAndSettle();

      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      // By icon, not text: the bottom bar's Publish and the confirm dialog's
      // CTA share the same label.
      await tester.tap(find.byIcon(Icons.publish_rounded));
      await tester.pumpAndSettle();

      // Confirms in place; Preview is no longer a step in publishing.
      expect(find.text('PREVIEW'), findsNothing);
      expect(find.text(l10n.jobPublishConfirmTitle), findsOne);

      await tester.tap(find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text(l10n.jobPublishConfirmCta),
      ));
      await tester.pumpAndSettle();

      expect(
        (await repo.fetchJob('j1'))?.status,
        JobStatus.published,
        reason: 'this is the reported bug: Publish left the posting a draft',
      );
      expect(find.text('MY JOBS'), findsOne);
    });
  });
}
