import 'package:careerbridge/core/localization/generated/app_localizations.dart';
import 'package:careerbridge/core/localization/locale_controller.dart';
import 'package:careerbridge/core/navigation/route_names.dart';
import 'package:careerbridge/core/providers/app_providers.dart';
import 'package:careerbridge/core/services/company/company_repository.dart';
import 'package:careerbridge/core/services/company/in_memory_company_repository.dart';
import 'package:careerbridge/core/services/storage/local_storage_service.dart';
import 'package:careerbridge/core/services/user_profile/user_profile_repository.dart';
import 'package:careerbridge/features/auth/application/auth_providers.dart';
import 'package:careerbridge/features/auth/presentation/auth_navigation.dart';
import 'package:careerbridge/features/user_type/domain/user_type.dart';
import 'package:careerbridge/shared/models/app_user.dart';
import 'package:careerbridge/shared/models/user_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_auth.dart';

/// Guards the number of Firestore round trips a sign-in costs.
///
/// `goAfterAuth` used to await `ensureProfile` (a get, then a set) and then
/// `_resolveUserType(trustCache: false)`, whose `fetchProfile` issued a THIRD
/// round trip to re-read the document it had just written — all sequential, all
/// before the first navigation. That is what made signing in, and especially
/// retrying after a failed attempt, feel slow.
///
/// `ensureProfile` now returns the profile it already read, so the role comes
/// from that and the redundant read is gone. These tests pin the call counts,
/// because the cost is invisible in behaviour: the old code navigated to
/// exactly the same place, just later.

const _user = AppUser(uid: 'u1', method: AuthMethod.email, email: 'a@b.co');

/// Counts reads so a reintroduced round trip fails the build.
class _CountingProfiles implements UserProfileRepository {
  _CountingProfiles(this.stored);

  final UserProfile? stored;
  int ensureCount = 0;
  int fetchCount = 0;

  @override
  Future<UserProfile?> ensureProfile(AppUser user) async {
    ensureCount++;
    return stored;
  }

  @override
  Future<UserProfile?> fetchProfile(String uid) async {
    fetchCount++;
    return stored;
  }

  @override
  Stream<UserProfile?> watchProfile(String uid) =>
      Stream<UserProfile?>.value(stored);

  @override
  Future<void> saveProfile(UserProfile profile) async {}

  @override
  Future<void> setUserType(String uid, UserType type) async {}

  @override
  Future<void> setPhotoUrl(String uid, String url) async {}
}

/// Fires `goAfterAuth` from a real router context.
class _Harness extends ConsumerWidget {
  const _Harness();

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => goAfterAuth(context, ref),
            child: const Text('go'),
          ),
        ),
      );
}

GoRoute _stub(String path, String name, String marker) => GoRoute(
      path: path,
      name: name,
      builder: (_, __) => Scaffold(body: Center(child: Text(marker))),
    );

late LocalStorageService _storage;

Future<void> _pumpAndGo(
  WidgetTester tester,
  _CountingProfiles profiles,
) async {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, __) => const _Harness()),
      _stub('/home', RouteNames.home, 'SEEKER HOME'),
      _stub('/employer', RouteNames.employerHome, 'EMPLOYER HOME'),
      _stub('/user-type', RouteNames.userType, 'ROLE SELECTION'),
    ],
  );

  await tester.pumpWidget(ProviderScope(
    overrides: [
      localStorageProvider.overrideWithValue(_storage),
      authRepositoryProvider
          .overrideWithValue(FakeAuthRepository(user: _user)),
      userProfileRepositoryProvider.overrideWithValue(profiles),
      companyRepositoryProvider
          .overrideWithValue(InMemoryCompanyRepository()),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: supportedLocales,
    ),
  ));
  await tester.tap(find.text('go'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    _storage = await LocalStorageService.create();
  });

  testWidgets('a seeker sign-in reads the profile once', (tester) async {
    final profiles = _CountingProfiles(
      const UserProfile(uid: 'u1', userType: UserType.jobSeeker),
    );
    await _pumpAndGo(tester, profiles);

    expect(profiles.ensureCount, 1);
    expect(
      profiles.fetchCount,
      0,
      reason: 'fetchProfile re-read the document ensureProfile had just '
          'written — a third sequential round trip before navigating',
    );
    expect(find.text('SEEKER HOME'), findsOne);
  });

  testWidgets('an employer sign-in reads the profile once', (tester) async {
    final profiles = _CountingProfiles(
      const UserProfile(uid: 'u1', userType: UserType.employer),
    );
    await _pumpAndGo(tester, profiles);

    expect(profiles.ensureCount, 1);
    expect(profiles.fetchCount, 0);
    expect(find.text('EMPLOYER HOME'), findsOne);
  });

  testWidgets('a brand-new account still reaches role selection',
      (tester) async {
    // No stored profile => no role. The device-local cache must not be able to
    // stand in for it, or a new user inherits the previous user's role and
    // skips role selection entirely.
    final profiles = _CountingProfiles(null);
    await _pumpAndGo(tester, profiles);

    expect(profiles.ensureCount, 1);
    expect(profiles.fetchCount, 0);
    expect(find.text('ROLE SELECTION'), findsOne);
  });

  testWidgets('a stale cached role never overrides the stored one',
      (tester) async {
    // The device-global cache says employer; Firestore says job seeker. The
    // authoritative value must win on a fresh sign-in.
    SharedPreferences.setMockInitialValues({'pref_user_type': 'employer'});
    _storage = await LocalStorageService.create();

    final profiles = _CountingProfiles(
      const UserProfile(uid: 'u1', userType: UserType.jobSeeker),
    );
    await _pumpAndGo(tester, profiles);

    expect(find.text('SEEKER HOME'), findsOne);
    expect(profiles.fetchCount, 0);
  });
}
