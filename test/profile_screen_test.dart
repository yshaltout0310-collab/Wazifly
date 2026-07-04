import 'package:careerbridge/core/localization/generated/app_localizations.dart';
import 'package:careerbridge/core/localization/locale_controller.dart';
import 'package:careerbridge/core/providers/app_providers.dart';
import 'package:careerbridge/core/services/storage/local_storage_service.dart';
import 'package:careerbridge/core/services/storage/storage_keys.dart';
import 'package:careerbridge/core/services/user_profile/in_memory_user_profile_repository.dart';
import 'package:careerbridge/core/services/user_profile/user_profile_repository.dart';
import 'package:careerbridge/features/profile/domain/experience_level.dart';
import 'package:careerbridge/features/profile/presentation/profile_screen.dart';
import 'package:careerbridge/features/profile/presentation/widgets/completion_indicator.dart';
import 'package:careerbridge/shared/models/app_user.dart';
import 'package:careerbridge/shared/models/user_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_auth.dart';

const _user = AppUser(
  uid: 'u1',
  method: AuthMethod.email,
  email: 'sarah@cb.app',
  displayName: 'Sarah Ahmed',
);

const _profile = UserProfile(
  uid: 'u1',
  displayName: 'Sarah Ahmed',
  headline: 'Flutter Engineer',
  location: 'Doha',
  skills: ['Flutter', 'Dart'],
  experienceLevel: ExperienceLevel.senior,
  preferredJobTitles: ['Mobile Engineer'],
  githubUrl: 'https://github.com/sarah',
);

Widget _host(Locale locale, LocalStorageService storage) {
  return ProviderScope(
    overrides: [
      localStorageProvider.overrideWithValue(storage),
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
      home: const ProfileScreen(),
    ),
  );
}

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  for (final locale in const [Locale('en'), Locale('ar')]) {
    final tag = locale.languageCode.toUpperCase();
    testWidgets('profile renders in $tag with completion + details',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 915));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      SharedPreferences.setMockInitialValues(
          {StorageKeys.userType: 'jobSeeker'});
      final storage = await LocalStorageService.create();
      await tester.pumpWidget(_host(locale, storage));
      // Drain the auth-stream → profile-stream → rebuild chain, then let the
      // entrance animations play.
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(tester.takeException(), isNull, reason: 'threw ($tag)');
      final dir = Directionality.of(tester.element(find.byType(ProfileScreen)));
      expect(dir,
          locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr);

      expect(find.text('Sarah Ahmed'), findsWidgets);
      expect(find.text('Flutter Engineer'), findsOneWidget);
      expect(find.byType(CompletionIndicator), findsOneWidget);
      expect(find.widgetWithText(Chip, 'Flutter'), findsOneWidget);
    });
  }
}
