import 'package:careerbridge/core/navigation/route_names.dart';
import 'package:careerbridge/core/providers/app_providers.dart';
import 'package:careerbridge/core/services/storage/local_storage_service.dart';
import 'package:careerbridge/core/services/storage/storage_keys.dart';
import 'package:careerbridge/core/services/user_profile/in_memory_user_profile_repository.dart';
import 'package:careerbridge/core/services/user_profile/user_profile_repository.dart';
import 'package:careerbridge/features/auth/application/auth_providers.dart';
import 'package:careerbridge/features/auth/presentation/auth_navigation.dart';
import 'package:careerbridge/features/user_type/application/user_type_controller.dart';
import 'package:careerbridge/features/user_type/domain/user_type.dart';
import 'package:careerbridge/shared/models/app_user.dart';
import 'package:careerbridge/shared/models/user_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_auth.dart';

/// Regression coverage for the role-selection routing bug: after authentication
/// the destination must be decided by the **per-user Firestore role**, not by a
/// role a previous user left in the device-global cache. See [goAfterAuth].
const _user = AppUser(
  uid: 'new-uid',
  method: AuthMethod.email,
  email: 'new@user.app',
  emailVerified: true,
);

/// A minimal start screen whose button drives the real [goAfterAuth].
class _Start extends ConsumerWidget {
  const _Start();

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

GoRouter _router() => GoRouter(
      initialLocation: RouteNames.welcomePath,
      routes: [
        GoRoute(
          path: RouteNames.welcomePath,
          name: RouteNames.welcome,
          builder: (_, __) => const _Start(),
        ),
        GoRoute(
          path: RouteNames.userTypePath,
          name: RouteNames.userType,
          builder: (_, __) => const Scaffold(body: Text('ROLE_SELECTION')),
        ),
        GoRoute(
          path: RouteNames.homePath,
          name: RouteNames.home,
          builder: (_, __) => const Scaffold(body: Text('SEEKER_HOME')),
        ),
        GoRoute(
          path: RouteNames.employerHomePath,
          name: RouteNames.employerHome,
          builder: (_, __) => const Scaffold(body: Text('EMPLOYER_HOME')),
        ),
      ],
    );

Future<ProviderContainer> _container({
  Map<String, Object> seed = const {},
  required UserProfileRepository profiles,
}) async {
  SharedPreferences.setMockInitialValues(seed);
  final storage = await LocalStorageService.create();
  final c = ProviderContainer(overrides: [
    localStorageProvider.overrideWithValue(storage),
    authRepositoryProvider.overrideWithValue(FakeAuthRepository(user: _user)),
    userProfileRepositoryProvider.overrideWithValue(profiles),
  ]);
  addTearDown(c.dispose);
  return c;
}

Future<void> _pumpAndGo(WidgetTester tester, ProviderContainer c) async {
  await tester.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: MaterialApp.router(routerConfig: _router()),
  ));
  await tester.tap(find.text('go'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'new user with no Firestore role reaches role selection even when a '
    'previous user left a role in the device-local cache',
    (tester) async {
      final c = await _container(
        // A prior user on this device had chosen Job Seeker.
        seed: {StorageKeys.userType: UserType.jobSeeker.name},
        // The signed-in user is new: their Firestore profile has no role.
        profiles: InMemoryUserProfileRepository(),
      );
      // The stale device-local role is present before we route.
      expect(c.read(userTypeControllerProvider), UserType.jobSeeker);

      await _pumpAndGo(tester, c);

      // Firestore is authoritative: no role → role selection, NOT the seeker flow.
      expect(find.text('ROLE_SELECTION'), findsOneWidget);
      expect(find.text('SEEKER_HOME'), findsNothing);
      // The stale cache was reconciled away for this user.
      expect(c.read(userTypeControllerProvider), isNull);
    },
  );

  testWidgets(
    'returning user with a saved Firestore role routes straight to that home '
    'and rehydrates the local cache',
    (tester) async {
      final c = await _container(
        // Empty device cache (e.g. fresh install), role lives in Firestore.
        profiles: InMemoryUserProfileRepository(seed: const [
          UserProfile(uid: 'new-uid', userType: UserType.jobSeeker),
        ]),
      );
      expect(c.read(userTypeControllerProvider), isNull);

      await _pumpAndGo(tester, c);

      expect(find.text('SEEKER_HOME'), findsOneWidget);
      expect(find.text('ROLE_SELECTION'), findsNothing);
      // Cache reconciled to the authoritative Firestore role.
      expect(c.read(userTypeControllerProvider), UserType.jobSeeker);
    },
  );
}
