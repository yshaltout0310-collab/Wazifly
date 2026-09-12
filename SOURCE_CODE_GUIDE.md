# Wazifly — Source Code Guide

A professional walkthrough of the Wazifly source tree for reviewers: what the app
is, how it is built, and how to get it running.

> **Package/identifier note:** the app is branded **Wazifly** (Arabic: وظيفة فلاي).
> Technical identifiers remain `careerbridge` / `com.careerbridge.careerbridge` and
> the Firebase project id is `careerbridge-97-f58c9` — this is a display-name-only
> rebrand, so the internal names are intentionally unchanged.

---

## 1. Project overview

Wazifly is an **AI-powered, bilingual (English + Arabic) job platform** built with
Flutter for Android and iOS. It serves two audiences from one codebase:

- **Job seekers** — an AI toolkit (Résumé Analyzer, AI Job Matching, Career Coach,
  Interview Prep), a CV Builder with a multi-CV repository, job browsing/search,
  applications, and recommendations.
- **Employers** — a dashboard to manage a company profile, post/edit jobs, review
  applicants, and view hiring analytics.

The AI features are powered by **Google Gemini** through **Firebase AI Logic** (no
API key ships in the client). The app is production-oriented: telemetry, security
(App Check, hardened rules), offline support, bundled fonts, and localization/RTL
are all wired in.

---

## 2. Technologies used

| Area | Technology |
|------|-----------|
| Language / SDK | Dart `>=3.6.0 <4.0.0`, Flutter `>=3.27.0` (developed on 3.44.x stable) |
| UI | Flutter, Material 3, custom design system |
| State management | Riverpod (`flutter_riverpod`) |
| Navigation | `go_router` (declarative) |
| Backend | Firebase (Auth, Firestore, Storage, Messaging, Analytics, Crashlytics, Performance, App Check) |
| AI | Google Gemini via **Firebase AI Logic** (`firebase_ai`, model `gemini-2.5-flash`) |
| PDF | `syncfusion_flutter_pdf` (text extraction), `pdf` + `printing` (generation, rasterization) |
| Auth extras | `local_auth` (biometrics), `flutter_secure_storage` |
| Localization | `flutter_localizations` + `gen-l10n` (EN + AR, RTL-aware) |
| Persistence | `shared_preferences` (prefs), Cloud Firestore (data) |

---

## 3. Folder structure

```
wazifly/
├── lib/
│   ├── main.dart                 # Entry point: bootstrap Firebase + telemetry, run app
│   ├── app.dart                  # Root MaterialApp.router (theme + locale + offline banner)
│   ├── core/                     # Cross-cutting foundation
│   │   ├── constants/            # App constants, languages/countries data
│   │   ├── localization/         # l10n ARB files + generated AppLocalizations + LocaleController
│   │   ├── navigation/           # AppRouter (go_router graph) + RouteNames
│   │   ├── providers/            # App-wide Riverpod providers (storage, etc.)
│   │   ├── services/             # Vendor-neutral service seams (see §6)
│   │   ├── theme/                # AppTheme, colors, dimensions, typography, ThemeController
│   │   └── utils/                # Responsive helpers, formatters
│   ├── features/                 # One folder per feature (see §4 for the layering)
│   │   ├── auth/  splash/  onboarding/  language_selection/  country_selection/
│   │   ├── user_type/  home/  profile/  settings/  security/
│   │   ├── resume_analyzer/  job_matching/  career_coach/  interview_prep/
│   │   ├── cv_builder/  cv_repository/  recommendations/  internships/  learning/
│   │   ├── jobs/  applications/
│   │   └── employer/
│   └── shared/                   # Shared models + reusable widgets (StatusView, buttons, …)
├── assets/                       # Fonts (Inter, Cairo), images, icons, seed data
├── android/  ios/  web/          # Platform runners
├── test/                         # Unit + widget tests
├── docs/                         # Release, store, and legal documentation
├── firebase.json  firestore.rules  storage.rules  firestore.indexes.json
├── l10n.yaml                     # gen-l10n configuration
├── pubspec.yaml                  # Dependencies
└── SOURCE_CODE_GUIDE.md          # This file
```

---

## 4. Architecture

**Feature-first + layered.** Each feature under `lib/features/<name>/` is split into
up to four layers so UI, orchestration, contracts, and implementations stay
decoupled:

