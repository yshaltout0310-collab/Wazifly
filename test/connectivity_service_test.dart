import 'package:careerbridge/core/services/connectivity/connectivity_service.dart';
import 'package:careerbridge/core/services/connectivity/io_connectivity_service.dart';
import 'package:careerbridge/core/services/connectivity/noop_connectivity_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('NoopConnectivityService is always online', () async {
    const s = NoopConnectivityService();
    expect(await s.check(), ConnectivityStatus.online);
    expect(await s.watch().first, ConnectivityStatus.online);
  });

  test('IoConnectivityService maps the probe result', () async {
    final online = IoConnectivityService(probe: () async => true);
    expect(await online.check(), ConnectivityStatus.online);

    final offline = IoConnectivityService(probe: () async => false);
    expect(await offline.check(), ConnectivityStatus.offline);
  });

  test('a throwing probe is treated as offline (never rethrows)', () async {
    final s = IoConnectivityService(probe: () async => throw Exception('boom'));
    expect(await s.check(), ConnectivityStatus.offline);
  });

  test('watch emits the first observed status immediately', () async {
    final s = IoConnectivityService(
      interval: const Duration(seconds: 30),
      probe: () async => false,
    );
    expect(await s.watch().first, ConnectivityStatus.offline);
  });
}
