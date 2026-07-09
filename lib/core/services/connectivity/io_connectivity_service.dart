import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'connectivity_service.dart';
import 'noop_connectivity_service.dart';

/// `dart:io`-based [ConnectivityService] — polls reachability with a short DNS
/// lookup and emits only on change. No native plugin.
///
/// Best-effort: any lookup error is treated as "offline" (advisory), and the
/// poll loop can never throw into the app. The probe is injectable so tests stay
/// deterministic without touching the network.
class IoConnectivityService implements ConnectivityService {
  IoConnectivityService({
    Duration interval = const Duration(seconds: 8),
    Duration timeout = const Duration(seconds: 4),
    Future<bool> Function()? probe,
  })  : _interval = interval,
        _timeout = timeout,
        _probe = probe;

  final Duration _interval;
  final Duration _timeout;
  final Future<bool> Function()? _probe;

  /// A well-known, always-on host (the Firestore endpoint the app already talks
  /// to). Only DNS resolution is needed — no data is sent.
  static const String _host = 'firestore.googleapis.com';

  @override
  Future<ConnectivityStatus> check() async {
    final online = await _reachable();
    return online ? ConnectivityStatus.online : ConnectivityStatus.offline;
  }

  @override
  Stream<ConnectivityStatus> watch() {
    late final StreamController<ConnectivityStatus> controller;
    Timer? timer;
    ConnectivityStatus? last;

    Future<void> tick() async {
      final status = await check();
      if (status != last) {
        last = status;
        if (!controller.isClosed) controller.add(status);
      }
    }

    controller = StreamController<ConnectivityStatus>(
      onListen: () {
        tick(); // emit the first observed status ASAP
        timer = Timer.periodic(_interval, (_) => tick());
      },
      onCancel: () {
        timer?.cancel();
        timer = null;
      },
    );
    return controller.stream;
  }

  Future<bool> _reachable() async {
    try {
      if (_probe != null) return await _probe();
      final result =
          await InternetAddress.lookup(_host).timeout(_timeout);
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (e) {
      debugPrint('[Connectivity] lookup failed (treating as offline): $e');
      return false;
    }
  }
}

/// The app-wide connectivity service. `dart:io` polling on mobile/desktop; an
/// always-online no-op on platforms where the lookup isn't meaningful (web) or
/// in tests. Rebind to change the backend.
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  if (kIsWeb) return const NoopConnectivityService();
  return IoConnectivityService();
});

/// Reactive reachability for the UI (the offline banner). Seeds `online` so the
/// first frame never flashes an offline state before the first probe resolves.
final connectivityStatusProvider = StreamProvider<ConnectivityStatus>((ref) {
  return ref.watch(connectivityServiceProvider).watch();
});