```
features/<feature>/
├── domain/        # Contracts (abstract interfaces) + immutable models. No Flutter/Firebase.
├── data/          # Concrete implementations of the domain contracts (Firebase, Gemini, PDF…).
├── application/   # Riverpod controllers = state + orchestration (StateNotifier).
└── presentation/  # Screens + widgets. Watch controllers; hold no business logic.
```

**Dependency inversion via seams.** Features depend on **abstract interfaces**, not
concrete backends. For example the Résumé Analyzer depends on `AiService`,
`PdfTextExtractor`, and `ResumeOcr` interfaces — the Firebase/Gemini/Syncfusion
implementations live in `data/` and are bound by a provider. Swapping a provider
(e.g. Firebase → another backend) is a one-line provider rebind, not a feature
rewrite. The same pattern wraps every platform service in `core/services/`.

**Navigation** is a single declarative `go_router` graph in
`core/navigation/app_router.dart`. The splash reads persisted state and chooses the
entry point:

```
Splash → Language → Country → Onboarding → Welcome
      → Email sign-in / sign-up → Verify email → User type → Home / Employer Home
```

---

## 5. State management

**Riverpod** throughout. The convention:

- **Controllers** are `StateNotifier`s exposing an immutable state object, one per
  feature (e.g. `ResumeAnalyzerController`, `JobMatchingController`,
  `CvActionsController`). Exposed via `StateNotifierProvider`.
- **Repositories/services** are plain `Provider`s returning an interface
  implementation (e.g. `resumeAnalyzerRepositoryProvider`).
- **Dependency injection** is provider overrides: `main.dart` builds a
  `ProviderContainer` and overrides `localStorageProvider` with the loaded
  `SharedPreferences`-backed instance; the same container powers both the bootstrap
  and the widget tree.
- Screens are `ConsumerWidget` / `ConsumerStatefulWidget` and `ref.watch` state.

---

## 6. Firebase services

All Firebase usage is behind **vendor-neutral interfaces** in `core/services/` (an
interface + a Firebase implementation + a no-op fallback), so they never block
startup and can be swapped:

| Service | Interface / impl | Purpose |
|---------|------------------|---------|
| Core | `core/services/firebase/firebase_service.dart` | App init + Firestore cache settings |
| Auth | `features/auth/…` (see §7) | Email/password + verification, phone linking, biometrics |
| Firestore | repositories under features + `core/services/*_store` | Jobs, CVs, applications, company, etc. |
| Storage | `core/services/cloud_storage/` | File upload/download with progress |
| Messaging | `core/services/messaging/` | Push notifications + preferences |
| Analytics | `core/services/analytics/` | Screen views (route observer) + consent |
| Crashlytics | `core/services/crashlytics/` | Error reporting + user context |
| Performance | `core/services/performance/` | Perf traces |
| App Check | `core/services/app_check/` | Device attestation (activated after `runApp`, never blocks startup) |
| AI Logic | `core/services/ai/` | Gemini access (see §10) |

`firebase_options.dart` (in `core/services/firebase/`) holds the generated client
config. **Firestore/Storage security rules** are versioned at the repo root
(`firestore.rules`, `storage.rules`) and are deployed — reviewers can read the exact
access model there.

---

## 7. Authentication

Located in `features/auth/`, `features/security/`, and gated by the splash.

- **Email/password** sign-up and sign-in with a mandatory **email-verification
  gate**: `registerWithEmail` auto-sends a verification link; a dedicated
  `EmailVerificationScreen` offers Resend (30 s cooldown) / "I've verified"
  (reload) / "Use another". Both the sign-in flow and the splash refuse an
  unverified session.
- **Phone verification by linking** (`linkWithCredential`) — adds a phone factor to
  the existing account; it is not a separate phone-only sign-in.
- **Biometric app-lock** (`local_auth`) — an optional launch-time gate over the
  persisted Firebase session; the preference (never the password) is kept in
  `flutter_secure_storage`. Existing users are unaffected when it is off.
- `AppUser` carries `method` (`AuthMethod`) and `emailVerified`. A **Security
  Settings** screen manages phone + biometrics.

---

## 8. Résumé Analyzer

`features/resume_analyzer/`. Pipeline:

