import 'package:careerbridge/core/localization/generated/app_localizations.dart';
import 'package:careerbridge/core/localization/locale_controller.dart';
import 'package:careerbridge/core/services/user_profile/in_memory_user_profile_repository.dart';
import 'package:careerbridge/core/services/user_profile/user_profile_repository.dart';
import 'package:careerbridge/features/profile/presentation/edit_profile_screen.dart';
import 'package:careerbridge/shared/models/app_user.dart';
import 'package:careerbridge/shared/models/user_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'support/fake_auth.dart';

const _user =
    AppUser(uid: 'u1', method: AuthMethod.email, displayName: 'Sarah Ahmed');

const _profile = UserProfile(
  uid: 'u1',
  displayName: 'Sarah Ahmed',
  headline: 'Flutter Engineer',
  skills: ['Flutter'],
);

Widget _host(Locale locale) {
  return ProviderScope(
    overrides: [
      fakeAuthOverride(user: _user),
      userProfileRepositoryProvider.overrideWithValue(
        InMemoryUserProfileRepository(seed: const [_profile]),
      ),
    ],
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: supportedLocales,
      home: const EditProfileScreen(),
    ),
  );
}

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  for (final locale in const [Locale('en'), Locale('ar')]) {
    final tag = locale.languageCode.toUpperCase();
    testWidgets('edit profile renders in $tag with seeded fields',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_host(locale));
      // Drain the auth-stream → profile-stream chain so the form seeds.
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(tester.takeException(), isNull, reason: 'threw ($tag)');
      final dir =
          Directionality.of(tester.element(find.byType(EditProfileScreen)));
      expect(dir,
          locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr);

      final l10n = await AppLocalizations.delegate.load(locale);
      expect(find.text(l10n.save), findsOneWidget);
      // Seeded values are present in the form.
      expect(find.text('Flutter Engineer'), findsOneWidget);
      expect(find.widgetWithText(Chip, 'Flutter'), findsOneWidget);
    });
  }
}
