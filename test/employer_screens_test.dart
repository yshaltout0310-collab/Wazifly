import 'package:careerbridge/core/localization/generated/app_localizations.dart';
import 'package:careerbridge/core/localization/locale_controller.dart';
import 'package:careerbridge/core/services/company/company_repository.dart';
import 'package:careerbridge/core/services/company/in_memory_company_repository.dart';
import 'package:careerbridge/features/auth/application/auth_providers.dart';
import 'package:careerbridge/features/employer/domain/company_size.dart';
import 'package:careerbridge/features/employer/domain/industry.dart';
import 'package:careerbridge/features/employer/presentation/company_profile_screen.dart';
import 'package:careerbridge/features/employer/presentation/edit_company_screen.dart';
import 'package:careerbridge/features/employer/presentation/employer_home_screen.dart';
import 'package:careerbridge/shared/models/app_user.dart';
import 'package:careerbridge/shared/models/company.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'support/fake_auth.dart';

const _user = AppUser(
    uid: 'c1', method: AuthMethod.email, email: 'owner@acme.co');

Company _company() => Company.empty('c1').copyWith(
      name: 'Acme',
      industry: Industry.technology,
      size: CompanySize.size11_50,
      website: 'https://acme.co',
      headquarters: 'Doha, Qatar',
      description: 'We build great things.',
      contactEmail: 'jobs@acme.co',
    );

Widget _host(Locale locale, Widget child) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(FakeAuthRepository(user: _user)),
      companyRepositoryProvider
          .overrideWithValue(InMemoryCompanyRepository(seed: [_company()])),
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
      home: child,
    ),
  );
}

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  final screens = <String, (Widget, double)>{
    'EmployerHome': (const EmployerHomeScreen(), 1600),
    'CompanyProfile': (const CompanyProfileScreen(), 1600),
    'EditCompany': (const EditCompanyScreen(), 2400),
  };

  for (final locale in const [Locale('en'), Locale('ar')]) {
    final tag = locale.languageCode.toUpperCase();
    final expectedDir =
        locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr;

    for (final entry in screens.entries) {
      final (widget, height) = entry.value;
      testWidgets('${entry.key} renders in $tag with no overflow',
          (tester) async {
        await tester.binding.setSurfaceSize(Size(412, height));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(_host(locale, widget));
        // Data loads async (auth + company streams) then one-shot animations
        // play; settle both so no timers remain.
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull,
            reason: '${entry.key} ($tag) threw');
        final dir =
            Directionality.of(tester.element(find.byType(widget.runtimeType)));
        expect(dir, expectedDir);
      });
    }
  }

  testWidgets('Company profile shows the company name + industry (EN)',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_host(const Locale('en'), const CompanyProfileScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Acme'), findsWidgets);
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.industryTechnology), findsWidgets);
  });
}
