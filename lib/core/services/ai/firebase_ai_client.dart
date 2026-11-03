import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

/// The **single attested entry point** to Firebase AI Logic.
///
/// `FirebaseAI.googleAI()` takes `appCheck` as an *optional* parameter and
/// silently sends no `X-Firebase-AppCheck` header when it is omitted (see
/// `BaseModel.firebaseTokens`, which only adds the header `if (appCheck !=
/// null)`). Since App Check enforcement became mandatory for Firebase AI Logic,
/// an omitted `appCheck` makes every request unattested and the backend rejects
/// it with `ServerException: Firebase App Check token is invalid.` — which looks
/// like a Console/configuration fault but is purely client-side.
///
/// Two further reasons every call site must go through this function rather
/// than calling `FirebaseAI.googleAI()` directly:
///
///  * `FirebaseAI` caches one instance per `'<appName>::googleai'` key, so the
///    **first** call wins. A single unattested call site anywhere would poison
///    the cache for the whole process, including the attested ones.
///  * Attestation then applies uniformly to every AI feature (analysis, job
///    matching, coach, interview prep, employer tools) and to the multimodal
///    PDF OCR path, which is a separate call site.
///
/// `firebase_ai` requires the plugin's own `FirebaseAppCheck` object (it calls
/// `getToken()` on it), so the vendor-neutral `AppCheckService` seam cannot be
/// used here; this file is therefore the second — and only other — place that
/// imports `firebase_app_check`. Attestation itself is still activated once, in
/// the app bootstrap, through that seam.
FirebaseAI attestedGoogleAi() =>
    FirebaseAI.googleAI(appCheck: FirebaseAppCheck.instance);
