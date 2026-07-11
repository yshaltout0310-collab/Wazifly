# Career Bridge — Release Runbook

> **Goal:** someone unfamiliar with the project can build and publish the app
> using **only this document**. It covers prerequisites, one-time setup, signing,
> branding, building, the manual production console steps, Play Store upload,
> validation, and rollback.

Career Bridge is a Flutter (Android-first) app. This runbook targets the
**Android** release; the iOS pipeline is prepared (icons/splash configs target
iOS) but not covered here.

---

## 0. Project facts

| Item | Value |
| --- | --- |
| App name | Career Bridge |
| Android `applicationId` / package | `com.careerbridge.careerbridge` |
| Firebase project | `careerbridge-97-f58c9` (project number `894890748117`) |
| Flutter | 3.44.4 stable · Dart `>=3.6.0 <4.0.0` · `flutter >=3.27.0` |
| `minSdk` | 23 (Firebase Auth requirement) · `targetSdk`/`compileSdk` from Flutter |
| Version | `pubspec.yaml` → `version: <name>+<code>` (e.g. `1.0.0+1`) |
| Store artifact | Android App Bundle (`.aab`) |

---

## 1. Prerequisites (tools)

1. **Flutter SDK** 3.27+ (3.44.4 used). Verify: `flutter --version`, then `flutter doctor`.
2. **Android toolchain** — Android Studio / command-line SDK, a JDK 17, and platform tools on PATH (or via Android Studio). `flutter doctor` must show Android toolchain ✓.
3. **Firebase CLI** (for rules/console tasks) — `npm i -g firebase-tools`, then `firebase login`.
4. **`keytool`** — ships with the JDK (used to create the signing keystore).
5. Git.

---

## 2. One-time project setup

```bash
git clone <repo> && cd CareerBridge
flutter pub get
```

### 2.1 Firebase config (required to build)
- `lib/core/services/firebase/firebase_options.dart` is **committed** (client
  identifiers, not secrets).
- `android/app/google-services.json` is **gitignored** and must be present
  locally. Obtain it by running **`flutterfire configure`** (recommended — it
  regenerates both files in place) or by downloading it from the Firebase
  Console → Project settings → your Android app.

### 2.2 Fonts & branding assets
- Fonts (Inter, Cairo) are **bundled** at `assets/fonts/*.ttf` and committed — no
  action needed. (They are OFL-licensed; see §9.)
- Launcher-icon and splash **source** images live at `assets/icon/*.png` (1024²).
  The generated native resources are committed; regenerate only if a source
  changes (§4).

---

## 3. Signing (one-time, per release identity)

The release build reads signing config from **`android/key.properties`** (which
is **gitignored**). When that file is absent, the build falls back to **debug
signing** so dev/CI builds still run — but the Play Store requires a real
release key.

### 3.1 Generate an upload keystore
Keep the `.jks` file **outside** the repo (e.g. `~/keys/`):

```bash
keytool -genkey -v \
  -keystore /ABSOLUTE/PATH/careerbridge-upload.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```
Answer the prompts (name/org/etc.) and **record the store + key passwords in a
password manager** — losing them means you can never update the app (unless you
enrolled in Play App Signing, which is recommended — see §7).

### 3.2 Create `android/key.properties`
Copy the template and fill in real values:

```bash
cp android/key.properties.example android/key.properties
```
```properties
keyAlias=upload
keyPassword=<the key password>
storeFile=/ABSOLUTE/PATH/careerbridge-upload.jks
storePassword=<the store password>
```
`android/key.properties` and `*.jks` are already in `.gitignore` — **never commit
them.**

---

## 4. Branding (regenerate only when a source image changes)

Sources: `assets/icon/app_icon.png`, `ic_background.png`, `ic_foreground.png`,
`splash_logo.png` (all 1024²). Brand colors: emerald `#0E9F6E` (icon bg),
`#0B7D57` (splash), dark `#101413` — must match `lib/core/theme/app_colors.dart`.

```bash
dart run flutter_launcher_icons      # launcher + adaptive icons (all densities)
dart run flutter_native_splash:create # native splash incl. Android 12+
```
Then review `git diff android/app/src/main/res/**` and commit intentionally.

---

## 5. Versioning

