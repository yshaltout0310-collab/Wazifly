// ignore_for_file: prefer_const_literals_to_create_immutables
import 'package:careerbridge/core/localization/generated/app_localizations.dart';
import 'package:careerbridge/core/localization/locale_controller.dart';
import 'package:careerbridge/features/career_coach/application/career_coach_controller.dart';
import 'package:careerbridge/features/career_coach/domain/chat_message.dart';
import 'package:careerbridge/features/career_coach/presentation/career_coach_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

final _messages = <ChatMessage>[
  const ChatMessage(id: 'a', role: ChatRole.user, text: 'How do I grow my career?'),
  const ChatMessage(
    id: 'b',
    role: ChatRole.assistant,
    text: 'Focus on shipping impact and learning in-demand skills.',
  ),
];

Widget _host(Locale locale, {required bool empty}) {
  return ProviderScope(
    overrides: [
      careerCoachControllerProvider.overrideWith(
        (ref) => CareerCoachController.seeded(
          ref,
          CareerCoachState(messages: empty ? const [] : _messages),
        ),
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
      home: const CareerCoachScreen(),
    ),
  );
}

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  for (final locale in const [Locale('en'), Locale('ar')]) {
    final tag = locale.languageCode.toUpperCase();

    testWidgets('conversation renders in $tag with no overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 915));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_host(locale, empty: false));
      await tester.pump(const Duration(milliseconds: 400));

      expect(tester.takeException(), isNull, reason: 'threw during render ($tag)');

      final dir =
          Directionality.of(tester.element(find.byType(CareerCoachScreen)));
      expect(dir,
          locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr);

      expect(find.text('How do I grow my career?'), findsOneWidget);
      expect(
          find.text('Focus on shipping impact and learning in-demand skills.'),
          findsOneWidget);
    });

    testWidgets('empty state shows starter prompts in $tag', (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 915));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_host(locale, empty: true));
      await tester.pump(const Duration(milliseconds: 700));

      expect(tester.takeException(), isNull, reason: 'threw during render ($tag)');

      final l10n = await AppLocalizations.delegate.load(locale);
      expect(find.text(l10n.coachIntroTitle), findsOneWidget);
      expect(find.text(l10n.coachPrompt1), findsOneWidget);
    });
  }
}
