import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/localization/generated/app_localizations.dart';
import 'core/localization/locale_controller.dart';
import 'core/navigation/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'shared/widgets/offline_banner.dart';

/// Root widget.
///
/// Wires the router, the light/dark themes, the active theme mode, and the
/// localization stack. Theme and locale both come from persisted Riverpod
/// controllers, so user choices are honored from the very first frame. The
/// [router] is built once in `main()` (with the analytics screen-view observer
/// attached) so it stays stable across rebuilds.
class WaziflyApp extends ConsumerWidget {
  const WaziflyApp({super.key, this.router});

  /// The app router. When null (e.g. tests), a fresh default router is built.
  final GoRouter? router;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeControllerProvider);
    final locale = ref.watch(localeControllerProvider);

    // Font selection is locale-aware, so build themes against the active
    // locale (falling back to English when following the device locale).
    final themeLocale = locale ?? const Locale('en');

    return MaterialApp.router(
      title: 'Wazifly',
      debugShowCheckedModeBanner: false,
      routerConfig: router ?? AppRouter.create(),

      // --- Theming ---
      theme: AppTheme.light(themeLocale),
      darkTheme: AppTheme.dark(themeLocale),
      themeMode: themeMode,

      // --- Localization (RTL/LTR handled automatically per locale) ---
      locale: locale,
      supportedLocales: supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // Ambient, app-wide offline indicator (advisory only — never gates a
      // feature). Wrapping via builder keeps it decoupled from every screen.
      builder: (context, child) =>
          OfflineBanner(child: child ?? const SizedBox.shrink()),
    );
  }
}
