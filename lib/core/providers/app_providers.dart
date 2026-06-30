import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/storage/local_storage_service.dart';

/// Global access point for the persistence layer.
///
/// Overridden in `main()` with the already-initialized instance so the rest of
/// the app can read it synchronously. Throwing here guarantees we never forget
/// to provide it.
final localStorageProvider = Provider<LocalStorageService>(
  (ref) => throw UnimplementedError(
    'localStorageProvider must be overridden in main() with the loaded instance.',
  ),
);
