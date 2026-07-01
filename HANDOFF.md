# Career Bridge — Session Handoff

> Living handoff doc so a fresh Claude session can continue immediately.
> Last updated: end of Phase 2 · Milestone 3 (AI Career Coach) implementation.
> **Phase 2 (M1 Resume Analyzer + M2 Job Matching + M3 Career Coach) is COMPLETE.**

---

## 1. Project overview

**Career Bridge** is an AI-powered global job platform built in **Flutter**. It is
bilingual (English + Arabic, full RTL), Material 3, emerald-green branded, and
backed by **Firebase** (Auth, Firestore, Storage, Messaging, and — new in Phase 2 —
**Firebase AI Logic / Gemini**).

- **Repo root:** `C:\project\CareerBridge`
- **Flutter:** 3.44.4 stable · Dart SDK `>=3.6.0 <4.0.0` · `flutter >=3.27.0`
- **Package name / Android applicationId:** `com.careerbridge.careerbridge`
- **Primary dev target:** Android emulator `emulator-5554` (AVD `careerbridge_pixel`, 1080x2400, density 420, API 35).
- **Platform:** Windows 11. Shell examples below use Git Bash; `adb` lives at
  `~/AppData/Local/Android/Sdk/platform-tools/adb.exe` (NOT on PATH).

---

## 2. Current architecture

**Feature-first, clean layering.** Each feature under `lib/features/<name>/` splits into:
```
presentation/   screens + widgets (Consumer widgets)
application/    Riverpod controllers (StateNotifier) + state
domain/         models (Equatable), repository interfaces, exceptions
data/           repository implementations, external adapters
```
Cross-cutting code under `lib/core/` (`constants`, `localization`, `navigation`,
`providers`, `services/{ai,firebase,storage,messaging,cloud_storage,document}`,
`theme`, `utils`). Reused widgets/models under `lib/shared/`.

**State management:** `flutter_riverpod` 2.6.x (no code-gen). Controllers are
`StateNotifier<T>` exposed via `StateNotifierProvider`. Services/repositories are
plain `Provider`s. `localStorageProvider` is overridden in `main()`.

**Navigation:** `go_router` 14.x. All routes in `lib/core/navigation/app_router.dart`,
names/paths in `route_names.dart`. Pattern: **`push`/`pushNamed` to go forward within
a flow** (keeps back stack), **`go`/`goNamed` to reset** (post-auth, splash, logout).
Onboarding→Welcome uses `pushReplacementNamed`.

**Localization:** ARB files at `lib/core/localization/l10n/app_{en,ar}.arb`
(simple `"key": "value"`, **no `@`-metadata**). Generated via `flutter gen-l10n`
into `lib/core/localization/generated/`. `l10n.yaml` drives it. Access with
`AppLocalizations.of(context)`. Locale held by `localeControllerProvider`
(`StateNotifier<Locale?>`, persisted).

**Design system:** `lib/core/theme/` — `AppColors` (emerald palette, gradients),
`AppSpacing`/`AppRadius`/`AppDurations`/`AppCurves`/`AppShadows`
(`app_dimensions.dart`), `AppTheme`, `AppTypography` (Inter/Cairo via google_fonts).
Shared widgets: `PrimaryButton`, `SearchField`, `AppLogo`, `AuroraBackground`,
`GlassCard`, `ResponsiveCenter` (+ `context.horizontalGutter`).

**Error handling convention:** typed exceptions with a stable, localizable `code`
enum (`AuthException`/`AuthErrorCode`, `AiException`/`AiErrorCode`,
`ResumeAnalyzerException`/`ResumeErrorCode`, `JobMatchingException`/`JobMatchErrorCode`;
the Career Coach reuses `AiException` mapped to a `CoachFailure` enum); presentation
maps the code → a UI-facing failure enum → l10n string. Branded snackbars via
`showAuthSnack`/`showAuthError`.

**AI abstraction (`AiService`):** `generateText`, `generateJson`, `streamText`, and
**`streamChat(List<AiMessage>, {systemInstruction})`** (multi-turn streaming for the
coach). Only plain Dart crosses the interface (`String`/`Map`/`Stream<String>`/the
plain-value `AiMessage`) — no vendor types leak. `FirebaseAiService` is the only file
importing `firebase_ai`; swap providers by rebinding `aiServiceProvider`.

---

## 3. App flow

`Splash → Language → Country → Onboarding → Welcome → (Email | Google | Phone→OTP)
→ User Type (Job Seeker/Employer) → Home`. Settings + Profile reachable from Home.
Home shows an "AI toolkit" grid of feature cards; the **Resume Analyzer**, **AI Job
Matching**, and **Career Coach** cards are now live (route to their screens), the
remaining three (CV Builder, Interview Prep, For You) show a "Soon" badge +
coming-soon snackbar.

