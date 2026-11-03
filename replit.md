# Replit setup

## Run the Flutter Web app

The Replit Run workflow uses the checked-in Flutter Web scripts:

```bash
PORT=5000 bash tool/replit/serve_web.sh
```

The first run installs the pinned Flutter SDK (3.44.4) into
`/home/runner/flutter`, fetches Dart packages, builds the release web bundle, and
serves `build/web` on port 5000. Later starts reuse the SDK and existing bundle.

To rebuild after source changes:

```bash
bash tool/replit/build_web.sh
```

The app uses Firebase directly from the browser. Firebase web configuration is
already included in the project; sign-in and OAuth flows require the Replit
preview or deployment host to be added to Firebase Authentication's authorized
domains.

On web, App Check uses reCAPTCHA Enterprise when `RECAPTCHA_SITE_KEY` is
available to the build. The checked-in build script passes this value as a
Dart define. Crashlytics, biometrics, and push notifications remain
best-effort features with platform limitations; they do not block the first
frame or prevent the main app from loading.

Android debug builds use the App Check debug provider; Android release builds
use Play Integrity. Do not disable App Check enforcement to work around a
provider configuration issue.