- Edit `pubspec.yaml` → `version: <marketing>+<buildCode>` (e.g. `1.1.0+3`).
  `flutter.versionName`/`flutter.versionCode` flow into Gradle automatically.
- Every Play upload needs a **strictly higher** `+<buildCode>`.
- **Also pass the version to the app's `BuildInfo`** (used in crash reports / a
  future About screen) via `--dart-define` so it matches the store build:

```bash
--dart-define=APP_VERSION=1.1.0 --dart-define=BUILD_NUMBER=3
```
(Defaults are `1.0.0` / `1` if omitted — the app still runs.)

---

## 6. Building

Always `flutter clean && flutter pub get` before a release build if the toolchain
or deps changed.

```bash
# Play Store artifact (recommended):
flutter build appbundle --release \
  --dart-define=APP_VERSION=1.1.0 --dart-define=BUILD_NUMBER=3
# -> build/app/outputs/bundle/release/app-release.aab

# Universal APK (sideload / QA):
flutter build apk --release \
  --dart-define=APP_VERSION=1.1.0 --dart-define=BUILD_NUMBER=3
# -> build/app/outputs/flutter-apk/app-release.apk

# Smaller per-ABI APKs (optional, for direct distribution):
flutter build apk --release --split-per-abi
```

**R8/minify:** enabled for release (`isMinifyEnabled`, `isShrinkResources` in
`android/app/build.gradle.kts`) with keep rules in
`android/app/proguard-rules.pro`. If a release build ever fails inside R8 (AGP 9
is bleeding-edge), the safe fallback is to set both flags to `false` and ship —
Dart is already tree-shaken, so the size cost is small. Document any such change.

---

## 7. Manual production console steps (cannot be scripted from the repo)

These are the **only** steps outside the codebase. The app runs correctly without
them (everything degrades gracefully), but a production release should complete
them.

### 7.1 Firebase App Check (security)
The app activates App Check on device (debug provider in debug, **Play Integrity**
in release). Currently the App Check API is **not enabled** and enforcement is
**off** (monitoring) — the app falls back to a placeholder token and stays usable.
To finish:
1. **Enable the API:** Firebase Console → **App Check** (or enable
   `firebaseappcheck.googleapis.com` in the Google Cloud API library).
