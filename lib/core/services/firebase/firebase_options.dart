// PLACEHOLDER Firebase configuration — FlutterFire-compatible shape.
//
// Generate the real file with:
//   dart pub global activate flutterfire_cli
//   flutterfire configure
//
// That command OVERWRITES this file with real per-platform options (and adds
// google-services.json / GoogleService-Info.plist + the Gradle plugin).
//
// Until then, every platform returns a placeholder whose apiKey equals
// `kFirebasePlaceholderApiKey`. `FirebaseService` detects that sentinel and
// skips initialization, so the app still launches without a backend.
import 'package:firebase_core/firebase_core.dart';

/// Sentinel apiKey marking an unconfigured project. Lives here (not in the
/// service) only so it's obvious in the placeholder; the service hardcodes the
/// same literal so detection survives a FlutterFire overwrite.
const String kFirebasePlaceholderApiKey = 'REPLACE_WITH_FIREBASE_CONFIG';

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
  DefaultFirebaseOptions._();

  static FirebaseOptions get currentPlatform => _placeholder;

  static const FirebaseOptions _placeholder = FirebaseOptions(
    apiKey: kFirebasePlaceholderApiKey,
    appId: '1:000000000000:android:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'careerbridge-unconfigured',
    storageBucket: 'careerbridge-unconfigured.appspot.com',
  );
}
