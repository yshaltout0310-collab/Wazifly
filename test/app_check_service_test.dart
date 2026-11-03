import 'dart:io';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:careerbridge/core/services/app_check/app_check_service.dart';
import 'package:careerbridge/core/services/app_check/firebase_app_check_service.dart';
import 'package:careerbridge/core/services/app_check/noop_app_check_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('NoopAppCheckService activates as a no-op and yields no token',
      () async {
    const AppCheckService service = NoopAppCheckService();

    // Activation "succeeds" (nothing to attest) so the bootstrap never records a
    // failure in unconfigured runs / tests.
    expect(await service.activate(), isTrue);
    expect(await service.getToken(), isNull);
    expect(await service.getToken(forceRefresh: true), isNull);
  });

  test('configured web release selects reCAPTCHA Enterprise', () {
    const siteKey = 'test-enterprise-site-key';

    final providers = selectAppCheckProviders(
      isWeb: true,
      isDebug: false,
      webRecaptchaSiteKey: siteKey,
    );

    expect(providers.webProvider, isA<ReCaptchaEnterpriseProvider>());
    expect(providers.webProvider!.siteKey, siteKey);
  });

  test('web site key comes from the build-time dart define', () {
    const buildTimeSiteKey = String.fromEnvironment('RECAPTCHA_SITE_KEY');

    expect(FirebaseAppCheckService.webRecaptchaSiteKey, buildTimeSiteKey);
  });

  test('Android debug and release providers remain unchanged', () {
    final debugProviders = selectAppCheckProviders(
      isWeb: false,
      isDebug: true,
      webRecaptchaSiteKey: '',
    );
    final releaseProviders = selectAppCheckProviders(
      isWeb: false,
      isDebug: false,
      webRecaptchaSiteKey: '',
    );

    expect(debugProviders.androidProvider, AndroidProvider.debug);
    expect(releaseProviders.androidProvider, AndroidProvider.playIntegrity);
    expect(debugProviders.appleProvider, AppleProvider.debug);
    expect(releaseProviders.appleProvider, AppleProvider.deviceCheck);
    expect(debugProviders.webProvider, isNull);
    expect(releaseProviders.webProvider, isNull);
  });

  test('web release build stops when its site key is missing', () async {
    final tempDir = await Directory.systemTemp.createTemp('app-check-build-');
    addTearDown(() => tempDir.delete(recursive: true));

    final flutterBin = Directory('${tempDir.path}/bin');
    await flutterBin.create(recursive: true);
    final flutterStub = File('${flutterBin.path}/flutter');
    await flutterStub.writeAsString('''#!/usr/bin/env bash
if [[ "\$1" == "--version" ]]; then
  echo "Flutter 3.44.4"
elif [[ "\$1" == "config" ]]; then
  exit 0
else
  echo "Unexpected Flutter command: \$*" >&2
  exit 42
fi
''');
    await Process.run('chmod', ['+x', flutterStub.path]);

    final environment = Map<String, String>.from(Platform.environment)
      ..['RECAPTCHA_SITE_KEY'] = ''
      ..['FLUTTER_HOME'] = tempDir.path;
    final result = await Process.run(
      'bash',
      ['tool/replit/build_web.sh'],
      environment: environment,
    );
    final output = '${result.stdout}\n${result.stderr}';

    expect(result.exitCode, isNot(0), reason: output);
    expect(output, contains('RECAPTCHA_SITE_KEY is required'));
    expect(output, isNot(contains('Unexpected Flutter command')));
  });
}
