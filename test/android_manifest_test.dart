// Regression guard for the Android manifest's permission surface.
//
// The app deliberately requests a tiny, auditable set of permissions, and it
// strips the advertising ID that firebase_analytics would otherwise merge in.
// These facts back the Play Console declarations (docs/store/PLAY_CONSOLE.md §3,
// §7) and Data Safety (docs/store/DATA_SAFETY.md), so a silent change here would
// desync the store paperwork from the shipped artifact. This test asserts on the
// source manifest (the app's own declarations); the Gradle manifest-merge that
// applies the tools:node="remove" directive is verified at build time.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final manifest = File(
    'android/app/src/main/AndroidManifest.xml',
  ).readAsStringSync();

  group('AndroidManifest permissions', () {
    test('declares exactly the three expected app permissions', () {
      final declared = RegExp(r'<uses-permission\s+android:name="([^"]+)"')
          .allMatches(manifest)
          .map((m) => m.group(1)!)
          .toList();

      // The advertising-ID entry is present only to REMOVE it (tools:node),
      // not to request it — exclude it from the "requested" set.
      final requested = declared
          .where((p) => p != 'com.google.android.gms.permission.AD_ID')
          .toSet();

      expect(
        requested,
        {
          'android.permission.INTERNET',
          'android.permission.POST_NOTIFICATIONS',
          'android.permission.USE_BIOMETRIC',
        },
        reason:
            'The app must request only INTERNET, POST_NOTIFICATIONS and '
            'USE_BIOMETRIC. Update docs/store/PLAY_CONSOLE.md if this changes.',
      );
    });

    test('strips the advertising ID (AD_ID) via manifest merge', () {
      expect(
        manifest.contains('xmlns:tools='),
        isTrue,
        reason: 'The tools namespace is required for the AD_ID removal.',
      );
      final adIdRemoval = RegExp(
        r'<uses-permission\s+android:name="com\.google\.android\.gms\.permission\.AD_ID"\s+tools:node="remove"\s*/>',
      );
      expect(
        adIdRemoval.hasMatch(manifest),
        isTrue,
        reason:
            'firebase_analytics merges AD_ID; it must be removed so the app '
            'carries no advertising ID (Data Safety: no ads / no ad ID).',
      );
    });

    test('requests no dangerous / sensitive permissions', () {
      const sensitive = [
        'ACCESS_FINE_LOCATION',
        'ACCESS_COARSE_LOCATION',
        'CAMERA',
        'READ_CONTACTS',
        'READ_SMS',
        'RECEIVE_SMS',
        'READ_EXTERNAL_STORAGE',
        'WRITE_EXTERNAL_STORAGE',
        'QUERY_ALL_PACKAGES',
        'RECORD_AUDIO',
      ];
      for (final perm in sensitive) {
        expect(
          manifest.contains(perm),
          isFalse,
          reason: 'Unexpected sensitive permission $perm would trigger a Play '
              'permissions-declaration form.',
        );
      }
    });
  });
}
