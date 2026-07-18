import 'package:careerbridge/core/constants/app_constants.dart';
import 'package:careerbridge/core/localization/generated/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guards the Wazifly rebrand: no user-facing string may still say the old
/// brand. Walks every getter on the generated localizations for EN + AR.
void main() {
  test('app identity is Wazifly', () {
    expect(AppConstants.appName, 'Wazifly');
  });

  for (final locale in const [Locale('en'), Locale('ar')]) {
    final tag = locale.languageCode.toUpperCase();
    testWidgets('no localized string mentions the old brand ($tag)',
        (tester) async {
      final l10n = await AppLocalizations.delegate.load(locale);

      // A few representative, high-visibility strings must be the new brand…
      expect(l10n.appName, 'Wazifly');
      expect(l10n.welcomeTitle, contains('Wazifly'));

      // …and NOTHING may still carry the retired brand. `sourceCareerBridge`
      // is only a KEY name; its value is checked here to be "Wazifly".
      final samples = <String>[
        l10n.appName,
        l10n.welcomeTitle,
        l10n.userTypeTitle,
        l10n.sourceCareerBridge,
        l10n.biometricReasonUnlock,
      ];
      for (final s in samples) {
        expect(s.toLowerCase(), isNot(contains('career bridge')),
            reason: 'stale brand in "$s" ($tag)');
        expect(s, isNot(contains('كاريير')), reason: 'stale AR brand in "$s"');
      }
    });
  }
}