2. **Register Play Integrity** for the release app (Console → App Check → your
   Android app → Play Integrity; provide the app's SHA-256).
3. **Debug devices:** each debug build prints a debug token in logcat
   (`DebugAppCheckProvider: Enter this debug secret …`). Add it under App Check →
   Manage debug tokens. **Never commit debug tokens** (they're per-install).
4. **Enforce** (only after real traffic shows tokens validating): App Check →
   enforce on Firestore / Storage / (AI Logic). Enforcing before 1–3 locks out
   all clients.

### 7.2 Cloud Storage bucket (media)
The default bucket is **not yet provisioned**, so photo/logo/résumé uploads
degrade to a localized error.
1. Console → **Storage → Get Started** (creates the default
   `.firebasestorage.app` bucket; may require the Blaze plan).
2. Deploy the hardened rules (already authored + gitignored-safe):
   ```bash
   firebase deploy --only storage --project careerbridge-97-f58c9
   ```

### 7.3 Firestore rules (data)
Already deployed. Re-deploy after any change:
```bash
firebase deploy --only firestore:rules --project careerbridge-97-f58c9
```

### 7.4 Crashlytics / Performance Gradle plugins (optional hardening)
The runtime SDKs work without them. Once AGP-9-compatible versions are confirmed,
add `com.google.firebase.crashlytics` + `com.google.firebase.firebase-perf`
Gradle plugins (unlocks release mapping-upload + auto HTTP/screen traces), and
**re-validate the release build immediately** (KGP/Gradle risk).

### 7.5 Firebase AI Logic (Gemini)
Already enabled/provisioned. If it regresses to "AI logic config is missing",
re-run Console → **AI Logic → Get started**.

### 7.6 Auth / SMS (only if phone auth is used in prod)
Console → Auth → Settings → **SMS region policy** (allow the target region) or add
a test phone number.

---

## 8. Publish to Google Play

1. **Play Console** → create the app (first time) with package
   `com.careerbridge.careerbridge`.
2. **Enroll in Play App Signing** (strongly recommended): Play manages the app
   signing key; you upload with your *upload* key (§3). This lets you recover a
   lost upload key.
3. **Create a release** (Internal testing → Closed → Production) and upload the
   `.aab` from §6.
4. Complete the required Play listing: store listing, content rating, data-safety
   form (declare Firebase Analytics/Crashlytics data collection + the analytics
   **consent** lever), target-audience, privacy policy URL.
5. Roll out (start with Internal/Closed testing; then staged Production rollout).

---

## 9. Third-party assets & licenses

- **Inter** (`assets/fonts/Inter.ttf`) and **Cairo** (`assets/fonts/Cairo.ttf`) —
  SIL **Open Font License 1.1** (bundled; redistribution permitted). Both are
  variable fonts; Flutter drives the weight axis from `TextStyle.fontWeight`.
- Fonts render **offline** (no runtime fetch); `google_fonts` runtime fetching is
  disabled as a guard in `main()`.

---

## 10. Reserved / generated assets (verification)

Every asset declared in `pubspec.yaml` is used or intentionally reserved:

| Declared | Status |
| --- | --- |
| `assets/data/seed_jobs.json` | **Used** — bundled seed jobs (`SeedJobsRepository`). |
| `assets/fonts/{Inter,Cairo}.ttf` | **Used** — bundled UI fonts (`pubspec fonts:`). |
| `assets/images/` | **Reserved** (empty, `.gitkeep`) — future in-app imagery. |
| `assets/icons/` | **Reserved** (empty, `.gitkeep`) — future in-app icon assets. |
| `assets/icon/*.png` (1024²) | **Generator sources** — inputs to
  `flutter_launcher_icons`/`flutter_native_splash`; not shipped in the app bundle. |

---

## 11. Release validation (automatable foundation)

Run these **in order** before every release. They are ordered/structured so a CI
script (e.g. a future `scripts/release_check.sh`) can run them 1:1 — no CI is set
up yet; this is the documented foundation.

| # | Step | Command | Pass criteria |
| --- | --- | --- | --- |
| 1 | Static analysis | `flutter analyze` | `No issues found!` |
| 2 | Tests | `flutter test` | all pass (**574** baseline; see HANDOFF for the current count) |
| 3 | Asset verification | `grep -roE "assets/[A-Za-z0-9_./-]+" lib/` vs `pubspec.yaml` | every declared asset used or reserved (§10) |
| 4 | Fonts present | (covered by `test/font_bundling_test.dart` in step 2) | Inter+Cairo load from the bundle |
| 5 | Manifest/permissions | (covered by `test/android_manifest_test.dart` in step 2) | only INTERNET/POST_NOTIFICATIONS/USE_BIOMETRIC; `AD_ID` removed |
| 6 | Release APK | `flutter build apk --release` | builds, R8 succeeds |
| 7 | Release AAB | `flutter build appbundle --release` | builds |
| 8 | AD_ID check (merged manifest) | inspect `build/app/intermediates/merged_manifest/release/.../AndroidManifest.xml` | **no** `com.google.android.gms.permission.AD_ID` |
| 9 | Install smoke | `adb install -r build/app/outputs/flutter-apk/app-release.apk` | launches, no crash |

> Automation note: steps 1, 2, 6, 7 are pure CLI and deterministic; step 3 is a
> simple diff; step 8 is a grep over the build output; step 9 needs a device/
> emulator. A `scripts/release_check.sh` that chains 1→8 and fails on the first
> non-zero exit is the intended next step.

---

## 12. Rollback

- **Bad release on Play:** halt the staged rollout in Play Console; promote the
  previous known-good `.aab` (Play keeps prior artifacts) or upload a hotfix with
  a higher `versionCode`.
- **App Check lockout:** if enforcement was turned on prematurely and clients are
  denied, **turn enforcement off** in the Console (immediate, reversible).
- **Rules regression:** re-deploy the previous `firestore.rules`/`storage.rules`
  from git history via `firebase deploy`.

---

## 13. Quick reference

```bash
flutter clean && flutter pub get
flutter analyze && flutter test
flutter build appbundle --release --dart-define=APP_VERSION=<v> --dart-define=BUILD_NUMBER=<n>
# upload build/app/outputs/bundle/release/app-release.aab to Play Console
```

See also: `docs/QA_CHECKLIST.md` (pre-release QA + accessibility) and
`HANDOFF.md` §5 (Firebase console state) / §7.19 (this milestone).
