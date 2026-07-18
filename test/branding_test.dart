import 'package:careerbridge/core/constants/app_constants.dart';
import 'package:careerbridge/core/localization/generated/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guards the Wazifly rebrand + Arabic brand localization.
///
/// The **wordmark / display name stays the Latin "Wazifly"** everywhere
/// (`AppConstants.appName`, `l10n.appName` — shown as the splash wordmark).
/// Inside **Arabic sentence text** the brand is localized to **"وظيفة فلاي"**;
/// English keeps "Wazifly". Nothing may still carry the retired brand.
void main() {
  const enBrand = 'Wazifly';
  const arBrand = 'وظيفة فلاي';

  test('app identity (wordmark) is Wazifly', () {
    expect(AppConstants.appName, 'Wazifly');
  });

  for (final locale in const [Locale('en'), Locale('ar')]) {
    final tag = locale.languageCode.toUpperCase();
    final isAr = locale.languageCode == 'ar';
    final brand = isAr ? arBrand : enBrand;

    testWidgets('brand strings are correct for $tag', (tester) async {
      final l10n = await AppLocalizations.delegate.load(locale);

      // The wordmark stays Latin "Wazifly" in BOTH locales (it's the logo text).
      expect(l10n.appName, 'Wazifly');

      // Sentence / label strings carry the locale's brand form.
      final sentences = <String>[
        l10n.welcomeTitle,
        l10n.userTypeTitle,
        l10n.sourceCareerBridge, // key name only; value is the brand
        l10n.biometricReasonUnlock,
      ];
      for (final s in sentences) {
        expect(s, contains(brand), reason: 'expected "$brand" in "$s" ($tag)');
        if (isAr) {
          // Arabic sentences must NOT keep the Latin wordmark inline.
          expect(s, isNot(contains(enBrand)),
              reason: 'Latin brand should be localized in "$s"');
        }
        // The retired brand must be gone everywhere.
        expect(s.toLowerCase(), isNot(contains('career bridge')));
        expect(s, isNot(contains('كاريير')));
      }
    });
  }
}
