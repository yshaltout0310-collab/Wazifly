# Career Bridge — Production Readiness Report

> **Purpose:** the single **evidence-backed Go/No-Go assessment** for shipping
> Career Bridge to Google Play. It records what has been **verified** in the
> codebase and build, and what remains a **manual pre-launch step** that cannot be
> automated from the repository (console configuration, hosting, credentials).
>
> This report is the **sign-off**; the **mechanics** live in — and are cross-linked,
> not duplicated from — [`RELEASE.md`](RELEASE.md) (build/sign/publish),
> [`store/RELEASE_CHECKLIST.md`](store/RELEASE_CHECKLIST.md) (ordered checklist),
> [`store/DATA_SAFETY.md`](store/DATA_SAFETY.md), [`store/PLAY_CONSOLE.md`](store/PLAY_CONSOLE.md),
> [`store/STORE_LISTING.md`](store/STORE_LISTING.md), and [`QA_CHECKLIST.md`](QA_CHECKLIST.md).
>
> Produced in **Phase 7 · Milestone 5 (Deployment & Publishing)**. The app is
> **code-complete and release-ready**; every open item below is an external,
> user-side action.

---

## 1. Final production status

Completed engineering work vs. the manual actions still owed before publishing:

| Area | Status | Notes |
| --- | --- | --- |
| **Release build (R8/AAB)** | ✅ Ready | `flutter analyze` clean · **574 tests** pass · release `.apk` (73.0 MB) + `.aab` (71.3 MB) build under R8. |
| **Google Play (paperwork)** | ✅ Ready | Store listing (EN + AR), Data Safety, Play Console declarations, screenshot specs all prepared and reconciled to the shipped app. |
| **Firebase (code/rules)** | ✅ Ready | Auth/Firestore/Analytics/Crashlytics/Performance/App Check/AI Logic all wired; `firestore.rules` deployed & re-audited (8 collections). |
| **Security** | ✅ Ready | Secrets gitignored & untracked; no hardcoded secrets; advertising ID (`AD_ID`) stripped from the artifact; only normal permissions. |
| **AI services** | ✅ Ready | Firebase AI Logic (Gemini) provisioned & live; AI-transparency disclosure consistent across listing, Privacy Policy, Terms. |
| **Monitoring** | ✅ Ready (code) | Analytics (consent-gated), Crashlytics, Performance SDKs live on device. *Optional:* Crashlytics/Perf Gradle plugins (release mapping upload) — see §8. |
| **Legal documents** | ⚠️ Manual hosting required | Privacy Policy + Terms are complete templates; must be **filled in, counsel-reviewed, and hosted at public URLs** before submission. |
| **Release signing** | ⚠️ Upload keystore required | Signing config is wired (debug fallback verified); the **real upload keystore + `android/key.properties`** must be created by the release owner. |
| **App Check** | ⚠️ Final console step | Activates on device (monitoring-only, graceful placeholder). Enable API → register Play Integrity → **enforce** after traffic validates. |
| **Cloud Storage** | ⚠️ Final console step | Default bucket not provisioned; hardened `storage.rules` authored but undeployed. Provision the bucket, then `firebase deploy --only storage`. |

**Legend:** ✅ Ready = done & verified in-repo · ⚠️ = a manual, non-automatable
pre-launch action (all degrade gracefully; **none blocks the app from running**).

---

## 2. Verification evidence (this milestone)

All commands run on the committed tree at Phase 7 · Milestone 5.

| Check | Command | Result |
| --- | --- | --- |
| Static analysis | `flutter analyze` | **No issues found!** |
| Tests | `flutter test` | **574 passed** (571 prior + 3 new manifest guards) |
| Release APK | `flutter build apk --release` | ✅ built, 73.0 MB, R8 on (only the known benign `firebase_analytics` KGP *warning*) |
| Release AAB | `flutter build appbundle --release` | ✅ built, 71.3 MB |
| AD_ID stripped | grep the merged release manifest | ✅ `com.google.android.gms.permission.AD_ID` **absent** (was present before the fix) |
| Permission surface | merged release manifest | ✅ `INTERNET`, `POST_NOTIFICATIONS`, `USE_BIOMETRIC` + only normal Firebase/Messaging/`local_auth` merges |

---

## 3. Release build

- **Config** (`android/app/build.gradle.kts`): `minSdk 23`, `targetSdk`/`compileSdk`
  from Flutter, `multiDexEnabled`, **R8 `isMinifyEnabled` + `isShrinkResources` on**
  for release with keep rules in `proguard-rules.pro`. ✅