1. **PDF → text** — `SyncfusionPdfTextExtractor` uses Syncfusion's layout-aware
   extraction (`extractText(layoutText: true)`) so text reflows into readable lines
   with intact spacing and dates (avoids the one-token-per-line "soup" the default
   mode produces).
2. **OCR fallback** for scanned PDFs — see §9.
3. **AI analysis** — the text is sent to `AiService.generateJson` with a prompt that
   (a) detects the candidate's **career field first**, (b) evaluates **only** within
   that field (never recommends unrelated-domain skills), (c) applies an explicit
   **0–100 rubric calibrated to career stage**, and (d) validates dates against
   today so it never invents date errors.
4. **Result** — mapped to `ResumeAnalysis` (`careerField`, `atsScore`, `summary`,
   `strengths`, `weaknesses`, `missingSkills`, `grammarIssues`,
   `improvementSuggestions`) and rendered with an animated score gauge.

---

## 9. OCR (scanned PDFs)

`features/resume_analyzer/data/gemini_pdf_ocr.dart` implements the `ResumeOcr`
interface. When text extraction yields too little (a scan from Adobe Scan,
CamScanner, Microsoft Lens, or a photographed page), the repository falls back to
OCR and continues the analysis on the recovered text:

1. `printing` rasterizes each page to a PNG on-device (PDFium), capped at 8 pages /
   200 DPI.
2. A **single multimodal Gemini request** (`firebase_ai`,
   `Content.multi([TextPart, InlineDataPart…])`) transcribes all pages verbatim.
3. The transcription flows into the normal analysis path.

This reuses the Firebase AI backend the analyzer already needs — **no extra native
OCR plugin or model download**. If OCR is unavailable or also empty, the usual
"couldn't read any text" error is shown.

---

## 10. AI integration

`core/services/ai/` defines `AiService` (the provider-neutral seam) with
`generateText`, `generateJson`, `streamText`, `streamChat`.
`FirebaseAiService` implements it against **Firebase AI Logic** using the Gemini
Developer backend (`FirebaseAI.googleAI()`), model **`gemini-2.5-flash`**, with
`responseMimeType: application/json` for structured calls. **No API key is shipped**
— requests are authenticated by the Firebase app (+ App Check).

The one `AiService` seam powers every AI feature: Résumé Analyzer, AI Job Matching,
Career Coach (streaming chat), CV enhancement, Interview Prep, Recommendations, and
Recruiter Insights.

---

## 11. CV Builder + CV repository

- **`features/cv_builder/`** — a form-driven builder that produces an ATS-friendly
  PDF via the `pdf` / `printing` packages (bidi-aware for Arabic). It can optionally
  edit and save back an existing stored CV.
- **`features/cv_repository/`** — a Firestore-backed **multiple-CV** store
  (`resumes/{resumeId}`): create / import / rename / duplicate / archive / restore /
  set-default / soft-delete, each CV carrying its own analysis, tags, and last-used
  timestamp. A **core seam** (`core/services/cv_repository/`, `CvRepository` +
  `CvDocument`) lets the builder and AI features depend on core rather than the
  feature. Includes default-protection (always ≥1 active CV) and import dedup.

---

## 12. Job search

- **`features/jobs/`** — browse/search jobs, job detail with an AI match panel.
- **`features/job_matching/`** — AI matches a résumé/CV against jobs (via
  `AiService`).
- **`features/recommendations/`** — personalized suggestions.
- **`features/internships/` / `features/learning/`** — internship metadata and a
  learning-profile seam.

Country defaults to **Qatar** for browsing/matching (via
`CountriesData.defaultCountry`), independent of the persisted profile country.

> **Data source:** the seeker-facing catalogue is a **bundled dataset** of 18
> bilingual openings (`assets/data/seed_jobs.json`, read through
> `SeedJobsRepository`), *not* live Firestore data — and submitted applications are
> **session-scoped in memory**. Both sit behind the same repository interfaces as a
> real backend would, so connecting them is a provider rebind. See
> [`docs/TECHNICAL_AUDIT.md`](docs/TECHNICAL_AUDIT.md) §4.3–§4.4.

---

## 13. Employer dashboard

`features/employer/` — a role-aware experience selected at `user_type`:

