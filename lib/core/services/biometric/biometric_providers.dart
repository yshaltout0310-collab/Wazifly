import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'biometric_service.dart';
import 'local_auth_biometric_service.dart';

/// The production [BiometricService] (`local_auth`). Overridden in tests with a
/// fake / Noop; this is the single swap point.
final biometricServiceProvider =
    Provider<BiometricService>((ref) => LocalAuthBiometricService());
