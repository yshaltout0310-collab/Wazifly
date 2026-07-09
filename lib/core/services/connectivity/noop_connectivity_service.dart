import 'connectivity_service.dart';

/// Always-online [ConnectivityService] for tests, web, and unconfigured runs —
/// never probes the network, so widget tests stay deterministic and offline.
class NoopConnectivityService implements ConnectivityService {
  const NoopConnectivityService();

  @override
  Future<ConnectivityStatus> check() async => ConnectivityStatus.online;

  @override
  Stream<ConnectivityStatus> watch() =>
      Stream<ConnectivityStatus>.value(ConnectivityStatus.online);
}