- **Company** profile (view/edit).
- **Jobs** — list, create, edit, preview, and per-job applicants.
- **Applicants** — review candidates and application detail.
- **Analytics** — hiring funnel/metrics.

Employer permission-denied events feed the security audit log.

Jobs and applicants on this side are **Firestore-backed** (`jobs/`,
`applications/`, `applicationNotes/`). Because the seeker side does not yet write
to `applications/`, the Applicants and Analytics screens have no production data
to show — see [`docs/TECHNICAL_AUDIT.md`](docs/TECHNICAL_AUDIT.md) §4.4.

---

## 14. Localization

- `flutter_localizations` + **`gen-l10n`**; config in `l10n.yaml`, source strings in
  `lib/core/localization/l10n/app_en.arb` and `app_ar.arb`, generated into
  `AppLocalizations`.
- **English + Arabic** are fully supported; the language registry
  (`core/constants/languages_data.dart`) lists 8 more as "coming soon".
- **RTL** is handled automatically per locale; the brand renders as "وظيفة فلاي"
  inside Arabic sentences while the wordmark stays Latin "Wazifly".
- Language is chosen on first launch (Language Selection screen) and changeable in
  Settings; the choice is persisted by `LocaleController`.

To regenerate localizations after editing an ARB: `flutter gen-l10n`.

---

## 15. Theme

`core/theme/` — a **Material 3** design system: `AppTheme.light()` / `.dark()`,
an emerald-green brand palette (`AppColors`), spacing/radius tokens
(`AppDimensions`), and locale-aware typography (`AppTypography`). Fonts (**Inter**
for Latin, **Cairo** for Arabic) are **bundled under `assets/fonts`** (not fetched
at runtime) so text renders correctly offline. Theme mode (system/light/dark) is a
persisted `ThemeController` and switches live.

---

## 16. Packages used

**Runtime**

| Package | Why |
|---------|-----|
| `flutter_riverpod` | State management + DI |
| `go_router` | Declarative navigation |
| `intl`, `flutter_localizations` | i18n / l10n |
| `shared_preferences` | Local preferences |
| `google_fonts` | Font config (runtime fetching disabled; fonts bundled) |
| `flutter_animate` | Micro-interactions / entrance animations |
| `equatable` | Value equality for models/state |
| `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`, `firebase_messaging`, `firebase_analytics`, `firebase_crashlytics`, `firebase_performance`, `firebase_app_check` | Firebase platform |
| `firebase_ai` | Gemini via Firebase AI Logic |
| `syncfusion_flutter_pdf` | PDF text extraction (résumé parsing) |
| `pdf`, `printing` | PDF generation + on-device page rasterization (OCR) |
| `file_selector` | Pick PDFs |
| `local_auth` | Biometric authentication |
| `flutter_secure_storage` | Secure preference storage |

**Dev**

| Package | Why |
|---------|-----|
| `flutter_test` | Unit + widget tests |
| `flutter_lints` | Lint ruleset (`analysis_options.yaml`) |
| `flutter_launcher_icons` | Adaptive launcher icons |
| `flutter_native_splash` | Native splash screen |

Exact versions are pinned in `pubspec.yaml` / `pubspec.lock`.

---

## 17. Prerequisites

- **Flutter SDK** matching the constraints above (`>=3.27.0`, Dart `>=3.6.0`).
  Verify with `flutter --version` and `flutter doctor`.
- **Android:** Android Studio + an SDK / emulator (or a device). The Gradle wrapper
  is included.
- **iOS (optional):** macOS + Xcode + CocoaPods (`pod install` in `ios/`).
- A **Firebase project** (this source is wired to `careerbridge-97-f58c9`; see §19).

---

## 18. Build & run

```bash
# 1. Fetch dependencies
flutter pub get

# 2. (Re)generate localizations — usually already generated in the source
flutter gen-l10n

# 3. Run on a connected device / emulator
flutter run                       # pick a device, or:
flutter run -d <deviceId>

# 4. Build release artifacts
flutter build apk --release       # Android APK  → build/app/outputs/flutter-apk/
flutter build appbundle --release # Android AAB (Play Store)
flutter build ios --release       # iOS (requires macOS + Xcode + GoogleService-Info.plist)
flutter build web --release       # Web bundle → build/web/ (see §21)

# Quality gates
flutter analyze                   # static analysis (expected: no issues)
flutter test                      # full unit + widget suite
```

