# Career Bridge — Phase 1 (Foundation)

An AI-powered global job platform. **Phase 1** delivers the production-ready
foundation only: design system, localization (LTR + RTL), the welcome flow, and
prepared (not yet implemented) Firebase & Gemini architecture.

> No job features and no authentication logic yet — by design.

---

## ✨ What's included

- **Material 3 design system** — emerald-green brand, light + dark themes, live
  theme switching, locale-aware typography (Inter / Cairo), rounded cards,
  pill buttons, soft surfaces.
- **Localization from day one** — English + Arabic with full RTL support,
  persisted language choice (switchable anytime from **Settings**), and an
  architecture that scales to unlimited languages (drop in one `.arb` file).
- **Settings screen** — language, theme (System/Light/Dark), notifications,
  profile, replay onboarding, and logout.
- **Branded identity** — adaptive launcher icon + branded native splash
  (Android 12+) generated from a single source image, plus an animated
  in-app splash.
- **Full welcome + auth flow** — Splash → Language → Country → Onboarding →
  Welcome → (Email / Google / Phone+OTP) → User Type (Job Seeker / Employer) →
  Home, wired with `go_router` and smooth transitions.
- **Authentication** — email/password (sign-in + sign-up), Google, and phone+OTP,
  behind an `AuthRepository` interface. A `FirebaseAuthRepository` runs when real
  credentials exist; otherwise a `MockAuthRepository` simulates sign-in so the
  whole flow is demoable on-device with no backend.
- **Responsive** — adapts padding/width for phones and tablets.
- **Animations** — splash reveal, page/card/button/list micro-interactions.
- **Scalable, clean architecture** — feature-first folders with clear layers.

---

## 🚀 Getting started

This repo currently contains the Dart source + configuration. Generate the
native platform projects, then run:

```bash
# 1. Generate android/ios/web scaffolding (does NOT touch lib/).
flutter create --org com.careerbridge --project-name careerbridge .

# 2. Fetch packages (also auto-generates the localization classes).
flutter pub get

# 3. (Optional) generate localization manually if needed
flutter gen-l10n

# 4. Run
flutter run
```

> Requires Flutter **3.27+** / Dart **3.6+**.

### Regenerating the icon & splash (after editing `assets/icon/`)

```bash
dart run flutter_launcher_icons        # adaptive launcher icons
dart run flutter_native_splash:create  # branded OS splash
```

### Connecting Firebase (one-time)

The production auth/Firestore/Storage/Messaging code is fully wired. It activates
the moment real credentials exist — until then the app launches and shows a
"connect Firebase" notice (no demo/mock sign-in).

```bash
# 1. Tooling (needs Node.js for firebase-tools)
npm install -g firebase-tools
dart pub global activate flutterfire_cli
firebase login

# 2. Generate real config (overwrites firebase_options.dart, adds
#    google-services.json + the Gradle plugin)
flutterfire configure

# 3. In the Firebase console, enable the sign-in providers:
#    Authentication → Sign-in method → Email/Password, Google, Phone
#    - Google: add the app's SHA-1 & SHA-256 (gradlew signingReport)
#    - Phone:  add a test number for emulator OTP, or use a real device
#    Then create Firestore + Storage in the console.

flutter run
```

`FirebaseService` auto-detects the real config (the placeholder apiKey sentinel
is gone) and switches `authRepositoryProvider` from the unconfigured stub to the
real `FirebaseAuthRepository` — **no code changes needed**.

---

## 🧱 Project structure

```
lib/
├── main.dart                      # Bootstrap: storage + Firebase + ProviderScope
├── app.dart                       # MaterialApp.router: theme + locale + routes
│
├── core/                          # Cross-cutting foundation
│   ├── constants/                 # app constants, country & language datasets
│   ├── localization/              # l10n ARB files, controller, generated output
│   ├── navigation/                # go_router config + route names
│   ├── providers/                 # global Riverpod providers (storage)
│   ├── services/
│   │   ├── ai/                    # AiService contract + Gemini placeholder
│   │   ├── firebase/              # FirebaseService + options placeholder
│   │   └── storage/               # LocalStorageService + keys
│   ├── theme/                     # colors, dimensions, typography, theme, controller
│   └── utils/                     # responsive helpers
│
├── features/                      # Feature-first modules
│   ├── splash/
│   ├── language_selection/
│   ├── country_selection/
│   ├── onboarding/
│   └── auth/                      # placeholder only
│       Each feature splits into:
│         presentation/  (screens + widgets)
│         application/   (Riverpod controllers)
│         domain/        (models / contracts)
│
└── shared/                        # Reused across features
    ├── models/                    # CountryModel, LanguageModel
    └── widgets/                   # AppLogo, PrimaryButton, SearchField, ...
```

**Layering rule:** `presentation → application → domain`. Features depend on
`core`/`shared`, never on each other.

---

## 📦 Packages & why

| Package | Why it's here |
|---|---|
| **flutter_riverpod** | Compile-safe, testable state management. Theme, locale, country, and onboarding state each live in independent providers — keeps a large app maintainable. |
| **go_router** | Declarative, URL/deep-link-ready routing maintained by the Flutter team. Centralizes the whole navigation graph. |
| **shared_preferences** | Lightweight key/value persistence for theme, language, country, and the onboarding flag. |
| **google_fonts** | Premium typefaces without bundling files — Inter (LTR) + Cairo (Arabic). |
| **flutter_animate** | Concise, performant animation API powering splash, page, card, button, and list motion. |
| **intl** | Locale utilities + message formatting used by generated localizations. |
| **flutter_localizations** | Official Material/Cupertino/Widgets localization delegates; required for RTL/LTR. |
| **equatable** | Value equality for immutable models (Country, Language). |
| **firebase_core** | Base required to initialize any Firebase service. |
| **firebase_auth** | Authentication backend (wired in a later phase). |
| **cloud_firestore** | Primary NoSQL datastore for users/jobs (later phase). |
| **firebase_storage** | File/object storage for resumes & media (later phase). |
| **flutter_lints** *(dev)* | Official recommended lint rules for idiomatic Dart/Flutter. |

---

## 🌍 Adding a new language

1. Add `lib/core/localization/l10n/app_<code>.arb` (copy `app_en.arb`, translate).
2. Add a `LanguageModel` entry in `languages_data.dart` (set `isSupported: true`).
3. Done — `supportedLocales`, the picker, and RTL handling update automatically.

---

## 🔭 Roadmap (next phases)

- Authentication (Firebase Auth) using the `AuthRepository` contract.
- Gemini integration behind the `AiService` interface.
- Job discovery, matching, resume analysis, career coach, interview prep.