---

## 4. Completed phases & milestones

### Phase 1 — Foundation (committed `6f860fe` on `main`)
Design system, l10n (EN/AR/RTL), splash, language/country pickers, onboarding,
welcome + full auth UI, user type, home, settings, profile. Firebase architecture
prepared but not wired.

### Phase 1.5 — Fixes + Real Firebase (committed on `firebase-auth-integration`)
- **`2af451d` Integrate real Firebase Authentication and remove demo mode:**
  wired real `firebase_options.dart` (moved to `lib/core/services/firebase/`),
  `FirebaseService` always initializes, `authRepositoryProvider` always returns
  `FirebaseAuthRepository`, deleted `UnconfiguredAuthRepository` + the demo banner +
  `demoModeNotice`/`errNotConfigured`/`AuthErrorCode.notConfigured`. Tests override
  `authRepositoryProvider` with `FakeAuthRepository` (`test/support/fake_auth.dart`).
- **`aa9b7d2` Add Cloud Firestore security rules:** `firestore.rules` (users can
  read/write only their own `users/{uid}` doc) + `firestore.indexes.json`, wired into
  `firebase.json`, **deployed** with `firebase deploy --only firestore:rules`.
- Also included earlier UI fixes (all in `6f860fe` actually — see note): country
  search clear button (`SearchField` is now stateful), onboarding→welcome
  `pushReplacementNamed` back-nav fix, RTL dial-code fix (`+974` not `974+` via
  `textDirection: TextDirection.ltr`), email screen "Sign Up" row overflow fix
  (`Row`→`Wrap`), and the `render_all_locales_test.dart` sweep.

**Verified on emulator (Phase 1.5):** Email register + login (real account
`appreg030157@cb.app` created in Firebase Auth), Google Sign-In launches the real
OAuth activity, Phone auth reaches Firebase's SMS gateway (blocked only by SMS region),
Firestore profile doc created, User Type → Home, logout. All confirmed via
logcat + Firestore REST + screenshots.

### Phase 2 · Milestone 1 — AI Resume Analyzer ✅ COMPLETE (committed `bf469e6`)
See §7. Fully implemented, tested, and **verified live end-to-end on the emulator in
both English and Arabic** with real Gemini output. No open blockers.

### Phase 2 · Milestone 2 — AI Job Matching ✅ COMPLETE (committed `8f2101f`)
See §7.5. Ranks a bundled seed job dataset against the analyzed resume via the same
`AiService.generateJson`. Uses the cached resume analysis when present; otherwise prompts
to upload one, analyzes it (reusing the M1 pipeline), caches it, and matches
automatically. **Verified live end-to-end on the emulator in both English and Arabic**
with real Gemini output. `flutter analyze` clean; **59 tests pass**. No open blockers.

### Phase 2 · Milestone 3 — AI Career Coach ✅ COMPLETE (committed on `feature/resume-analyzer`)
See §7.6. Streaming chat assistant (`AiService.streamChat`) with multi-turn history,
personalized with the cached resume analysis when available, history behind a
`ChatHistoryStore` seam. **Verified live end-to-end on the emulator in both English and
Arabic** with real streaming Gemini output (incl. multi-turn context). `flutter analyze`
clean; **76 tests pass**. No open blockers. **Phase 2 is now complete.**

---

## 5. Firebase setup & required console configuration

- **Project:** `careerbridge-97-f58c9` · **project number:** `894890748117`
- **Config in code:** `lib/core/services/firebase/firebase_options.dart` (real client
  keys — committed; these are client identifiers, not secrets, and are NOT gitignored).
  `firebase.json` `dart` output path points here so `flutterfire configure` regenerates
  in place.
- **`android/app/google-services.json`:** present locally but **gitignored** (per
  `.gitignore` "Firebase secrets"). A fresh clone must run `flutterfire configure`
  or obtain it.
- **Gradle:** `google-services` plugin applied, `minSdk 23`, `multiDexEnabled true`
  (set by `flutterfire configure`).

