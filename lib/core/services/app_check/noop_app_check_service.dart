import 'app_check_service.dart';

/// Inert [AppCheckService] for tests, unconfigured runs, and platforms without
/// App Check — activation is a no-op "success" (nothing to attest) and tokens
/// are null. Never touches the plugin.
class NoopAppCheckService implements AppCheckService {
  const NoopAppCheckService();

  @override
  Future<bool> activate() async => true;

  @override
  Future<String?> getToken({bool forceRefresh = false}) async => null;
}