If Android release signing is desired, copy `android/key.properties.example` to
`android/key.properties` and point it at a keystore; without it the release build
falls back to debug signing.

---

## 19. Firebase configuration & environment variables

**No `.env` file and no runtime environment variables are required** — the app has
no secrets to inject at runtime (AI access is authenticated through Firebase, not an
API key in the client).

Firebase config in this bundle:

- **`lib/core/services/firebase/firebase_options.dart`** — included (generated by
  FlutterFire); used by `Firebase.initializeApp`.
- **`android/app/google-services.json`** — **not in the repository.** It is
  gitignored, so a `git clone` will not have it and the Android build will fail at
  the Google-Services Gradle step until you supply your own (Firebase console, or
  `flutterfire configure`). A hand-assembled source archive may include it; a clone
  will not. **The web target needs no such file** and builds from a clean clone,
  because `firebase_options.dart` already carries the web config.
  These are **client-side** identifiers (already present in `firebase_options.dart`
  and in any shipped APK); access is protected server-side by the Firestore/Storage
  **security rules** and **App Check**, not by keeping the file private.
- **`ios/Runner/GoogleService-Info.plist`** — **not included**; add your own from the
  Firebase Console to build the iOS target.

To point the app at **your own Firebase project** instead, run
`flutterfire configure` (regenerates `firebase_options.dart` + the platform config
files), then deploy `firestore.rules` / `storage.rules`.

Optional build-time defines (not required):

```bash
flutter run --dart-define=APP_VERSION=1.0.0   # stamped onto crash reports (BuildInfo)
```

Server-side console steps that are outside the source (App Check enforcement, Storage
bucket provisioning, enabling the Gemini/AI Logic API) are documented in `docs/`.

---

## 20. Repository hygiene

The distributed archive contains **source only** — `build/`, `.dart_tool/`,
`.idea/`, `.gradle/`, `.git/`, iOS `Pods/`/ephemeral output, and other generated
build artifacts are excluded. Run `flutter pub get` after extracting to regenerate
the local tool state.

---

## 21. Web target

The same source builds a browser bundle:

```bash
flutter build web --release        # → build/web/
```

Unlike Android, the web target builds **from a clean clone** — no extra config
file is required (§19).

**What runs and what disables itself.** Every platform capability is behind an
interface with a no-op fallback, so the web build loses features rather than
breaking:

| Capability | Web | Why |
| --- | --- | --- |
| Auth, Firestore, Storage, Analytics, Gemini/AI | ✅ | Firebase JS SDK loads automatically; `firebase_options.dart` carries the web config |
| PDF generation, résumé upload | ✅ | `pdf`, `printing`, `file_selector` all have web implementations |
| Biometric app-lock | Absent | `local_auth` has no web plugin — `biometricServiceProvider` binds `NoopBiometricService` when `kIsWeb` |
| Connectivity / offline banner | Absent | The probe is `dart:io`-based; web binds `NoopConnectivityService` |
| Crashlytics, Push (FCM), App Check | Fail softly | No web plugin / no provider configured; every call is caught and logged |

**Two web-specific properties worth knowing when changing code:**

1. **No 64-bit integer literals.** Dart compiles to JavaScript, whose numbers
   cannot represent integers above 2^53 exactly, so a literal such as
   `0xcbf29ce484222325` is a hard compile failure — and one that neither
   `flutter analyze` nor `flutter test` will catch, because both run on the VM.
   Deterministic hashing therefore lives in
   `lib/core/utils/stable_hash.dart` (32-bit lanes), and
   `test/stable_hash_test.dart` scans `lib/` for any reintroduced literal.
2. **Nothing in the launch path may throw.** The splash awaits the biometric gate
   before routing; an escaping `MissingPluginException` there leaves the app on a
   blank splash forever. Launch-path service probes swallow all exceptions by
   design.

**Deployment.** `.replit`, `replit.nix` and `tool/replit/` configure a Replit
static deployment of `build/web`. The app uses Flutter's default **hash-based URL
strategy** (`/#/home`), so any plain static file host works — no SPA rewrite rule
is needed. Full runbook, including the Firebase console steps the deployed domain
requires: [`docs/REPLIT_DEPLOYMENT.md`](docs/REPLIT_DEPLOYMENT.md).