- **Signing**: reads optional `android/key.properties` → real `release` signing;
  **falls back to debug signing** when absent so dev/CI/validation builds still run.
  Verified: the release artifacts build via the fallback path. The **real upload
  keystore is the release owner's to create** ([`RELEASE.md`](RELEASE.md) §3). ⚠️
- **Versioning strategy**: `pubspec.yaml` `version: <marketing>+<buildCode>`
  (currently **`1.0.0+1`** — correct for the first submission). Semantic marketing
  version; **`buildCode` strictly increases on every Play upload**. Pass matching
  `--dart-define=APP_VERSION`/`BUILD_NUMBER` so `BuildInfo`/crash reports agree with
  the store build ([`RELEASE.md`](RELEASE.md) §5). ✅
- **Build verification**: both `.apk` and `.aab` green under R8 (see §2). ✅

## 4. Firebase

| Service | State | Manual step? |
| --- | --- | --- |
| **Authentication** | Email/Password, Google, Phone enabled | — |
| **Firestore** | Hardened rules **deployed**; covers `users` (+`learning`), `companies`, `jobs`, `applications`, `applicationNotes`, `resumes`, `employerActivity` | — |
| **Storage** | Hardened rules authored; **bucket unprovisioned** | ⚠️ provision + `firebase deploy --only storage` |
| **App Check** | Activates on device; API off, **enforcement off** (graceful placeholder token) | ⚠️ enable API → Play Integrity → enforce |
| **Analytics** | SDK live; **consent-gated** | — |
| **Crashlytics** | SDK live | ⚠️ *optional* Gradle plugin (mapping upload) |
| **Performance** | SDK live | ⚠️ *optional* Gradle plugin (auto traces) |
| **AI Logic (Gemini)** | Provisioned & live | — |

## 5. Security review

- **Secrets & keys** — `google-services.json`, `android/key.properties`, `*.jks`
  are **gitignored and untracked**; `firebase_options.dart` is committed (client
  identifiers, not secrets); **no hardcoded secrets** in `lib/`; the App Check
  **debug token is not in code** (documented as debug-only). ✅
- **Advertising ID** — `firebase_analytics` merges
  `com.google.android.gms.permission.AD_ID`; the app now **removes it** via
  `tools:node="remove"` (`android/app/src/main/AndroidManifest.xml`), verified
  absent from the merged release manifest and guarded by
  `test/android_manifest_test.dart`. The newer Privacy-Sandbox
  `ACCESS_ADSERVICES_*` permissions remain (merged by Google measurement, **normal**,
  no advertising-ID exposure, no Play declaration form); they may optionally be
  stripped too if desired. ✅
- **Permissions** — the app **requests** only `INTERNET`, `POST_NOTIFICATIONS`,
  `USE_BIOMETRIC` (all normal). The merged manifest additionally carries standard
  normal permissions from Firebase/Messaging/`local_auth`
  (`ACCESS_NETWORK_STATE`, `WAKE_LOCK`, `USE_FINGERPRINT`, c2dm `RECEIVE`,
  `READ_GSERVICES`, install-referrer) — **none sensitive/dangerous**, so **no Play
  Permissions-Declaration form** is triggered. ✅
- **Manifest** — single exported activity (`MainActivity`, launcher); no
  `usesCleartextTraffic="true"`; no `android:debuggable`. ✅
- **Network** — all egress is HTTPS (Firebase/Gemini); Flutter release blocks
  cleartext by default on modern targetSdk. No custom network-security-config is
  required (documented, not added — behavior-preserving). ✅
- **ProGuard/R8** — enabled with keep rules; release build green. ✅

## 6. Google Play

- **Store listing** — EN + AR, reconciled to the shipped app (now surfaces
  biometric login, multiple CVs, internships, learning interests)
  ([`store/STORE_LISTING.md`](store/STORE_LISTING.md)). ✅
- **Data Safety** — mapped to real flows; biometric declared **not collected**
  (device-local), secure-storage flags declared on-device-only
  ([`store/DATA_SAFETY.md`](store/DATA_SAFETY.md)). ✅
- **Declarations** — permissions table current (3 permissions), AD_ID resolved,
  content rating / 18+ / ads=No / IAP=No prepared
  ([`store/PLAY_CONSOLE.md`](store/PLAY_CONSOLE.md)). ✅
- **App creation, App Signing enrollment, listing/asset upload, closed-testing
  track** — Play Console actions owed at submission. ⚠️

## 7. Legal & privacy

