import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/generated/app_localizations.dart';
import '../../core/services/connectivity/io_connectivity_service.dart';
import '../../core/services/connectivity/connectivity_service.dart';
import '../../core/theme/app_colors.dart';

/// Wraps the app and shows a slim, localized offline bar at the bottom whenever
/// connectivity drops — an **ambient, advisory** signal only. It never gates a
/// feature; data still comes from the Firestore offline cache and features keep
/// their own graceful network errors.
///
/// Placed once in `MaterialApp.builder`, so it's app-wide with zero
/// feature-to-feature coupling. RTL-safe (Row + Directionality) and animated so
/// it appears/disappears smoothly.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offline = ref.watch(connectivityStatusProvider).valueOrNull ==
        ConnectivityStatus.offline;

    return Column(
      children: [
        Expanded(child: child),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          child: offline
              ? const _OfflineBar()
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

class _OfflineBar extends StatelessWidget {
  const _OfflineBar();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // A live region so a screen reader announces the connectivity change when
    // the bar appears; the decorative icon is excluded so only the message is
    // read.
    return Semantics(
      liveRegion: true,
      container: true,
      label: l10n.offlineBannerMessage,
      child: Material(
        color: AppColors.darkBackground,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.wifi_off_rounded,
                    size: 18, color: AppColors.white),
                const SizedBox(width: 8),
                Flexible(
                  child: ExcludeSemantics(
                    child: Text(
                      l10n.offlineBannerMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
