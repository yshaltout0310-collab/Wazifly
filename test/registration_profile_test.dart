import 'package:careerbridge/core/localization/generated/app_localizations.dart';
import 'package:careerbridge/core/localization/locale_controller.dart';
import 'package:careerbridge/core/navigation/route_names.dart';
import 'package:careerbridge/core/providers/app_providers.dart';
import 'package:careerbridge/core/services/company/company_repository.dart';
import 'package:careerbridge/core/services/company/in_memory_company_repository.dart';
import 'package:careerbridge/core/services/storage/local_storage_service.dart';
import 'package:careerbridge/core/services/user_profile/in_memory_user_profile_repository.dart';
import 'package:careerbridge/core/services/user_profile/user_profile_repository.dart';
import 'package:careerbridge/core/theme/app_theme.dart';
import 'package:careerbridge/core/utils/contact_details.dart';
import 'package:careerbridge/features/auth/application/auth_providers.dart';
import 'package:careerbridge/features/auth/presentation/email_auth_screen.dart';
import 'package:careerbridge/shared/models/app_user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_auth.dart';

/// Registration collects the user's full name and phone number.
///
/// Before this, sign-up asked only for email and password. Nothing ever set
/// Firebase Auth's `displayName`, so `ensureProfile` wrote
/// `users/{uid}.displayName = null` and `ensureCompany` seeded the company name
/// from that same null — which is why Company Profile rendered a fallback label
/// and empty rows for every employer.

late LocalStorageService _storage;
late InMemoryUserProfileRepository _profiles;
late InMemoryCompanyRepository _companies;
late FakeAuthRepository _auth;

Widget _app() {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, __) => const EmailAuthScreen()),
      GoRoute(
        path: '/verify',
        name: RouteNames.verifyEmail,
        builder: (_, __) => const Scaffold(body: Center(child: Text('VERIFY'))),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      localStorageProvider.overrideWithValue(_storage),
      authRepositoryProvider.overrideWithValue(_auth),
      userProfileRepositoryProvider.overrideWithValue(_profiles),
      companyRepositoryProvider.overrideWithValue(_companies),
    ],
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
}