- **Privacy Policy + Terms** are thorough templates grounded in the real data
  flows, with an explicit AI-transparency section, consent lever, deletion rights,
  18+, and ad-free clause. **Fill in the `⟨FILL-IN⟩`s, have counsel review, and
  host at public URLs** — Play requires a reachable privacy-policy URL. ⚠️
- **AI transparency** wording is consistent across the listing, Privacy Policy,
  and Terms. ✅

## 8. QA

- `flutter analyze` clean; **574 tests** (the `render_all_locales` EN+AR sweep is
  the regression backbone). ✅
- Release-build smoke (EN + AR launch, offline banner, notification prompt,
  biometric availability) verified on `emulator-5554` this milestone (see HANDOFF
  §7.25). ✅
- **Recommended before launch:** a full **TalkBack** accessibility pass and
  native-speaker review of the Arabic listing (documented follow-ups, non-blocking;
  HANDOFF §7.19/§7.20). ⚠️
- Full pre-release matrix (EN+AR × light/dark × core seeker/employer flows) lives
  in [`QA_CHECKLIST.md`](QA_CHECKLIST.md). ⚠️ run end-to-end before the production
  push.

## 9. AI services

- **Firebase AI Logic (Gemini)** provisioned and live; every AI feature (Resume
  Analyzer, Job Matching, Career Coach, CV Builder, Interview Prep, Recommendations,
  Recruiter Insights) routes through the vendor-neutral `AiService`. ✅
- **Transparency:** AI output is framed as assistance, **not professional
  employment/career/legal advice**, in the listing + legal docs. ✅
- **AI content language** follows the prompt/user language (EN/AR) — by design. ✅

## 10. Monitoring

- **Analytics** (consent-gated screen views + typed events), **Crashlytics**
  (crash + non-fatal reporting, stamped with `app_version`/`build_type` via
  `BuildInfo`), **Performance** (upload traces) SDKs are live on device. ✅
- **During rollout:** watch Crashlytics and Play **Android vitals** (ANR/crash
  rate) as the staged rollout advances. ⚠️
- **Optional hardening:** add the Crashlytics + Performance **Gradle plugins**
  (release mapping upload + auto HTTP/screen traces) once AGP-9-compatible versions
  are confirmed, then re-validate the release build immediately
  ([`RELEASE.md`](RELEASE.md) §7.4). ⚠️

## 11. Rollback plan

- **Bad release on Play:** halt the staged rollout; promote the previous
  known-good `.aab` (Play retains prior artifacts) or ship a hotfix with a higher
  `versionCode`.
- **App Check lockout:** if enforcement is turned on prematurely and clients are
  denied, **turn enforcement off** in the Console (immediate, reversible).
- **Rules regression:** re-deploy the prior `firestore.rules`/`storage.rules` from
  git history via `firebase deploy`.
- Full detail: [`RELEASE.md`](RELEASE.md) §12.

---

## Remaining Before Publish

Only the **manual actions that cannot be automated from the repository** — every
engineering task above is complete. Work these before the production submission
(all are cross-referenced; none is a code change):

- ☐ **Create the upload keystore** + fill `android/key.properties`; enroll in
  **Play App Signing** on first upload. ([`RELEASE.md`](RELEASE.md) §3, §8)
- ☐ **Fill in** the legal/store `⟨FILL-IN⟩`s (support email, legal entity,
  jurisdiction, effective dates) — tracker in [`store/README.md`](store/README.md).
- ☐ **Counsel-review** the Privacy Policy + Terms, then **host both at public URLs**;
  enter the privacy-policy URL in Play.
- ☐ **Provision the Cloud Storage bucket** (Console → Storage → Get Started), then
  `firebase deploy --only storage`.
- ☐ **App Check:** enable `firebaseappcheck.googleapis.com` → register **Play
  Integrity** (release SHA-256) → allow-list debug tokens → **enforce** only after
  real traffic validates.
- ☐ *(Optional)* add the **Crashlytics + Performance Gradle plugins** once
  AGP-9-compatible; re-validate the release build.
- ☐ *(If phone auth in prod)* set the **SMS region policy** or add a test number.
- ☐ **Play Console:** create the app (`com.careerbridge.careerbridge`), upload the
  listing + assets, complete Data Safety / content rating / target-audience /
  app-access, and release to **Internal → Closed testing → Production** (staged).
- ☐ **Confirm test logins** work immediately before submission; capture the
  screenshot sets ([`store/STORE_ASSETS.md`](store/STORE_ASSETS.md)).
- ☐ *(Recommended)* full **TalkBack** pass + native-speaker review of the Arabic
  listing.

> When every box above is ticked, Career Bridge is ready for its first Google Play
> release. Nothing in the codebase blocks it today.