**Console state (what's enabled):**
- ✅ **Authentication** providers: Email/Password, Google, Phone — **enabled**.
- ✅ **Cloud Firestore** — created in **Production mode**; rules deployed from
  `firestore.rules`.
- ⚠️ **Phone SMS delivery** — Firebase returns `17006 "SMS unable to be sent until
  this region enabled"`. To actually deliver codes: Console → Auth → Settings →
  **SMS region policy** (allow the region, e.g. Qatar/+974) **or** add a **test phone
  number** under Auth → Sign-in method → Phone. (Not needed for M1/M2/M3.)
- ✅ **Firebase AI Logic (Gemini Developer API)** — **ENABLED and provisioned.**
  `firebasevertexai.googleapis.com` + `generativelanguage.googleapis.com` are enabled,
  and the AI Logic config now has a `generativeLanguageConfig` (a Gemini API key
  restricted to `generativelanguage.googleapis.com`, obfuscated `GHCGSb6Y`). This is
  exactly what the Console "AI Logic → Get started" wizard does; it was completed via
  the Service Usage + `firebasevertexai` `updateConfig` APIs using the logged-in
  Firebase CLI credentials (project owner `yshaltout0310@gmail.com`). **Live Gemini
  calls succeed.** If it ever regresses to "AI logic config is missing," re-run the
  Console AI Logic "Get started" flow (or re-PATCH `.../locations/global/config`).

**Deploying Firestore rules** (Node not on PATH; firebase CLI at
`%APPDATA%\npm\firebase.cmd`):
```powershell
$env:Path = "C:\Program Files\nodejs;" + $env:Path
& "C:\Users\yshal\AppData\Roaming\npm\firebase.cmd" deploy --only firestore:rules --project careerbridge-97-f58c9
```

**Test account (already exists in Firebase Auth + Firestore):**
`appreg030157@cb.app` / `Test123456` — has a `users/{uid}` profile doc and
`userType = jobSeeker`.

---

## 6. Git branches & latest commits

```
main                         6f860fe  Phase 1 production foundation completed
firebase-auth-integration    aa9b7d2  Add Cloud Firestore security rules  (branched from main)
                             2af451d  Integrate real Firebase Authentication and remove demo mode
feature/resume-analyzer  *  89ee1a1  feat: AI Career Coach (Phase 2, Milestone 3)  <-- current HEAD
                             8f2101f  feat: AI Job Matching (Phase 2, Milestone 2)
                             bf469e6  feat: AI Resume Analyzer (Phase 2, Milestone 1)
                            (each milestone: 1 feat commit + a follow-up docs commit updating this file)
                             branched from firebase-auth-integration
```
- **M1 COMMITTED (`bf469e6`); M2 COMMITTED (`8f2101f`); M3 COMMITTED (`89ee1a1`).** Neither
  `firebase-auth-integration` nor `feature/resume-analyzer` is merged to `main`, and
  nothing is pushed to any remote. (No PRs opened.)
- Commit message convention: end with
  `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`.
- **Do NOT commit** `.claude/settings.local.json` (local). Exclude it from `git add`.

**Uncommitted Milestone-1 changes on `feature/resume-analyzer`:**
- New: `lib/core/services/ai/{ai_exception,ai_providers,firebase_ai_service}.dart`,
  entire `lib/features/resume_analyzer/`, `test/resume_analysis_test.dart`,
  `test/resume_analyzer_repository_test.dart`, `test/resume_analyzer_screen_test.dart`.
- Modified: `lib/core/services/ai/ai_service.dart` (new interface),
  `lib/core/navigation/{app_router,route_names}.dart`,
  `lib/features/home/presentation/home_screen.dart`,
  `lib/core/localization/l10n/*` + generated, `pubspec.yaml`, `pubspec.lock`,
  `test/render_all_locales_test.dart`.

---

## 7. Milestone 1 — AI Resume Analyzer ✅ COMPLETE & VERIFIED (`bf469e6`)

**Scope (approved):** upload PDF → extract text → analyze with AI → display ATS Score,
Strengths, Weaknesses, Missing Skills, Grammar/Writing Issues, Improvement Suggestions.
**No Firestore/Storage history** (explicitly deferred). Provider = **Firebase AI Logic
(Gemini Developer API)** behind a swappable interface.

**DONE (code complete):**
- Reusable AI layer: `AiService` interface (`generateText`, `generateJson`,
  `streamText` — `streamText` is defined now for M3 streaming),
  `FirebaseAiService` (`FirebaseAI.googleAI()`, model `gemini-2.5-flash`, JSON mode via
  `responseMimeType: application/json`, strips ```` ```json ```` fences, maps errors to
  `AiException`), `aiServiceProvider`. `AiException`/`AiErrorCode`.
- `ResumeAnalysis` model (Equatable, **defensive `fromJson`** — clamps score 0–100,
  tolerates snake_case + missing/mistyped fields; `GrammarIssue{issue,suggestion}`).
- `PdfTextExtractor` interface + `SyncfusionPdfTextExtractor` (pure-Dart).
- `ResumeAnalyzerRepository` + impl (extract → build localized prompt → `generateJson`
  → map; throws `ResumeAnalyzerException(noText)` for scanned PDFs,
  `AiException(invalidResponse)` for empty analysis). `resumeAnalyzerRepositoryProvider`.
- `ResumeAnalyzerController` (`StateNotifier<ResumeAnalyzerState>`; states
  idle/analyzing/success/error; `pickAndAnalyze()` via `file_selector`, `reset()`;
  `@visibleForTesting .seeded()` ctor). `ResumeFailure` enum → localized message.
- UI: `ResumeAnalyzerScreen` (AnimatedSwitcher over upload/analyzing/error/results),
  widgets `AtsScoreGauge` (animated CustomPaint ring + qualitative band),
  `AnalysisSection` + `BulletItems` + `GrammarIssueList`, `_SkillChips`. Material 3,
  RTL-aware, branded.
- l10n: ~30 `resume*` keys in EN + AR. AI is asked to reply in the user's language.
- Wiring: `RouteNames.resumeAnalyzer` (`/resume-analyzer`) + `GoRoute`; Home card now
  has `route` + `available` fields (shows ↗ and `pushNamed`s; others still "Soon").
- Tests: **45 total pass.** New: model parse (5), repository orchestration with a fake
  `AiService`/`PdfTextExtractor` (5), screen results render EN+AR (2), + analyzer idle
  added to the locale sweep. `flutter analyze` clean.

**VERIFIED live on emulator with REAL Gemini output — both English and Arabic:**
Home card → analyzer screen → "Choose PDF" opens the SAF picker filtered to
`application/pdf` → selecting `/sdcard/Download/sample_resume.pdf` runs the full
pipeline (extract text → Gemini analysis) → results render:
- **English:** ATS Score **88/100 (Excellent)**, summary, Strengths (5), Weaknesses (5),
  Missing Skills (6 chips), Grammar & Writing (issue + suggestion), Improvement
  Suggestions (6) — all specific to the resume.
- **Arabic (RTL):** re-ran after switching Settings → Language → العربية; the AI
  returned all sections **in Arabic** with correct RTL layout (right-aligned text,
  checkmarks/arrows on the right, gauge + chips correct).
- Error handling also verified earlier (graceful localized messages).

Also fixed during verification: a ~3px Home feature-card overflow with the longer
Arabic "AI Job Matching" label (lowered grid `childAspectRatio` 1.55 → 1.42).

**No open blockers.** Firebase AI Logic is enabled + provisioned (see §5).
`flutter analyze` clean; **45 tests pass.** Committed as `bf469e6`.

---

## 7.5 Milestone 2 — AI Job Matching ✅ COMPLETE & VERIFIED

**Scope (approved — Option 3):** rank jobs against the analyzed resume; ranked list with
per-job **match score (%)** + a short **"why it matches"** explanation. **Use the cached
resume analysis if it exists; otherwise prompt to upload one, analyze it (reusing the M1
pipeline), cache it, and continue to matching automatically.** Architected so a real jobs
API can replace the seed source later with no refactor. Provider = **Firebase AI Logic
(Gemini)** via the same `AiService.generateJson`.

**Persistence-ready resume cache (the seam the user asked for):**
- `lib/core/services/resume_store/resume_analysis_store.dart` — `ResumeAnalysisStore`
  interface + `InMemoryResumeAnalysisStore` (session-scoped) + `resumeAnalysisStoreProvider`
  (the swap point) + `LastResumeAnalysisController`/`lastResumeAnalysisProvider` (reactive
  `StateNotifier<ResumeAnalysis?>` that mirrors writes into the store).
- The M1 `ResumeAnalyzerController` now writes its result here on success.
- **To add durable persistence later (Firestore `users/{uid}` or a local cache): write a
  new `ResumeAnalysisStore` and rebind `resumeAnalysisStoreProvider` — no feature changes.**

**DONE (code complete):**
- Domain `lib/features/job_matching/domain/`: `Job` + `JobMatch` (Equatable, defensive
  `fromJson`/`fromRanking` — clamps score 0–100, tolerates snake_case/missing fields),
  `JobsRepository` interface, `JobMatchingRepository` interface, `JobMatchingException`/
  `JobMatchErrorCode`.
- Data: `SeedJobsRepository` (loads `assets/data/seed_jobs.json` — 14 realistic roles —
  via `rootBundle`, cached; the jobs-source swap point), `JobMatchingRepositoryImpl`
  (fetch jobs → build localized ranking prompt → `generateJson` → map ids→jobs → sort
  desc; throws `JobMatchingException(noJobs)` / `AiException(invalidResponse)`).
  `jobsRepositoryProvider` + `jobMatchingRepositoryProvider`.
- Application: `JobMatchingController` (`StateNotifier<JobMatchingState>`; states
  needsResume/analyzingResume/matching/success/error). **Decides the initial state in its
  constructor** (cached analysis → matching immediately via `Future.microtask`; else
  needsResume) — mirrors how `LocaleController` hydrates on creation, and avoids a
  post-frame state change that leaked a `flutter_animate` timer in tests.
  `pickAnalyzeAndMatch()` reuses `resumeAnalyzerRepositoryProvider.analyze`, `retry()`,
  `useAnotherResume()` (clears cache), `@visibleForTesting .seeded()`. `JobMatchFailure`
  enum → localized message.
- UI: `JobMatchingScreen` (`ConsumerWidget`, AnimatedSwitcher over the states),
  `JobMatchCard` (compact animated score ring + band, meta chips, reason, matching/missing
  skill chips). Material 3, RTL-aware, branded.
- l10n: ~24 `jobMatch*` keys in EN + AR (incl. a **pluralized** results header
  `jobMatchResultsHeader(int count)`). AI is asked to write the reason in the user's
  language.
- Wiring: `RouteNames.jobMatching` (`/job-matching`) + GoRoute; Home "AI Job Matching"
  card is now `available` (↗, `pushNamed`s). `assets/data/` registered in `pubspec.yaml`.
- Tests: **59 total pass** (was 45; +14). New: `job_match_model_test` (4),
  `job_matching_repository_test` (6 — ranking/sort/lang/invalid ids/noJobs/invalidResponse/
  error propagation with fake `AiService`+`JobsRepository`), `job_matching_screen_test`
  (2, EN+AR results render), + JobMatching added to the locale sweep. `flutter analyze` clean.

**VERIFIED live on emulator with REAL Gemini — both English and Arabic:**
Home card → Job Matching → (no cache) needs-resume prompt → "Upload resume" → SAF picker
(PDF-filtered) → select `sample_resume.pdf` → analyze (M1 reuse) → rank → results:
- **English:** "14 jobs ranked for you"; Flutter Mobile Engineer **95% (Strong match)** with
  an English reason + matching-skill chips; ranked desc down to Fair (40%, orange) and 20%
  (red); "Skills to add" chips render on partial fits.
- **Arabic (RTL):** same flow after switching Settings → Language → العربية; header
  "14 وظيفة مرتّبة لك", all reasons **in Arabic**, correct RTL layout (score ring/left,
  chips flow RTL).
- **Cache path:** leaving and re-entering Job Matching returns straight to results (no
  re-upload). "Use another resume" clears the cache → needs-resume prompt.

**No open blockers.** `flutter analyze` clean; **59 tests pass.**

---

## 7.6 Milestone 3 — AI Career Coach ✅ COMPLETE & VERIFIED

**Scope (approved):** streaming in-app chat assistant for career guidance, learning
roadmaps, interview prep, and skill advice. **Personalized with the cached resume analysis
when available** (generic + suggests the Analyzer otherwise). History **in-memory behind a
swappable `ChatHistoryStore` seam**. Provider-agnostic through `AiService`.

**AI-layer extension (the only change there):**
- `lib/core/services/ai/ai_message.dart` — plain `AiMessage`/`AiRole` value types.
- `AiService.streamChat(List<AiMessage> history, {systemInstruction}) → Stream<String>`
  (single method added); `FirebaseAiService` maps turns → `Content` (user/model) and reuses
  the existing `_model`/`_map`. `streamText` stays for single-shot. No vendor types leak.

**Chat history seam:** `lib/core/services/chat_store/chat_history_store.dart` —
`ChatHistoryStore` interface + `InMemoryChatHistoryStore` + `chatHistoryStoreProvider`
(mirrors the resume store; rebind for Firestore/local persistence later, no feature changes).

**DONE (code complete):**
- Domain `lib/features/career_coach/domain/`: `ChatMessage` (Equatable, `ChatRole`,
  `ChatMessageStatus {complete,streaming,failed}`, `copyWith`), `CareerCoachRepository`
  interface. Failures reuse `AiException`.
- Data: `CareerCoachRepositoryImpl` (+ provider) builds the coach persona system
  instruction (+ resume profile when present; **instructs plain text / no Markdown**),
  maps `ChatMessage`→`AiMessage`, delegates to `streamChat`.
- Application: `CareerCoachController` (`StateNotifier<CareerCoachState>`) — appends the
  user turn + a streaming placeholder, **accumulates tokens into the assistant message**,
  marks complete/failed, persists via the store; `clearChat()`, `retryLast()`,
  `@visibleForTesting .seeded()`; `CoachFailure` enum → localized. Hydrates history from
  the store in its constructor.
- UI: `CareerCoachScreen` (chat list + input bar, empty-state with 4 starter-prompt chips,
  auto-scroll, failure snackbar), `widgets/chat_bubble.dart` (user/assistant bubbles +
  animated typing indicator + retry), `widgets/chat_input.dart` (multiline composer +
  send). Material 3, RTL-aware, branded.
- l10n: ~18 `coach*` keys in EN + AR. Wiring: `RouteNames.careerCoach` (`/career-coach`)
  + GoRoute; Home "Career Coach" card now live.
- Tests: **76 total pass** (was 59; +17). New: `career_coach_repository_test` (6 —
  streaming, history mapping, EN/AR persona, resume personalization, error propagation with
  a fake streaming `AiService`), `career_coach_controller_test` (5 — token accumulation,
  error/empty failure, blank-ignored, clear), `career_coach_screen_test` (4 — conversation
  + empty-state render EN+AR), + CareerCoach in the locale sweep. `flutter analyze` clean.

**VERIFIED live on emulator with REAL streaming Gemini — both English and Arabic:**
Home card → coach → empty state with starter chips → tap a prompt → user bubble + typing
indicator → tokens stream into the assistant bubble → complete reply.
- **English:** in-persona reply (asks a clarifying question); **multi-turn** confirmed —
  after "I aim for senior Flutter roles" the coach gave Flutter/senior-specific guidance
  (architecture, `flutter_test`/`integration_test`, CI/CD, platform channels, mentorship).
- **Arabic (RTL):** replies in Arabic with correct RTL layout; empty state + starter chips
  mirrored. Clear-chat works.
- **Plain-text fix:** an early run showed literal Markdown (`**`, `*`); resolved by
  instructing the model to write plain text (dashes for lists) — re-verified clean, no new
  dependency.

**No open blockers.** `flutter analyze` clean; **76 tests pass.**

---

## 8. Next steps — Phase 2 complete

Milestones 1, 2 & 3 are done, verified, and committed. **Phase 2 (AI Resume Analyzer +
AI Job Matching + AI Career Coach) is COMPLETE.** Nothing is in progress. **Do NOT start a
new milestone until the user approves a plan** (workflow rule).

Candidate future work (all still "Soon" on Home), pending user direction:
- **CV Builder** — guided resume/CV creation (could reuse the `ResumeAnalysis` + `AiService`).
- **Interview Prep** — mock-interview practice (a natural fit for `streamChat`, like the coach).
- **For You / Recommendations** — personalized content from the resume + matches.
- **Durable persistence** — implement a Firestore/local `ResumeAnalysisStore` and
  `ChatHistoryStore` (both seams already exist; just rebind the providers).
- **Markdown rendering** in chat (optional polish; currently the coach is prompted to emit
  plain text instead).

Per the workflow: present a plan, wait for approval, one milestone at a time, verify on the
emulator (both languages), one commit per milestone.

---

## 9. Phase 2 roadmap

- **M1 — AI Resume Analyzer** ✅ *complete & verified (`bf469e6`)*.
- **M2 — AI Job Matching** ✅ *complete & verified* (see §7.5). Ranks a seed job dataset
  against the analyzed resume via `AiService.generateJson`; ranked list with % scores +
  per-job "why it matches". `JobsRepository` interface + `SeedJobsRepository` now; swap in
  a real jobs API with no refactor. Resume analysis reused via `lastResumeAnalysisProvider`
  (persistence-ready store seam).
- **M3 — AI Career Coach** ✅ *complete & verified* (see §7.6). Streaming chat via
  `AiService.streamChat` (multi-turn history), personalized with the cached resume analysis,
  history behind a `ChatHistoryStore` seam. Provider stays swappable through `AiService`.

**Phase 2 is complete.** See §8 for candidate future work.

**Workflow rules (user-mandated):** present a plan per milestone and **wait for
approval before writing code**; implement one milestone at a time; small tasks;
verify each milestone on the emulator before moving on; `flutter analyze` + `flutter
test` before committing; **one Git commit per completed milestone**; don't start the
next milestone until the current is verified. Prefer real integrations over mock UI.

---

## 10. Known issues & environment quirks

**Emulator (`emulator-5554`) rendering/input — important for on-device verification:**
- **Impeller breaks `adb screencap`** (frozen/stale frames). **Always run with
  `--no-enable-impeller`** (Skia) for reliable screenshots.
- **Software GPU (`-gpu swiftshader_indirect`) is unusably slow / crashes.** Launch the
  emulator with **`-gpu host`**.
- **Blur screens** (`AuroraBackground`: Splash/Welcome/Onboarding/UserType) can produce
  stale captures and a **touch offset** (tap target ≈ 2× the rendered y). Even the plain
  **Home** grid needed a mild offset (card was live ~1.2× its drawn y). If a tap "does
  nothing," sweep y and/or try ~2× the drawn position. Non-blur screens
  (email/phone/settings/analyzer) generally map 1:1. `AuroraBackground` itself is a clean
  `Positioned.fill` (no transform) — the offset is an emulator artifact, **not an app bug**.
- **GoRouter `debugLogDiagnostics` logs don't reliably reach logcat/stdout** — don't rely
  on them to detect navigation; use screenshots or native-activity logs (e.g. the file
  picker `PickActivity`, Google OAuth `GenericIdpActivity`).
- These quirks are also recorded in the memory file `emulator-blur-screenshot-quirk.md`.

**Build:** `file_picker` was removed — its Kotlin Gradle Plugin conflicts with Flutter's
built-in Kotlin and breaks `assembleDebug` (`FilePickerPlugin` symbol not found). Use
**`file_selector`** (already done). If you re-add a plugin and the build fails on
`GeneratedPluginRegistrant`, suspect a KGP conflict.

**No functional app bugs open.** `flutter analyze` clean; 45 tests pass.

---

## 11. Verification toolkit (commands & helpers)

```bash
ADB=~/AppData/Local/Android/Sdk/platform-tools/adb.exe
SP=<scratchpad>   # session temp dir

# Emulator: launch cold with host GPU if not running
~/AppData/Local/Android/Sdk/emulator/emulator.exe -avd careerbridge_pixel -gpu host -no-snapshot-load -no-boot-anim &
"$ADB" wait-for-device

# Run the app (Skia renderer for reliable screenshots)
flutter run -d emulator-5554 --no-version-check --no-enable-impeller

# Screenshot helper (raw 1080x2400 is rejected by the Read tool — downscale to 1100px tall).
# scratchpad/shot.py already exists; it shells adb screencap + PIL resize -> 495x1100 PNG.
python "$SP/shot.py" "$SP/out.png"

# Tap / type
"$ADB" -s emulator-5554 shell input tap <x> <y>
"$ADB" -s emulator-5554 shell input text "hello"

# Push the sample resume (MSYS mangles /sdcard -> use // prefix)
"$ADB" -s emulator-5554 push "$SP/sample_resume.pdf" "//sdcard/Download/sample_resume.pdf"
```
- **Sample resume PDF** was generated with Python `fpdf2`
  (`scratchpad/make_resume.py`) and pushed to `/sdcard/Download/sample_resume.pdf`
  (Sarah Ahmed, Flutter engineer — realistic content). Regenerate if the emulator was
  wiped: `pip install fpdf2 && python scratchpad/make_resume.py`.
- **Firestore/Auth REST checks** (Web API key `AIzaSyA2HjyOAHZ392uLX_NAl2WSUwu-HbV5sPQ`,
  Android key `AIzaSyAnw3d7pLb1S1yz2tucfA4b_a1k55tF5tg`): used earlier to verify auth +
  Firestore writes independently of the UI. Beware: bash `UID` is readonly — use another
  var name.

---

## 12. Key files (quick map)

**AI layer** `lib/core/services/ai/`
`ai_service.dart` (interface) · `firebase_ai_service.dart` (Gemini impl + error map) ·
`ai_providers.dart` (`aiServiceProvider`) · `ai_exception.dart`.

**Resume Analyzer** `lib/features/resume_analyzer/`
`domain/`: `resume_analysis.dart`, `resume_analyzer_repository.dart`,
`pdf_text_extractor.dart`, `resume_analyzer_exception.dart`.
`data/`: `resume_analyzer_repository_impl.dart` (+ provider, prompt),
`syncfusion_pdf_text_extractor.dart`.
`application/`: `resume_analyzer_controller.dart` (state + controller + provider).
`presentation/`: `resume_analyzer_screen.dart`, `widgets/{ats_score_gauge,analysis_section}.dart`.

**Job Matching** `lib/features/job_matching/`
`domain/`: `job.dart`, `job_match.dart`, `jobs_repository.dart`,
`job_matching_repository.dart`, `job_matching_exception.dart`.
`data/`: `seed_jobs_repository.dart`, `job_matching_repository_impl.dart` (+ providers,
prompt). Seed data: `assets/data/seed_jobs.json`.
`application/`: `job_matching_controller.dart` (state + controller + provider).
`presentation/`: `job_matching_screen.dart`, `widgets/job_match_card.dart`.
**Resume cache seam** `lib/core/services/resume_store/resume_analysis_store.dart`
(`ResumeAnalysisStore` + in-memory impl + `lastResumeAnalysisProvider`).

**Career Coach** `lib/features/career_coach/`
`domain/`: `chat_message.dart`, `career_coach_repository.dart`.
`data/`: `career_coach_repository_impl.dart` (+ provider, persona/system instruction).
`application/`: `career_coach_controller.dart` (state + controller + provider).
`presentation/`: `career_coach_screen.dart`, `widgets/{chat_bubble,chat_input}.dart`.
**Chat history seam** `lib/core/services/chat_store/chat_history_store.dart`
(`ChatHistoryStore` + in-memory impl + `chatHistoryStoreProvider`).
**AI multi-turn** `lib/core/services/ai/ai_message.dart` (`AiMessage`/`AiRole`) +
`AiService.streamChat` (impl in `firebase_ai_service.dart`).

**Firebase** `lib/core/services/firebase/{firebase_service,firebase_options}.dart` ·
`firebase.json` · `firestore.rules` · `firestore.indexes.json`.

**Auth** `lib/features/auth/` (`domain/auth_repository.dart` interface,
`data/firebase_auth_repository.dart`, `application/auth_providers.dart`,
`presentation/` screens, `auth_navigation.dart` `goAfterAuth`).

**Navigation** `lib/core/navigation/{app_router,route_names}.dart`.
**l10n** `lib/core/localization/l10n/app_{en,ar}.arb` (+ generated).
**Tests** `test/` (`support/fake_auth.dart`, `render_all_locales_test.dart`,
`resume_*` tests, `screens_render_test.dart`, `widget_smoke_test.dart`).

---

## 13. Implementation decisions & conventions (why things are the way they are)

- **AI provider is swappable** by design: all feature code depends on the `AiService`
  interface; only `FirebaseAiService` + the `aiServiceProvider` binding know about
  `firebase_ai`. The interface returns plain Dart (`String` / `Map<String,dynamic>` /
  `Stream<String>`) — no vendor types leak. To switch to Vertex AI: change
  `FirebaseAI.googleAI()` → `FirebaseAI.vertexAI()` (needs Blaze billing). To switch
  vendors entirely: write a new `AiService` and rebind.
- **JSON reliability:** rely on `responseMimeType: application/json` + a very explicit
  prompt describing exact keys, plus **defensive parsing** in `ResumeAnalysis.fromJson`
  (so partial/mistyped AI output degrades gracefully rather than throwing). Gemini
  `responseSchema` is intentionally NOT used yet (keeps the interface vendor-neutral).
- **Text extraction on-device** (Syncfusion, pure Dart) rather than sending the PDF to
  the model — keeps the AI call text-only and provider-agnostic, and satisfies the
  explicit "extract the resume text" requirement. Threshold: `<40` chars ⇒ treat as a
  scanned/no-text PDF (`ResumeErrorCode.noText`); text capped at 20k chars for the prompt.
- **`file_selector`** over `file_picker` (KGP build conflict — §10).
- **Localized AI output:** the repository passes `languageCode` (`en`/`ar`) into the
  prompt ("Write ALL text values in English/Arabic"). UI strings are ARB-localized.
- **Testing:** the real `FirebaseAuthRepository`/`FirebaseAiService` need live backends,
  so tests inject fakes (`FakeAuthRepository`, and per-test fake `AiService`/extractor).
  Render tests use a 412×915 surface and assert `takeException() == null` + correct
  `Directionality` in EN and AR. Test fixtures use
  `// ignore_for_file: prefer_const_literals_to_create_immutables`.
- **Navigation:** forward = `push*` (preserve back stack); reset = `go*`. Verified back
  behavior end-to-end in Phase 1.5.
- **Firebase client keys are committed** in `firebase_options.dart` (not secrets);
  `google-services.json` stays gitignored. `firestore.rules` is the source of truth for
  Firestore access and must be redeployed after edits.
- **Memory files** exist under the session memory dir
  (`careerbridge-project.md`, `emulator-blur-screenshot-quirk.md`) and are indexed in
  `MEMORY.md` — consult/update them.

---

## 14. TL;DR for the next session

**Milestones 1, 2 & 3 are DONE, verified live in EN + AR with real Gemini, and committed**
on `feature/resume-analyzer` (M1 `bf469e6`; M2 `8f2101f`; M3 is the latest commit — see §6).
**Phase 2 is COMPLETE.** `flutter analyze` clean, **76 tests pass**, repo clean. Firebase AI
Logic is enabled + provisioned (§5). **Next:** nothing is in progress — present a plan for
any new milestone (§8 lists candidates) and **wait for the user's approval before coding**.
Keep the conventions in §13; run with `--no-enable-impeller`; the test account session is
persisted so the app opens to Home. (Note: the persisted app language is currently Arabic
after M3 verification.)
