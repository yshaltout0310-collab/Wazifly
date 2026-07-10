import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'flutter_secure_store.dart';
import 'secure_store.dart';

/// The production [SecureStore] (OS-backed). Overridden in tests with an
/// in-memory impl; this is the single swap point.
final secureStoreProvider = Provider<SecureStore>((ref) => FlutterSecureStore());
