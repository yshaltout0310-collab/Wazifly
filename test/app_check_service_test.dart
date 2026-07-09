import 'package:careerbridge/core/services/app_check/app_check_service.dart';
import 'package:careerbridge/core/services/app_check/noop_app_check_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('NoopAppCheckService activates as a no-op and yields no token', () async {
    const AppCheckService service = NoopAppCheckService();

    // Activation "succeeds" (nothing to attest) so the bootstrap never records a
    // failure in unconfigured runs / tests.
    expect(await service.activate(), isTrue);
    expect(await service.getToken(), isNull);
    expect(await service.getToken(forceRefresh: true), isNull);
  });
}