Future<AppLocalizations> _toSignUp(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(412, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(_app());
  await tester.pumpAndSettle();

  final l10n = await AppLocalizations.delegate.load(const Locale('en'));
  await tester.tap(find.text(l10n.signUp));
  await tester.pumpAndSettle();
  return l10n;
}

/// Sign-up fields in order: full name, phone, email, password.
Future<void> _fill(
  WidgetTester tester, {
  String name = 'Sarah Ahmed',
  String phone = '50123456',
  String email = 'sarah@cb.app',
  String password = 'passw0rdy',
}) async {
  await tester.enterText(find.byType(TextFormField).at(0), name);
  await tester.enterText(find.byType(TextFormField).at(1), phone);
  await tester.enterText(find.byType(TextFormField).at(2), email);
  await tester.enterText(find.byType(TextFormField).at(3), password);
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    _storage = await LocalStorageService.create();
    _profiles = InMemoryUserProfileRepository();
    _companies = InMemoryCompanyRepository();
    _auth = FakeAuthRepository();
  });

  group('successful registration', () {
    testWidgets('persists the name to Auth and the profile, and the phone',
        (tester) async {
      final l10n = await _toSignUp(tester);
      await _fill(tester);
      await tester.tap(find.text(l10n.signUp).last);
      await tester.pumpAndSettle();

      // Written to the Firebase Auth profile, so every downstream consumer
      // (ensureProfile, ensureCompany) can seed from it.
      expect(_auth.lastRegisteredDisplayName, 'Sarah Ahmed');

      final stored = await _profiles.fetchProfile('test-uid');
      expect(stored?.displayName, 'Sarah Ahmed');
      expect(stored?.phoneNumber, '+97450123456',
          reason: 'stored in E.164, dial code from the selected country');

      expect(find.text('VERIFY'), findsOne);
    });

    testWidgets('normalizes a sloppily typed name', (tester) async {
      final l10n = await _toSignUp(tester);
      await _fill(tester, name: '  Sarah   Ahmed  ');
      await tester.tap(find.text(l10n.signUp).last);
      await tester.pumpAndSettle();

      expect(_auth.lastRegisteredDisplayName, 'Sarah Ahmed');
    });
  });

  group('missing or invalid fields block registration', () {
    testWidgets('a missing name does not create the account', (tester) async {
      final l10n = await _toSignUp(tester);
      await _fill(tester, name: '');
      await tester.tap(find.text(l10n.signUp).last);
      await tester.pumpAndSettle();

      expect(find.text(l10n.fieldRequired), findsWidgets);
      expect(_auth.lastRegisteredDisplayName, isNull);
      expect(find.text('VERIFY'), findsNothing);
    });

    testWidgets('a name with no letters is rejected', (tester) async {
      final l10n = await _toSignUp(tester);
      await _fill(tester, name: '12 34');
      await tester.tap(find.text(l10n.signUp).last);
      await tester.pumpAndSettle();

      expect(find.text(l10n.invalidFullName), findsOne);
      expect(find.text('VERIFY'), findsNothing);
    });

    testWidgets('a missing phone does not create the account', (tester) async {
      final l10n = await _toSignUp(tester);
      await _fill(tester, phone: '');
      await tester.tap(find.text(l10n.signUp).last);
      await tester.pumpAndSettle();

      expect(find.text(l10n.fieldRequired), findsWidgets);
      expect(_auth.lastRegisteredDisplayName, isNull);
      expect(find.text('VERIFY'), findsNothing);
    });

    testWidgets('a too-short phone number is rejected', (tester) async {
      final l10n = await _toSignUp(tester);
      await _fill(tester, phone: '123');
      await tester.tap(find.text(l10n.signUp).last);
      await tester.pumpAndSettle();

      expect(find.text(l10n.invalidPhoneNumber), findsOne);
      expect(find.text('VERIFY'), findsNothing);
    });

    testWidgets('a too-long phone number is rejected', (tester) async {
      final l10n = await _toSignUp(tester);
      await _fill(tester, phone: '123456789012345');
      await tester.tap(find.text(l10n.signUp).last);
      await tester.pumpAndSettle();

      expect(find.text(l10n.invalidPhoneNumber), findsOne);
      expect(find.text('VERIFY'), findsNothing);
    });
  });

  group('sign-in is unaffected', () {
    testWidgets('shows neither new field', (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      // Existing users sign in exactly as before: two fields, no new
      // requirements applied to an account that already exists.
      expect(find.text(l10n.fullNameLabel), findsNothing);
      expect(find.text(l10n.phoneLabel), findsNothing);
      expect(find.byType(TextFormField), findsNWidgets(2));
    });
  });

  group('Company Profile can use the saved name', () {
    testWidgets('ensureCompany seeds the company name from the display name',
        (tester) async {
      // Issue 17 was largely downstream of issue 3: ensureCompany seeds the
      // company name from user.displayName, which was always null because
      // nothing ever collected it.
      final l10n = await _toSignUp(tester);
      await _fill(tester);
      await tester.tap(find.text(l10n.signUp).last);
      await tester.pumpAndSettle();

      final user = AppUser(
        uid: 'test-uid',
        method: AuthMethod.email,
        email: 'sarah@cb.app',
        displayName: _auth.lastRegisteredDisplayName,
      );
      await _companies.ensureCompany(user.uid,
          email: user.email, name: user.displayName);

      final company = await _companies.fetchCompany('test-uid');
      expect(company?.name, 'Sarah Ahmed',
          reason: 'previously null, leaving Company Profile on its fallback '
              'label with every detail row empty');
    });
  });

  group('contact detail policies', () {
    test('full name: length bounds and at least one letter', () {
      expect(FullNamePolicy.isValid('Jo'), isTrue);
      expect(FullNamePolicy.isValid('J'), isFalse);
      expect(FullNamePolicy.isValid('12345'), isFalse);
      expect(FullNamePolicy.isValid('.'), isFalse);
      expect(FullNamePolicy.isValid('سارة أحمد'), isTrue,
          reason: 'the app ships Arabic; an Arabic name is a name');
      expect(
        FullNamePolicy.isValid('a' * (FullNamePolicy.maxLength + 1)),
        isFalse,
        reason: 'firestore.rules caps displayName at 120 and profile writes '
            'swallow failures, so an over-long name would be lost silently',
      );
    });

    test('full name: normalize collapses whitespace', () {
      expect(FullNamePolicy.normalize('  Sarah   Ahmed '), 'Sarah Ahmed');
    });

    test('phone: national-number bounds', () {
      expect(PhonePolicy.isValidNational('50123456'), isTrue);
      expect(PhonePolicy.isValidNational('50 12 34 56'), isTrue);
      expect(PhonePolicy.isValidNational('12345'), isFalse);
      expect(PhonePolicy.isValidNational('123456789012345'), isFalse);
      expect(PhonePolicy.isValidNational(''), isFalse);
    });

    test('phone: compose produces E.164, or null when unusable', () {
      expect(
        PhonePolicy.compose(dialCode: '+974', national: '50 123 456'),
        '+97450123456',
      );
      expect(PhonePolicy.compose(dialCode: '', national: '50123456'), isNull);
      expect(PhonePolicy.compose(dialCode: '+974', national: '12'), isNull,
          reason: 'never persist a half-formed number like "+974"');
    });
  });
}
