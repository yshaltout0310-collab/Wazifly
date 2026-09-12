# Wazifly — Replit Deployment

> **What this deploys:** the **Flutter web** build of Wazifly, as a Replit
> **static deployment**. Wazifly is a client-side app that talks to Firebase
> directly, so there is no server to run — the deployment is a folder of static
> files plus a CDN.
>
> Android/iOS are unaffected: the same source still builds the mobile artifacts
> exactly as described in [`RELEASE.md`](RELEASE.md). Replit is an *additional*
> distribution channel, useful for demos and review because it needs no install.

---

## 1. What is in the repo for this

| File | Role |
| --- | --- |
| `.replit` | Run command, `$PORT` mapping, and the **static** deployment definition (`build/web` as `publicDir`). |
| `replit.nix` | System packages only (curl, tar, xz, git, unzip, python3). Deliberately **no** `pkgs.flutter` — see §2. |
| `tool/replit/install_flutter.sh` | Installs a **pinned** Flutter SDK into `~/flutter`. Idempotent. |
| `tool/replit/build_web.sh` | `pub get` + `flutter build web --release` → `build/web`. This is the deployment build command. |
| `tool/replit/serve_web.sh` | The Run button: builds if needed, then serves `build/web` on `$PORT`. |

---

## 2. Why the SDK is downloaded rather than taken from Nix

`pubspec.yaml` requires **Flutter ≥ 3.27 / Dart ≥ 3.6**. The nixpkgs channels
Replit pins ship an older Flutter, so `pkgs.flutter` fails `pub get` outright.
`install_flutter.sh` pins the exact SDK the app is verified against
(**3.44.4**, overridable with the `FLUTTER_VERSION` env var) and installs it
into the Repl's persistent home, so it is downloaded once and then reused. Bump
the version in that script when the project moves.

---

## 3. One-time setup

1. **Create the Repl** — *Create Repl → Import from GitHub* and point it at this
   repository, branch `feature/wazifly-rebrand`. Replit picks up `.replit` and
   `replit.nix` automatically.
2. **No secrets to add.** The app ships no API keys: Gemini is reached through
   Firebase AI Logic, authenticated by the Firebase app rather than by a key in
   the client. Firebase's own web client config is public by design and lives in
   `lib/core/services/firebase/firebase_options.dart`.
   *`android/app/google-services.json` is gitignored and therefore absent from a
   clone — that only affects Android builds, not this web deployment.*
3. **Press Run.** The first run downloads the SDK and builds (≈5–10 min on a
   cold Repl); later runs reuse both and start in seconds.

---

## 4. Deploying

*Deploy → Static* (the settings are already filled in from `.replit`):

| Setting | Value |
| --- | --- |
| Build command | `bash tool/replit/build_web.sh` |
| Public directory | `build/web` |

Deploy, then open the assigned `*.replit.app` URL.

Static hosting is sufficient because the app uses Flutter's **default
hash-based URL strategy** (`https://…/#/home`): every route is served by
`index.html` already, so no SPA rewrite rule is required.

---

## 5. Firebase console steps for the deployed domain

These are **console-side** and cannot be done from the repository.

1. **Authorized domains** — Firebase Console → *Authentication → Settings →
   Authorized domains* → add the deployed host (`<your-repl>.replit.app`, plus
   `<your-repl>.replit.dev` if you also share the dev preview). Required for any
   OAuth/reCAPTCHA flow and for email action links that should return to your
   own domain.
2. **API key referrer restrictions** — if the web API key has HTTP-referrer
   restrictions in Google Cloud Console → *APIs & Services → Credentials*, add
   the Replit host there too. With no restrictions set, nothing is needed.
3. **App Check (important).** Enforcement is currently **off**, and the web
   build logs a harmless `[AppCheck] activate failed` because no web attestation
   provider is registered. If App Check enforcement is ever switched on,
   **this web deployment will be denied Firestore/Storage/AI access** until a
   **reCAPTCHA v3 (or Enterprise) provider** is registered for the web app and
   activated in the client. Treat "enforce App Check" and "keep the web build
   working" as one change, not two.

---

## 6. How the web build behaves differently from Android

Everything degrades on its own — none of the following blocks the app — but a
reviewer should know what they are looking at.

| Capability | On web | Why |
| --- | --- | --- |
| Auth, Firestore, Storage, Analytics, Gemini (AI features) | ✅ Work | The Firebase JS SDK is loaded automatically and `firebase_options.dart` carries the web config. |
| **Biometric app-lock** | Silently absent | `local_auth` has no web implementation, so `biometricServiceProvider` binds the no-op service on web and the feature never appears. |
| **Crashlytics** | Not reported | `firebase_crashlytics` has no web plugin. Calls are caught and logged; telemetry is best-effort by design. |
| **Push notifications** | Denied / off | FCM on web needs a service worker plus a VAPID key, neither of which is configured. Initialization fails softly. |
| **App Check** | Unattested | No web provider registered — see §5.3. |
| **Offline banner** | Never shows | The connectivity probe is `dart:io`-based, so web binds the always-online no-op. |
| PDF export / résumé upload | ✅ Work | `pdf`, `printing` and `file_selector` all have web implementations. |

---

## 7. Performance notes

- The release bundle is ~**46 MB** on disk, of which `main.dart.js` is ~**6.1 MB**
  (roughly 1.5–2 MB over the wire once the CDN gzips it). First load on a cold
  cache is a few seconds; subsequent loads are served from cache.
- `build_web.sh` passes **`--no-web-resources-cdn`**, which copies CanvasKit into
  the bundle instead of fetching it from `gstatic.com` at runtime. That trades
  ~10 MB of bundle for a self-contained site that still renders behind a
  restrictive network. Drop the flag if you would rather have the smaller bundle.
- Flutter web renders into a canvas, so the page is **not** text-selectable or
  SEO-indexable. That is inherent to the framework, not a configuration mistake.

---

## 8. Troubleshooting

| Symptom | Cause / fix |
| --- | --- |
| `Because careerbridge requires SDK version >=3.27.0…` | The Repl picked up a Nix Flutter. Confirm `which flutter` resolves under `/home/runner/flutter/bin` and that `.replit`'s `[env] PATH` survived any manual edit. |
| `detected dubious ownership in repository` | The `git config --global --add safe.directory` line in `install_flutter.sh` did not run. Run that script directly. |
| Build fails with a stale pub cache | `rm -rf ~/.pub-cache .dart_tool && bash tool/replit/build_web.sh`. |
| Blank navy page, no error | The bundle is still downloading. Check the browser console — a successful boot logs `[FirebaseService] Initialized: careerbridge-97-f58c9`. |
| `auth/unauthorized-domain` | §5.1 — add the Replit host to Firebase authorized domains. |
| Firestore reads return permission-denied only on web | Check whether App Check enforcement was enabled (§5.3). |

---

## 9. Verification performed

The web target was built and run from this branch before these files were
written, so the configuration reflects observed behaviour rather than
assumption:

| Check | Result |
| --- | --- |
| `flutter build web --release` | ✅ succeeds (after the web-compatibility fix recorded in [`TECHNICAL_AUDIT.md`](TECHNICAL_AUDIT.md) §4.1) |
| Bundle served and loaded in a browser | ✅ boots to the Language screen; `[FirebaseService] Initialized: careerbridge-97-f58c9` |
| Pre-auth flow (Language → Country → Onboarding → Welcome) | ✅ renders correctly, EN + AR listed, Wazifly branding intact |
| Failure modes of Crashlytics / FCM / App Check on web | ✅ all caught and logged; none blocks startup |
