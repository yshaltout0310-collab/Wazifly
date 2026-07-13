# Google Sign-In — Setup & Fix Runbook

> **Symptom:** tapping *Continue with Google* fails with an error.
>
> **Root cause (verified):** the Firebase project has **no OAuth client configured
> and no SHA-1 fingerprint registered**. `android/app/google-services.json`
> currently contains an **empty `oauth_client: []`**. The app signs in with
> Firebase's federated flow — `FirebaseAuth.signInWithProvider(GoogleAuthProvider())`
> (`lib/features/auth/data/firebase_auth_repository.dart`) — which needs a Web
> OAuth client (and, for the best native experience, an Android OAuth client tied
> to the app's SHA-1). Without them the OAuth handshake can't complete.
>
> This is **backend configuration**, not an app-code bug. The app change shipped
> alongside this doc only improves the *error message* (see “Code change” below);
> the steps here are what actually enable Google sign-in. They must be done by the
> project owner in the Firebase / Google Cloud console.

---

## 0. App fingerprints (already extracted for you)

| Keystore | SHA-1 | SHA-256 |
| --- | --- | --- |
| **Debug** (`~/.android/debug.keystore`, used by `flutter run` and unsigned release builds) | `22:A0:28:94:08:22:D9:E4:03:8A:3F:F1:DA:F1:F2:D4:42:FF:82:CE` | `F5:42:E5:81:43:AC:FF:A7:B7:24:31:35:90:94:B9:89:BB:E3:63:C5:7D:3B:8A:E5:C6:4D:8B:3F:CD:A7:1B:87` |
| **Release / upload** | *(generate after minting the upload keystore — see [RELEASE.md](RELEASE.md) §3)* | *(same)* |

Re-extract any time with:
```bash
keytool -list -v -keystore ~/.android/debug.keystore \
  -alias androiddebugkey -storepass android -keypass android | grep "SHA"
```
> ⚠️ The debug SHA-1 above is specific to **this machine's** debug keystore. Each
> developer/CI machine has a different one — register every debug SHA-1 that needs
> to test Google sign-in. When you enroll in **Play App Signing**, also register
> the **App signing SHA-1** shown in the Play Console.

App package: **`com.careerbridge.careerbridge`** · Firebase project:
**`careerbridge-97-f58c9`** (number `894890748117`).

---

## 1. Enable the Google provider (Firebase Console → Authentication)

1. Firebase Console → **Authentication → Sign-in method**.
2. **Add / enable “Google”.** Set a support email. Save.
   - This automatically creates the **Web OAuth client** (`client_type: 3`) the
     federated `signInWithProvider` flow hands off to.

## 2. Register the SHA-1 / SHA-256 fingerprints (Project settings)

1. Firebase Console → **Project settings → General → Your apps → the Android app**
   (`com.careerbridge.careerbridge`).
2. **Add fingerprint** → paste the **debug SHA-1** from §0. Add the **SHA-256** too
   (needed for App Check Play Integrity later — see RELEASE.md §7.1).
3. Later, add the **release/upload SHA-1** and the **Play App Signing SHA-1** the
   same way, before shipping.

## 3. Refresh `google-services.json`

1. Still in **Project settings → the Android app**, click
   **Download `google-services.json`**.
2. Replace `android/app/google-services.json` with the new file (it is gitignored).
3. **Verify** it now has a non-empty `oauth_client` (a `client_type: 3` web entry;
   ideally a `client_type: 1` Android entry carrying your `certificate_hash`):
   ```bash
   grep -c '"client_type"' android/app/google-services.json   # should be > 0
   ```
   *(Alternatively `flutterfire configure` regenerates it in place.)*

## 4. Confirm the OAuth redirect handler is reachable

The Custom-Tab flow returns to
`https://careerbridge-97-f58c9.firebaseapp.com/__/auth/handler`. This is provisioned
automatically with Firebase Auth; if you use a custom domain, add it under
**Authentication → Settings → Authorized domains**.

## 5. Rebuild & verify (real device recommended)

```bash
flutter clean && flutter pub get
flutter run           # debug build uses the debug SHA-1 registered in §2
```
Tap **Continue with Google** → the Google account chooser opens in a Custom Tab →
pick an account → returns signed in. Verify on a **real Android device with Google
Play services** (the flow can be flaky on bare emulators without Play services).

> If it still fails, read the message: with this milestone's code change, a
> configuration/OAuth failure now shows *“Google sign-in isn't fully set up
> yet…”* (was the generic *“Something went wrong.”*). Check `flutter logs` /
> logcat for the underlying `FirebaseAuthException` code and confirm §1–§3.

---

## Code change shipped with this doc (diagnostics only)

`lib/features/auth/domain/auth_exception.dart` now maps the Firebase codes a
misconfigured federated sign-in typically returns (`internal-error`,
`admin-restricted-operation`, `app-not-authorized`, `invalid-oauth-client-id`,
`invalid-oauth-provider`, `missing-client-identifier`, `unauthorized-domain`) to a
new `AuthErrorCode.configurationError`, surfaced via `errConfiguration`
(EN/AR) instead of the opaque generic error. This does **not** fix sign-in — only
makes the failure legible until §1–§3 are done.

## Optional: native `google_sign_in` plugin

The current federated `signInWithProvider` approach is intentional (no extra
dependency). If a fully native account picker is preferred later, add the
`google_sign_in` plugin and switch to
`GoogleAuthProvider.credential(idToken:, accessToken:)` +
`signInWithCredential`. It still requires the same §1–§3 OAuth-client / SHA-1
setup, so complete this runbook first regardless.
