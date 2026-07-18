import 'package:careerbridge/app.dart';
import 'package:careerbridge/core/providers/app_providers.dart';
import 'package:careerbridge/core/services/connectivity/io_connectivity_service.dart';
import 'package:careerbridge/core/services/connectivity/noop_connectivity_service.dart';
import 'package:careerbridge/core/services/storage/local_storage_service.dart';
import 'package:careerbridge/features/splash/presentation/splash_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_auth.dart';

/// Smoke test: the app builds, shows the splash, then routes onward without
/// throwing. Validates the bootstrap wiring (storage override + router + theme).
void main() {
  testWidgets('App boots to splash, then navigates onward', (tester) async {
    // Avoid network font fetches (and their timers) inside the test harness.
    GoogleFonts.config.allowRuntimeFetching = false;

    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorageService.create();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageProvider.overrideWithValue(storage),
          fakeAuthOverride(),
          // The real connectivity service polls with a periodic timer that
          // would linger past the test; the app-wide OfflineBanner only needs an
          // inert, always-online status here.
          connectivityServiceProvider
              .overrideWithValue(const NoopConnectivityService()),
        ],
        child: const WaziflyApp(),
      ),
    );

    // First frame is the splash screen.
    expect(find.byType(SplashScreen), findsOneWidget);

    // Fire the splash's delayed navigation, then advance through the route
    // transition. We pump fixed durations (not pumpAndSettle) because hero
    // screens run looping aurora animations that never "settle".
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 600));

    // A fresh user (no persisted state) is routed off the splash into the
    // welcome flow.
    expect(find.byType(SplashScreen), findsNothing);
  });
}
