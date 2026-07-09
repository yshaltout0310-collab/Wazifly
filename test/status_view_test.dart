import 'package:careerbridge/core/localization/generated/app_localizations.dart';
import 'package:careerbridge/shared/widgets/status_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child, {Locale locale = const Locale('en')}) {
  return MaterialApp(
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('loading shows a spinner and a screen-reader "loading" label',
      (tester) async {
    await tester.pumpWidget(_host(const StatusView.loading(title: 'Working')));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Working'), findsOneWidget);
    // The spinner is announced via a Semantics label ("Loading…").
    expect(find.bySemanticsLabel('Loading…'), findsWidgets);
  });

  testWidgets('empty shows icon + title + message + a working action',
      (tester) async {
    var tapped = false;
    await tester.pumpWidget(_host(
      StatusView.empty(
        icon: Icons.inbox_outlined,
        title: 'Nothing here',
        message: 'Come back later',
        action: ElevatedButton(
          onPressed: () => tapped = true,
          child: const Text('Do it'),
        ),
      ),
    ));
    await tester.pump();
    expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
    expect(find.text('Nothing here'), findsOneWidget);
    expect(find.text('Come back later'), findsOneWidget);
    await tester.tap(find.text('Do it'));
    expect(tapped, isTrue);
  });

  testWidgets('error shows the message and retry invokes the callback',
      (tester) async {
    var retried = false;
    await tester.pumpWidget(_host(
      StatusView.error(
        message: 'Something failed',
        onRetry: () => retried = true,
      ),
    ));
    await tester.pump();
    expect(find.text('Something failed'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    // Default retry label is localized.
    expect(find.text('Try again'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pump();
    expect(retried, isTrue);
  });

  testWidgets('error uses a custom retry label when given', (tester) async {
    await tester.pumpWidget(_host(
      StatusView.error(
        message: 'x',
        retryLabel: 'Reload',
        onRetry: () {},
      ),
    ));
    await tester.pump();
    expect(find.text('Reload'), findsOneWidget);
    expect(find.text('Try again'), findsNothing);
  });

  testWidgets('renders localized defaults in Arabic', (tester) async {
    await tester.pumpWidget(_host(
      StatusView.error(message: 'خطأ', onRetry: () {}),
      locale: const Locale('ar'),
    ));
    await tester.pump();
    expect(find.text('إعادة المحاولة'), findsOneWidget); // commonRetry (AR)
  });
}
