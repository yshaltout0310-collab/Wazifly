import 'package:careerbridge/core/localization/generated/app_localizations.dart';
import 'package:careerbridge/core/services/connectivity/connectivity_service.dart';
import 'package:careerbridge/core/services/connectivity/io_connectivity_service.dart';
import 'package:careerbridge/shared/widgets/offline_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app({required ConnectivityStatus status, required Locale locale}) {
  return ProviderScope(
    overrides: [
      connectivityStatusProvider.overrideWith((ref) => Stream.value(status)),
    ],
    child: MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: const OfflineBanner(
        child: Scaffold(body: Center(child: Text('content'))),
      ),
    ),
  );
}

void main() {
  testWidgets('shows the offline bar when offline (EN)', (tester) async {
    await tester.pumpWidget(
        _app(status: ConnectivityStatus.offline, locale: const Locale('en')));
    await tester.pumpAndSettle();
    expect(find.text("You're offline — showing saved data"), findsOneWidget);
    expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
    expect(find.text('content'), findsOneWidget); // app content still shown
  });

  testWidgets('hides the offline bar when online', (tester) async {
    await tester.pumpWidget(
        _app(status: ConnectivityStatus.online, locale: const Locale('en')));
    await tester.pumpAndSettle();
    expect(find.text("You're offline — showing saved data"), findsNothing);
    expect(find.byIcon(Icons.wifi_off_rounded), findsNothing);
  });

  testWidgets('shows the localized Arabic message when offline (RTL)',
      (tester) async {
    await tester.pumpWidget(
        _app(status: ConnectivityStatus.offline, locale: const Locale('ar')));
    await tester.pumpAndSettle();
    expect(find.textContaining('غير متصل'), findsOneWidget);
  });
}
