# Career Bridge — Session Handoff

> Living handoff doc so a fresh Claude session can continue immediately.
> Last updated: **Employer polish (see §7.38)** — Company completion fix (needs `firestore.rules` redeploy) + Logo upload
> now works with **no Storage bucket** (Firestore data-URI) + **Interview** and **Candidates** AI tools shipped (were
> "Coming Soon"). `analyze` clean, **691 tests**.
> Prior update: **Role Selection regression FIXED** (see §7.37) — new users no longer skip the role picker; routing is now
> Firestore-authoritative per-user (was reading a device-global cache).
> Earlier: **Email-Only Auth + Email Verification — COMPLETE** (see §7.29, feat `356a290`) — a deliberate MVP
> **scope cut**: Google Sign-In is **fully removed** (UI + logic + widget + l10n + enum + test fake) and replaced by a
> hard **email-verification gate**. Flow now: sign up → Firebase **auto-sends** a verification email → land on a new
> **Verify-email screen** (clear message, **"I've verified — Continue"** = `reload()` + re-check, **"Resend
> verification email"** with a 30s cooldown + confirmation snackbar, **"Use a different account"** = sign out). Sign-in
> and the **splash** now both **block** an unverified user (`!emailVerified` → verify screen) — a persisted unverified
> session can never reach home. `AppUser` gained `emailVerified` (mapped from `user.emailVerified`); `AuthMethod` is now
> `{email, phone}` (google removed); repo gained `sendEmailVerification()` + `reloadEmailVerified()`, `registerWithEmail`
> now `sendEmailVerification()` on success; `signInWithGoogle`/`_classifyGoogleError`/`GoogleGlyph`/`AuthMethodButton`
> deleted; `errConfiguration` reworded provider-neutral (enum kept, still mapped). Welcome screen is now a
> `StatelessWidget` with a single "Continue with Email". New route `verifyEmail` (`/auth/verify-email`). `analyze` clean
> · **602 tests** (+6: verify-flow behavior + Welcome-no-Google + EmailVerify render sweep EN/AR) · release `.apk`
> (73.1 MB) under R8. **Live-verified on the RELEASE APK**: the pre-existing unverified session auto-gated to the
> verify screen; Resend → "Verification email sent." + "Resend in 30s"; "I've verified" while unverified stays on the
> gate; "Use a different account" → Google-free Welcome; **registered a fresh account → auto-sent email → verify
> screen**. The one path not machine-verifiable is the actual inbox click (no real mailbox for `@cb.app`) — the
> verified→home continuation runs `reloadEmailVerified()` then `goAfterAuth` and works once the user taps the real link.
> (Google Sign-In console config from the prior turn is now moot but harmless; `google-services.json` stays gitignored.)
>
> **Final MVP Stabilization — Qatar everywhere + Google Sign-In diagnostics — COMPLETE** (see §7.28, feat dbf47cb) — an MVP-finishing **bug-fix / stabilization** pass (no new features). Reconciled five prioritized
> real-device reports against the code, extended the fixes where they were incomplete, and **verified on the RELEASE
> APK** (EN + AR). **(1) Google Sign-In** — added real diagnostics: `signInWithGoogle` no longer routes through `_guard`
> (which only caught `FirebaseAuthException`); it now catches **platform-level** failures too, **logs the raw
> type/code/message** to logcat for on-device diagnosis, and maps a non-Firebase failure via `_classifyGoogleError`
> (cancel→cancelled, network→network, else→**configurationError**). Root cause is unchanged and **not code-fixable**:
> `google-services.json` still has **`oauth_client: []`** (0 entries) → the Google provider isn't enabled / no SHA-1 →
> a real device can't complete the OAuth handshake (Firebase-console step, see `docs/GOOGLE_SIGNIN_SETUP.md`). **(2)
> "Vertical text" (For You → recommended job → Job Details)** — already root-caused + fixed in §7.27 (the `_MatchSection`
> `Expanded`+button `Row`, now stacked); **re-reproduced the exact flow on the RELEASE APK at 360dp + font 1.8 in EN and
> AR** and confirmed the match prompt wraps normally (no char-per-char). **(3) Qatar default everywhere** — §7.27 did
> Browse + Coach; this pass extends the **same `CountriesData.defaultCountry` default to Job Matching**
> (`job_matching_controller`), **Interview** (`interview_controller` → `InterviewContext.country`), and the **job-detail
> on-demand match** (`job_detail_controller`), so all AI market context is Qatar independent of the persisted profile
> country. Live: Browse = **13 jobs (Qatar + remote)** EN + AR — the Dubai/Cairo cards that read as "other countries"
> are **remote** roles (globe icon), intentionally included. **(4) Arabic** — job descriptions already localize
> (`descriptionFor(lang)`, all 18 seed jobs) — reconfirmed the recommended-job detail shows Arabic on the RELEASE APK;
> the **PDF "SQL→LQS"** concern is **already correct** — verified by generating the ATS PDF (Arabic doc) and running
> `pdftotext`: `SQL`/`Python`/`Flutter`/`PostgreSQL`/`Node.js` all keep their letter order (pdf 3.13 defaults
> `useBidi=true` → `bidi.logicalToVisual` on the per-string RTL runs the §7.26 fix already set). `analyze` clean ·
> **596 tests** (+1) · release `.apk` (73.1 MB) builds under R8. Both earlier bugs the user still saw were from the
> **older released APK** predating these fixes. Regression guard added: interview context defaults to Qatar even with a
> non-Qatar profile country persisted.
>
> **Follow-up Stabilization — job-detail vertical text + Qatar defaults — COMPLETE** (see §7.27, feat
> `6cfcc97`) — a **bug-fix / stabilization** round (no new features) for real-device reports still open after the prior
> 9-fix milestone. Each was **reproduced live before touching code**. **(2) "Vertical text" in Job Details (For You →
> Recommended → View Job)** — the prior fix targeted the internship label→value row in `job_detail_view.dart`, but the
> REAL culprit is the seeker **`_MatchSection` in `job_detail_screen.dart`**: each match-prompt state paired an
> `Expanded(message)` with an **unconstrained action button** (Analyze resume / See match / Retry) in one `Row`; on a
> narrow device with a large system font the button starves the message to a sliver → Flutter wraps it
> character-by-character. Recommended jobs open this panel in the **no-resume** state (wide "Analyze resume" button), so
> the For You path surfaced it. **Fix:** the action stacks **beneath** the message (full-width message, end-aligned
> action); loading state (no button) unchanged; score row → `Wrap`. Reproduced at **360dp + font scale 1.8** (EN + AR)
> and confirmed fixed. **(3) Browse Jobs defaults to Qatar** (`CountriesData.defaultCountry`) **independent of the
> persisted profile country** — it previously seeded from the profile country, so a device whose onboarding country
> isn't Qatar never opened on Qatar; still changeable in the filter sheet. **(4) Career Coach bases advice on Qatar** —
> the country was only a soft "tailor … when relevant" system hint (replies drifted global); now a **firm directive**
> (name Qatar cities/employers, quote QAR, default all figures to Qatar) mirroring Job Matching + coach market defaults
> to Qatar; verified live (Doha / QAR / "in Qatar" / "في قطر"). **(1) Google Sign-In** re-verified **app-side correct**
> (Firebase `signInWithProvider` + `configurationError` mapping + runbook); root cause remains Firebase console config
> (empty `oauth_client`, no SHA-1) — **user-side, no code change**. `analyze` clean · **595 tests** (+3) · release `.apk`
> (73.1 MB) builds under R8 · **live-verified EN + AR**. Known limitation: the Home AI-toolkit feature grid overflows at
> extreme font scale (≥1.8) on narrow devices (pre-existing `childAspectRatio`, out of reported scope — see §10).
>
> **Stabilization Milestone (9 bug fixes) — COMPLETE** (see §7.26) — a **bug-fix / stabilization**
> milestone (no new features): root-cause fixes, existing behavior preserved, no architecture change. `analyze` clean ·
> **592 tests** (+18) · release `.apk` builds under R8 · **live-verified EN + AR** on the release build. **(1) Google
> Sign-In** — root cause is Firebase config (empty `oauth_client`, no SHA-1), not code; added a clearer
> `AuthErrorCode.configurationError` mapping + **`docs/GOOGLE_SIGNIN_SETUP.md`** runbook (debug SHA-1/256 + console
> steps — user-side). **(2/3) Job/Internship Details layout** — internship label→value row now **responsive** (stacks
> under ~260px so a long word can't be squeezed into a sliver and wrap char-by-char) + meta chips/badges hardened
> (`Flexible`+ellipsis, no narrow overflow); all job-detail entry points already share one route (Coach/Recommended ==
> Browse). **(4) RTL/bidi "SQL"→"LQS"** — was **PDF-only**; `ats_template` now picks direction **per text run** (Latin
> LTR, Arabic RTL) instead of a page-level rtl; the Flutter UI was already correct. **(5) Default country Qatar** —
> `CountryController` defaults to Qatar; Browse Jobs opens country-scoped (remote always included) + a country filter in
> the sheet; country threaded into Job Matching/Coach/Interview prompts; user can change/clear. **(6) Currency QAR** —
> new offline peg-based `CurrencyConverter`; internship stipend shows **"QAR 4,368 (~ USD 1,200)"**; defaults→QAR.
> **(7) Arabic job content** — `titleAr`/`descriptionAr`/`locationAr` on `Job` + all **18 seed jobs** (natural Arabic),
> shown when locale=ar with **English fallback**; employmentType/seniority chips localized. **(8) Interview** — **Copy**
> button on "Sample strong answer" → clipboard + "Copied to clipboard." snackbar. **(9) CV PDF** — adaptive per-link
> scheme-stripped URLs (long GitHub/LinkedIn no longer overflow). feat `a603549`.
> **Phase 7 · Milestone 5 (Deployment & Publishing) — COMPLETE** (see §7.25) — a **review /
> reconcile / verify / sign-off** milestone that finishes **every remaining production task except the actual Play
> upload**. Behavior-preserving: no new deps, no rules change, no architectural impact. **One code change** — the
> Android manifest now **strips the advertising ID** (`com.google.android.gms.permission.AD_ID`, merged by
> `firebase_analytics`) via `tools:node="remove"`, **verified absent from the merged release manifest** and guarded by
> new `test/android_manifest_test.dart` (+3 tests → **574**) — so the "no ads / no advertising ID" Play declaration is
> provably true at the artifact level. **Doc drift closed** (the P7·M1 store kit predated M2–M4): `USE_BIOMETRIC` added
> to the Play permissions/Data-Safety docs; biometric + secure-storage declared **device-local / not collected**; the
> `resumes`/`learning` collections confirmed covered; test baseline 466→574; store listing (EN + AR) now surfaces
> biometric login / multiple CVs / internships / learning. **New headline doc `docs/PRODUCTION_READINESS.md`** — an
> evidence-backed **Go/No-Go report** (final status table + all 9 dimensions + a "Remaining Before Publish" checklist of
> only the non-automatable manual actions), cross-linking (not duplicating) RELEASE.md / RELEASE_CHECKLIST.md.
> **Security audit clean** (secrets gitignored & untracked, no hardcoded secrets, App Check debug token not in code,
> only normal permissions, no cleartext). `analyze` clean · **574 tests** · release `.apk` (73.0 MB) + `.aab` (71.3 MB)
> build under R8 · **live-verified EN + AR on the release build** (Home incl. Internships/Learning tiles → Settings →
> Arabic RTL; a host-GPU/Impeller raster crash on `-gpu host` was isolated to the emulator per §10 and cleanly rendered
> under `-gpu swiftshader_indirect`). Remaining before publish are **all user-side manual steps** (real keystore, host
> legal docs, Storage bucket, App Check enforce, Play Console). feat (this milestone).
> **Phase 7 · Milestone 4 (Internships & Learning) — COMPLETE** (see §7.24) — extends the job platform
> with **internships** and a **learning-interests** profile, **reusing the existing Job / JobPosting / Application
> architecture** (no parallel jobs stack). Internship metadata (funding · category · level · duration · **work mode
> remote/hybrid/on-site** · **university eligibility** · **schedule** · **certificate** · stipend · **start/deadline
> dates**) is an **embedded `InternshipDetails`** on `Job` + `JobPosting` (the `SalaryRange`/`JobMetrics` pattern, enums
> in **shared** so the seeker `Job` never imports `features/employer`); `toJob()` projects it + `trainsBeginners` so the
> shared `JobDetailView` renders an "Internship details" card + **Internship / Trains-beginners badges** (employer
> preview == seeker view). New seeker **Internships browse** (scoped consumer of `JobsRepository` + facet filters;
> detail reuses `/jobs/:id`). Employer job editor gains an **internship section** + a **"Train Beginners" toggle** (badge
> now; **recommendation-weight hook only — no AI**). New core seam **`LearningProfileRepository`** (`users/{uid}/learning/
> interests`; interface + Firestore-only-importer impl + in-memory + provider) behind a seeker **Learning Interests**
> screen (5 categories, add/edit/delete/search, offline-bounded save). `Application` gains a denormalized **`isInternship`**
> (stamped at apply) + an **Internships filter**; apply/track/withdraw reuse the flow unchanged (incl. multi-CV picker).
> Also fixed a **latent seeker `_ActionBar` infinite-width bug** (§7.14 pattern) surfaced live by internships→job-detail;
> job-detail tests now use the real `AppTheme`. `analyze` clean · **571 tests** (+44) · **live-verified EN + AR** (seeker
> `appreg030157@cb.app`, real Firestore) · `users/{uid}/learning` rules **deployed**. feat `0dc6274`.
> **Phase 7 · Milestone 3 (Multiple CV Repository) — COMPLETE** (see §7.23) — a **Firestore-backed**
> `resumes/{resumeId}` repository for **multiple CVs** (create/import/rename/duplicate/archive/restore/set-default/
> soft-delete), each carrying its own analysis/ATS/matches/recommendations; **tags** + **last-used** + **default
> protection** (always ≥1 active CV) + **auto-default** + **import dedup**. Core seam `CvRepository` (interface +
> Firestore impl + in-memory + providers) so CV Builder (optional `cvId` edit-and-save-back) + AI features integrate
> via **core only** (zero feature-to-feature deps). Apply flow gains a **CV picker** (≥2 CVs, remembers last). Home
> "My CVs" tile; `resumes` rules **deployed**. `analyze` clean · **527 tests** (+33) · **live-verified EN + AR** with
> real Firestore (create→persist→auto-default, default-protection block, RTL library). feat `0b01504`.
> **Phase 7 · Milestone 2 (Authentication Enhancements) — COMPLETE** (see §7.22) — **phone verification by
> linking** (strengthens the existing account, never a phone-only sign-in) + **biometric login** (app-launch gate over
> the persisted Firebase session; enrol once, "Not Now" remembered; availability-gated; logout/password-change
> invalidate) + a new **Security Settings** screen. Two new vendor-neutral core seams (`BiometricService` [local_auth],
> `SecureStore` [flutter_secure_storage] — store only the preference + trusted-device marker, never passwords). Existing
> users unaffected (biometric off ⇒ identical flow, no migration). `MainActivity`→`FlutterFragmentActivity`. `analyze`
> clean · **494 tests** (+28) · **live-verified EN + AR** (fingerprint enrol/enable, app-lock unlock, RTL Security). feat `09d78cb`.
> **Phase 7 · Milestone 1 (Deployment Preparation — Google Play) — COMPLETE** (see §7.21) — **docs-only**, zero code/deps/config change: a full **Play submission kit** under `docs/store/` (store listing EN **+ Arabic**, asset specs incl. screenshot order, Data Safety, Play Console declarations, master release checklist) + **legal docs** under `docs/legal/` (Privacy Policy + Terms, with AI-transparency + ad-free commitment). Validation = `analyze` clean · **466 tests** · **release `.aab` builds**. App preserved exactly — no regressions.
> **Phase 6 · Milestone 4 (Production Polish) — COMPLETE** (see §7.20) — shared `StatusView` (loading/empty/error) unifies 8 screens, a11y semantics + tooltips, audits clean; live-verified EN + AR on the **release build**. **466 tests.** Production-readiness report in §7.20.
> **Phase 6 · Milestone 3 (Release Preparation) — COMPLETE** (see §7.19) — live-verified EN + AR on the **release build** (bundled fonts, offline banner, R8/minify on). Release runbook + QA checklist in `docs/`.
> **Phase 6 · Milestone 2 (Security & Performance) — COMPLETE** (see §7.18) — live-verified EN + AR on `employer01@cb.app` (App Check active on device w/ graceful fallback, hardened rules deployed, no regressions).
> **Phase 6 · Milestone 1 (Production Ready — Firebase & Backend) — COMPLETE** (see §7.17) — live-verified EN + AR on `employer01@cb.app` (real Firebase Analytics/Crashlytics/FCM on device).
> **Phase 2 COMPLETE** (M1 Resume Analyzer + M2 Job Matching + M3 Career Coach).
> **Phase 3 · M1 (Jobs Platform) COMPLETE** (`6a6a72c`, §7.7).
> **Phase 3 · M2 (Applications Center) COMPLETE** (`b7e4b53`, §7.8).
> **Phase 3 · M3 (User Profile & Settings) COMPLETE** (`071902c`, §7.9) — live-verified EN+AR.
> **Phase 4 · M1 (AI CV Builder) COMPLETE** (`b237481`, §7.10) — live-verified EN (full flow) + AR.
> **Phase 4 · M2 (AI Interview Prep) COMPLETE** (`fc35db4`, §7.11) — live-verified EN + AR (real Gemini).
> **Phase 4 · M3 (AI Recommendations / For You) COMPLETE** (`c1d044b`, §7.12) — live-verified EN + AR (real Gemini). **Last "Soon" Home card is now live — the AI toolkit is complete.**
> **Phase 5 · M1 (Employer Dashboard — Company Foundation) COMPLETE** (`baf5801`, §7.13) — live-verified EN + AR. **First employer-side milestone: role-based landing + Company Profile/Settings/Dashboard over a Firestore-ready `CompanyRepository`.**
> **Phase 5 · M2 (Employer Job Management) COMPLETE** (§7.14) — live-verified EN + AR on `employer01@cb.app`. **Full employer job lifecycle: My Jobs (search/filter/sort) → create/edit with debounced auto-save + two-tier validation → preview (shared `JobDetailView`, exactly as a seeker sees it) → publish-with-confirmation → archive-with-reason/close/reopen/duplicate/soft-delete, all optimistic with rollback.** A `JobPosting` management superset `toJob()`-projects to the seeker `Job`; a separate write-path `EmployerJobsRepository` (`jobs/{jobId}`) leaves the read-only seeker `JobsRepository` untouched. `flutter analyze` clean; **329 tests pass**; `jobs/{jobId}` rules deployed.
> **Phase 5 · M3 (Employer Applicants Management) COMPLETE** (§7.15) — live-verified EN + AR on `employer01@cb.app` (real Firestore, seeded applicants). **Grouped-by-job applicants inbox (stats/search/status-filter/sort) → rich applicant detail (AI match, resume analysis, resume-file graceful, skills, links, interview readiness, timeline, private notes) → status pipeline (Move to Review/Interview/Accept/Reject, appends history) + note CRUD, all optimistic with rollback.** The **shared `Application`** was extended (dual-keyed applicantUid/ownerUid + denormalized versioned `ApplicantSnapshot` + `source`) so the employer reads the exact doc the seeker's Applications Center does — no cross-user private reads. Separate `EmployerApplicantsRepository` + owner-private `EmployerNotesRepository` (`applicationNotes`) + `EmployerActivityRepository` (`employerActivity`, audit foundation). `flutter analyze` clean; **375 tests pass** (+46); `applications`/`applicationNotes`/`employerActivity` rules deployed.
> **Phase 5 · M4 (Employer Analytics) COMPLETE** (§7.16) — live-verified EN + AR on `employer01@cb.app` (real Firestore, seeded applicants + real Gemini). **Read-only hiring dashboard: KPI overview → application status funnel → top jobs → time-to-hire → applicant-quality distribution → applications trend, plus an on-demand AI Recruiter Insights card (strengths/bottlenecks/suggested actions, grounded in the metrics).** All computed live by a **pure `AnalyticsCalculator`** over the employer's existing jobs/applicants/activity streams (no new data sources, no new Firestore collections/rules). The AI layer **reuses the Recommendations pattern exactly** (primitive context + signature → `AiService.generateJson` → defensive parse → latest-only `RecruiterInsightsStore` seam + refresh guard). Charts are plain-Flutter/`FractionallySizedBox` (no new deps). **Zero product-feature-to-feature deps.** `flutter analyze` clean; **412 tests pass** (+37); **no Firestore rules change**. AI Company Strength deferred to a future milestone.
> **Phase 6 · M2 (Security & Performance) COMPLETE** (§7.18) — live-verified EN + AR on `employer01@cb.app`. **Three pillars, all following the established patterns:** **(A) Security** — a sixth vendor-neutral core service **Firebase App Check** (`AppCheckService` interface + `FirebaseAppCheckService` [only file importing `firebase_app_check`] + Noop + provider), activated **non-blocking after `runApp`** (mandate: never delays the first frame; on failure records + continues — proven live: App Check API disabled → placeholder token → app fully usable), plus a **`SecurityAuditLog`** foundation (routes auth-failure/permission-denied/rule-violation/app-check-failure to Analytics `security_event` + Crashlytics; wired at the two owner-scoped employer streams' permission-denied path), plus **hardened `firestore.rules`** (validation helpers: identity-field immutability `ownerUid`/`applicantUid`/`companyId`, size caps — the owner-update path can no longer repoint an applicant's identity — **deployed**) and **hardened `storage.rules`** (content-type + size caps, authored). **(B) Performance** — explicit Firestore `Settings` (persistence + 40 MB bounded cache), `.limit(300)` runaway guards on the employer streams. **(C) Image optimization** — dependency-free `AppImage.provider` decode-downsizing seam (built-in `ResizeImage`, no `cached_network_image`/KGP risk) routed through **all 7** avatar/logo sites + error-resilient `ApplicantAvatar`; upload-side `ImageOptimizer` (pure `dart:ui` downscale, never-enlarge) folded into the media seams. **Zero product-feature-to-feature deps.** `firebase_app_check` added + **build-verified** (no new KGP warning). `flutter analyze` clean; **449 tests pass** (+11). **Manual console steps** (App Check API enable + enforcement, Storage bucket, debug-token allow-listing, release providers) documented in §5.
> **Phase 6 · M1 (Production Ready — Firebase & Backend) COMPLETE** (§7.17) — live-verified EN + AR on `employer01@cb.app` (real on-device Firebase). **Five vendor-neutral core services, each interface + single Firebase impl + Noop/in-memory + swap-point provider (the `AiService` pattern):** **Storage** (`StorageService` with upload progress + delete/replace + optional `StorageMetadata`; the two media seams `ProfileImageStorage`/`CompanyLogoStorage` rebased on it, + profile-photo/company-logo progress UI + Remove action), **Push Notifications** (`NotificationService` + `FirebaseNotificationService` absorbing the old `MessagingService`, token refresh, `PushTokenRegistrar` seam, + a `PushPreferences` category foundation), **Analytics** (`AnalyticsService` + vendor-neutral `AnalyticsRouteObserver` screen_views + `AnalyticsEvents` at key seams + a persisted **consent** lever), **Crashlytics** (`CrashReporter` + `FlutterError`/`PlatformDispatcher` handlers + user context uid/account_type), **Performance** (`PerformanceMonitor`/`PerfTrace` + upload traces). All telemetry **best-effort, non-blocking**. `firebase_analytics`/`crashlytics`/`performance` added; **build-verified**. Crashlytics/Performance **Gradle plugins deferred** (AGP 9 compat; runtime SDKs work without them). Live Storage upload **deferred** (default bucket unprovisioned). **Zero product-feature-to-feature deps; no new Firestore rules.** `flutter analyze` clean; **438 tests pass** (+26).

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
`providers`, `services/{ai,firebase,storage (local prefs),cloud_storage (Firebase
Storage),messaging,analytics,crashlytics,performance,document, + the store/repository
seams}`, `theme`, `utils`). Reused widgets/models under `lib/shared/`. **Every external
capability sits behind a vendor-neutral interface with a single Firebase impl (the only
file importing that plugin), a Noop/in-memory impl, and one swap-point provider** — the
`AiService` pattern, applied to Storage/Notifications/Analytics/Crashlytics/Performance
in P6·M1.

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
→ User Type (Job Seeker/Employer) → {Home | Employer Home}`. **Role-based landing (P5·M1):**
`splash`/`goAfterAuth`/`user_type_selection` branch on `UserType` — **employers → `/employer`
(Employer Home)**, job seekers → `/home`. Logout clears the persisted role.

**Job-seeker Home** shows an "AI toolkit" grid; **Resume Analyzer**, **AI Job Matching**,
**Career Coach**, **CV Builder**, **Interview Prep**, and **For You / Recommendations** are
all live. **No "Soon" cards remain — the AI toolkit is complete.** Home also has **Browse
Jobs** + **My Applications** CTAs.

**Employer Home** shows company header + quick stats (Active jobs derive from published jobs;
Applications/Interviews/Hires derive from the applicants stream), company-profile completion, a
Company Profile entry, a **Manage jobs** CTA, an **Analytics & insights** CTA (live ↗), and recruiting-tool
tiles: **Post a Job** (live ↗) and **Applicants** (live ↗); Interviews/Candidates remain "Soon". Settings is
shared by both roles (its account card is role-aware → Company Profile for employers). **The employer side is
complete: Company Foundation (M1) + Job Management (M2) + Applicants Management (M3) + Analytics (M4).**

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

### Phase 2 · Milestone 3 — AI Career Coach ✅ COMPLETE (committed `89ee1a1`)
See §7.6. Streaming chat assistant (`AiService.streamChat`) with multi-turn history,
personalized with the cached resume analysis when available, history behind a
`ChatHistoryStore` seam. **Verified live end-to-end on the emulator in both English and
Arabic** with real streaming Gemini output (incl. multi-turn context). `flutter analyze`
clean; **76 tests pass**. No open blockers. **Phase 2 is now complete.**

### Phase 3 · Milestone 1 — Jobs Platform ✅ COMPLETE (committed `6a6a72c`)
See §7.7. Browsable jobs experience (search/filter, detail, save, mock apply) over the
shared jobs foundation, integrating Resume Analyzer, Job Matching, and Career Coach.
`flutter analyze` clean; **99 tests pass**. Partially verified live (Arabic browse); the
full both-language on-device pass was curtailed by an emulator GPU/input failure — see
§7.7 and §10.

### Phase 3 · Milestone 2 — Applications Center ✅ COMPLETE (committed `b7e4b53`)
See §7.8. My Applications + Saved + Statistics + status/history, over a Stream-based,
Firestore-ready `ApplicationsRepository`. Mock Apply (from a job) now creates an
`Application`; integrates all four earlier features with **zero feature-to-feature
dependencies**. `flutter analyze` clean; **118 tests pass**. Live-verified: Home renders
both CTAs (Arabic); the Applications hub/detail are test-verified but not cleanly captured
live (same emulator quirk — §10).

### Phase 3 · Milestone 3 — User Profile & Settings ✅ COMPLETE (committed `071902c`)
See §7.9. Extended `UserProfile` (headline/location/bio/photo + **skills, experience
level (Entry→Lead), preferred job titles, portfolio/github/linkedin links**), a profile
**completion indicator**, Edit Profile, change/upload photo (via `ProfileImageStorage` →
Firebase Storage), change password (email reauth), granular notification preferences, and
an enhanced Settings — over a Stream-based, Firestore-ready `UserProfileRepository` with
**zero feature-to-feature dependencies**. `flutter analyze` clean; **153 tests pass**.
**Live-verified EN+AR** incl. a functional Edit→Save (Firestore persist, completion
10%→50%). One env caveat: **Firebase Storage isn't provisioned yet** (photo upload degrades
to a localized error until the console "Get Started" is run + `storage.rules` deployed).

### Phase 4 · Milestone 1 — AI CV Builder ✅ COMPLETE (committed `b237481`)
See §7.10. Builds a professional CV **from the profile (+ reused resume analysis)**, allows
manual editing, an **AI enhancement** step (summary + achievement bullets + ATS skills),
**multiple registered templates** (ATS implemented; Modern/Minimal/Harvard show "Coming
soon"), and a **WYSIWYG PDF preview/export** via `pdf` + `printing`. Zero feature-to-feature
deps. `flutter analyze` clean; **179 tests pass**. **Live-verified**: EN full flow (manual
edit → real-Gemini enhance → ATS PDF preview + share); AR form/template-picker RTL + Arabic
PDF (RTL, Arabic section headers). Known limitation: pure-Latin runs can render reversed in
the Arabic PDF (pdf-package bidi) — Arabic content is correct; a follow-up refinement.

### Phase 5 · Milestone 1 — Employer Dashboard: Company Foundation ✅ COMPLETE (committed `baf5801`)
See §7.13. The **first employer-side** milestone. **Role-based landing** (employers → a new
`/employer` dashboard; job seekers → `/home`, branch on `UserType` + route names only in
`splash`/`goAfterAuth`/`user_type_selection`; logout clears the role). A **shared `Company`
model** + core **`CompanyRepository`** (Firestore `companies/{companyId}`, `companyId == ownerUid`)
+ **`CompanyLogoStorage`** seam (over `CloudStorageService`) — single-binding swap points. New
`lib/features/employer/`: **Employer Home** (quick stats, completion, company CTA, "Soon"
recruiting tools), **Company Profile**, **Edit Company** (name/industry/size/website/HQ/
description/contact + social links + logo). **Company Settings** = the shared Settings screen made
role-aware. Forward-ready fields: `verificationStatus`, `companySlug` (auto-derived on save),
social links, and an embedded `CompanyStrength` (future AI profile-quality score — no refactor).
Promoted `CompletionIndicator` → `shared/widgets`. **Zero product-feature-to-feature deps.**
`flutter analyze` clean; **270 tests pass**. **Live-verified EN + AR**; `firestore.rules`
(companies) deployed.

### Phase 5 · Milestone 2 — Employer Job Management ✅ COMPLETE (feat `1ecba6f`, docs `d2030b0`)
See §7.14. Full employer job lifecycle: **My Jobs** (search/status-filter/sort) → **create/edit**
(debounced draft auto-save + two-tier validation + unsaved-changes guard) → **preview** (the shared
`JobDetailView`, exactly as a seeker sees it) → **publish-with-confirmation** → archive-with-reason/
close/reopen/duplicate/soft-delete — all **optimistic with rollback**. A `JobPosting` management
superset `toJob()`-projects to the seeker `Job`; a separate write-path `EmployerJobsRepository`
(`jobs/{jobId}`) leaves the read-only seeker `JobsRepository` untouched. Employer Home gains a
"Manage jobs" CTA + live "Post a Job". **Zero product-feature-to-feature deps.** `flutter analyze`
clean; **329 tests pass**. **Live-verified EN + AR** on `employer01@cb.app`; `jobs/{jobId}` rule
deployed. Three device-only bugs found + fixed (query-vs-rule field, theme full-width buttons,
dialog controller-after-dispose — see §7.14).

### Phase 5 · Milestone 3 — Employer Applicants Management ✅ COMPLETE (feat `8d241a6`, docs `d0810d5`)
See §7.15. Employers review + manage applicants for every published job over the **same shared
applications foundation** the seeker Applications Center uses. Because rules keep each user's
profile/resume/interview data private, everything the employer needs is **denormalized onto the
application at apply time** (a versioned `ApplicantSnapshot`). Grouped-by-job **inbox**
(stats/search/status-filter/sort) → rich **applicant detail** (AI match, resume analysis, resume-file
graceful-degrade, skills, links, interview readiness, timeline, **private notes**) → **status
pipeline** (Move to Review/Interview/Accept/Reject, appends history) + **note CRUD**, all optimistic
with rollback. Extended shared `Application` (dual-keyed `applicantUid`/`ownerUid` + `source`);
separate `EmployerApplicantsRepository` + owner-private `EmployerNotesRepository` + an
`EmployerActivityRepository` audit foundation. Promoted `StatusChip`/`StatusTimeline` → `shared/widgets`.
**Zero product-feature-to-feature deps.** `flutter analyze` clean; **375 tests pass**. **Live-verified
EN + AR** on `employer01@cb.app` (real Firestore, seeded applicants); `applications`/`applicationNotes`/
`employerActivity` rules deployed.

### Phase 5 · Milestone 4 — Employer Analytics ✅ COMPLETE (feat + docs)
See §7.16. A read-only hiring **analytics dashboard** for the employer — KPI overview, application status
funnel, top jobs, time-to-hire, applicant-quality distribution, and an applications trend — plus an on-demand
**AI Recruiter Insights** card (strengths / bottlenecks / suggested actions). Everything derives live from the
employer's own jobs/applicants/activity streams via a **pure, exhaustively-tested `AnalyticsCalculator`**; the AI
layer **reuses the Recommendations architecture** (primitive context + signature → `AiService.generateJson` →
defensive parse → latest-only `RecruiterInsightsStore` seam + refresh guard). Custom charts are plain Flutter
(no new deps). **Zero product-feature-to-feature deps; no new Firestore collections or rules.** `flutter analyze`
clean; **412 tests pass** (+37). **Live-verified EN + AR** on `employer01@cb.app` with real Firestore + real
Gemini. AI Company Strength intentionally **deferred** to a future milestone.

### Phase 4 · Milestone 3 — AI Recommendations / For You ✅ COMPLETE (committed `c1d044b`)
See §7.12. A personalized **For You** hub: **one holistic `generateJson` pass** over the
user's profile, resume analysis, CV, applications, and interview history → **Recommended
jobs** (confidence % + reason), **Skills to learn**, **Certifications**, **Courses**, an
action-oriented **Career roadmap** (This week / Next month / Next 3 months / 6–12 months),
and **Next best actions** (priority + estimated time + in-app deep links). Every item carries
a personalized reason. Recommended jobs are chosen by id from the **shared** jobs universe
(excludes already-applied) so cards deep-link to `/jobs/:id`. Provider-agnostic (`AiService`),
Firestore-ready `RecommendationsStore` (caches only the latest), a **refresh guard** that
skips the AI call when the source-data signature (incl. language) is unchanged. **Zero
feature-to-feature deps** — reuses **core** providers only. `flutter analyze` clean; **238
tests pass**. **Live-verified EN + AR** with real Gemini. Flips the **last "Soon" Home card**
live.

### Phase 4 · Milestone 2 — AI Interview Prep ✅ COMPLETE (committed `fc35db4`)
See §7.11. Pick an interview type (HR/Technical/Behavioral) → answer AI-generated questions
with **scored per-answer feedback** (5 dimensions) → a **streamed overall debrief** + a
scorecard + **improvement plan**. Reuses profile + resume analysis + CV + optional job (all
via **core** providers); history behind a **Firestore-ready** `InterviewHistoryRepository`
seam. `generateJson` for questions/evaluation, `streamText` for the debrief. Zero
feature-to-feature deps. `flutter analyze` clean; **212 tests pass**. **Live-verified EN + AR**
with real Gemini. Models are shaped so a future **Interview Report PDF** is a pure function of
`InterviewSession` (no refactor). Also promoted `CvDraftStore` → `core/services/cv_store`.

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
- ⚠️ **Cloud Storage** — the default bucket is **still NOT provisioned** (carried since P3·M3).
  `firebase deploy --only storage` fails with "Firebase Storage has not been set up". Needs
  Console → Storage → **Get Started** (may need Blaze); can't be done headlessly here
  (`gcloud`/`gsutil` absent). Until then all uploads degrade gracefully to a localized error.
  P6·M1 wired the full Storage stack (`StorageService`, progress, delete/replace) behind this.
- ✅ **Firebase Analytics / Crashlytics / Performance (P6·M1)** — SDKs added + initialize on
  device (verified: FA "App measurement initialized", Crashlytics 19.4.4). **No Console setup was
  required** for basic collection. **Deferred:** the Crashlytics + Performance **Gradle plugins**
  (AGP 9 compat — §7.17/§10); the runtime SDKs work without them (they only add release
  mapping-upload + auto-instrumentation).
- ⚠️ **Firebase App Check (P6·M2)** — SDK added + **activates on device** (debug provider;
  `DefaultTokenRefresher` running). The **App Check API is NOT yet enabled** in the project, so
  token fetch 403s → **placeholder token** and the app keeps working (**enforcement is OFF —
  monitoring only**, the intended graceful state). To finish/enforce, see the **Manual production
  console steps** checklist below (enable API → allow-list the debug token → register Play
  Integrity → then enforce).
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

> **See `docs/RELEASE.md` for the full, reproducible release runbook** (build/sign/publish + every manual step below,
> plus the `docs/QA_CHECKLIST.md`). The checklist here is the authoritative source that RELEASE.md §7 mirrors.

**Manual production console steps (deployment checklist — nothing here can be done
headlessly from this environment; `gcloud`/`gsutil` absent).** These are the ONLY
non-code steps between the current state and a fully-locked-down production backend.
The app runs correctly today without any of them (everything degrades gracefully):

1. **App Check — enable the API + register the debug token, then (later) enforce.**
   - The app **activates App Check on device** (debug provider in debug builds, Play
     Integrity in release) — verified live (`DebugAppCheckProvider` registered). But
     the **App Check API is not yet enabled** in the project, so token fetch returns
     `403 "Firebase App Check API has not been used in project 894890748117…"` and the
     SDK falls back to a **placeholder token** — the app keeps working because
     **enforcement is OFF** (monitoring only). This is the intended graceful state.
   - To finish: **(a)** enable `firebaseappcheck.googleapis.com` (Console → App Check,
     or the API library link in the 403). **(b)** Register the **debug token** printed
     in logcat on each debug device: `Enter this debug secret into the allow list…`
     (current emulator token: `e7834c02-c137-4fd7-beba-b34e41928abb` — **debug-only,
     regenerated per install/keystore; do NOT ship it**). Console → App Check → Apps →
     the Android app → **Manage debug tokens**. **(c)** Register the **Play Integrity**
     provider for the release app (SHA-256 in Console). **(d)** Only once real traffic
     shows tokens validating: **App Check → enforce** on Firestore / Storage / (and AI
     Logic if desired). Enforcing before (a)–(c) would lock out all clients.
2. **Cloud Storage bucket** (carried since P3·M3): Console → Storage → **Get Started**
   (creates the default `.firebasestorage.app` bucket; may need Blaze), then
   `firebase deploy --only storage` to push the **hardened `storage.rules`** (content-type
   + size caps — authored in P6·M2, compiles, but can't deploy until the bucket exists).
   Until then all uploads degrade to a localized error.
3. **Crashlytics + Performance Gradle plugins** (deferred in P6·M1 for AGP-9 KGP risk):
   add `com.google.firebase.crashlytics` + `com.google.firebase.firebase-perf` once
   AGP-9-compatible versions are confirmed, then build-verify immediately.
4. **App Check API note for tests/CI/headless runs:** if a future automated run signs in
   without a registered debug token AND enforcement is later turned on, reads will be
   denied — keep enforcement off until CI has a token strategy.

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
feature/resume-analyzer  *  (HEAD)   docs: HANDOFF consistency pass for Phase 6 Milestone 1  <-- current HEAD
                             bb62aac  docs: HANDOFF for Phase 6 Milestone 1
                             2e4c706  feat: Production-ready Firebase infrastructure (Phase 6, Milestone 1)
                             3f1ff4a  docs: HANDOFF for Phase 5 Milestone 4
                             9932422  feat: Employer Analytics (Phase 5, Milestone 4)
                             d0810d5  docs: HANDOFF for Phase 5 Milestone 3
                             8d241a6  feat: Employer Applicants Management (Phase 5, Milestone 3)
                             d2030b0  docs: HANDOFF for Phase 5 Milestone 2
                             1ecba6f  feat: Employer Job Management (Phase 5, Milestone 2)
                             3681109  docs: HANDOFF for Phase 5 Milestone 1
                             baf5801  feat: Employer Dashboard — Company Foundation (Phase 5, Milestone 1)
                             c1d044b  feat: AI Recommendations / For You (Phase 4, Milestone 3)
                             fc35db4  feat: AI Interview Prep (Phase 4, Milestone 2)
                             b237481  feat: AI CV Builder (Phase 4, Milestone 1)
                             071902c  feat: User Profile & Settings (Phase 3, Milestone 3)
                             b7e4b53  feat: Applications Center (Phase 3, Milestone 2)
                             6a6a72c  feat: Jobs Platform (Phase 3, Milestone 1)
                             89ee1a1  feat: AI Career Coach (Phase 2, Milestone 3)
                             8f2101f  feat: AI Job Matching (Phase 2, Milestone 2)
                             bf469e6  feat: AI Resume Analyzer (Phase 2, Milestone 1)
                            (each milestone: 1 feat commit + a follow-up docs commit updating this file)
                             branched from firebase-auth-integration
```
- **Latest employer-side commits: P5 M1 `baf5801` (Company Foundation); P5 M2 `1ecba6f` (Job
  Management); P5 M3 `8d241a6` (Applicants Management); P5 M4 `9932422` (Employer Analytics) — each +
  a docs commit.** Neither `firebase-auth-integration` nor `feature/resume-analyzer` is merged to
  `main`, and nothing is pushed to any remote. (No PRs opened.)
- Commit message convention: end with
  `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`.
- **Do NOT commit** `.claude/settings.local.json` (local). Exclude it from `git add`.

**Working tree is clean** — every milestone through P5·M4 is committed. The **only**
uncommitted file is `.claude/settings.local.json` (intentionally excluded from `git add`).
Each milestone is one `feat` commit + a follow-up `docs` commit updating this file; nothing is
merged to `main` and nothing is pushed to any remote (no PRs).

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

## 7.7 Phase 3 · Milestone 1 — Jobs Platform ✅ COMPLETE (`6a6a72c`)

**Scope (approved):** make jobs first-class — **browse/search/filter, job detail, save,
mock apply** — over a shared, repository-based jobs foundation (real API swappable later),
integrated with Resume Analyzer, Job Matching, and Career Coach.

**Shared jobs foundation (refactor — extracted from `job_matching`):**
- `Job` model → `lib/shared/models/job.dart`.
- `JobsRepository` + new `JobQuery` + `SeedJobsRepository` + `jobsRepositoryProvider` →
  `lib/core/services/jobs/`. `JobsRepository` gained `fetchJobById(id)` and
  `searchJobs(JobQuery)` (text + type/seniority/remote filters + offset/limit), applied
  in-memory by the seed repo; a `RemoteJobsRepository` drops in unchanged.
- `JobInteractionsStore` seam (`lib/core/services/jobs/job_interactions_store.dart`):
  saved + applied job-id sets, in-memory now, rebindable to Firestore/local (mirrors the
  resume/chat store seams). `jobInteractionsProvider` (reactive).
- **Intentional one-directional dependency:** `job_matching` and `jobs` both depend on
  this shared foundation; additionally `jobs` depends on `job_matching` for the AI match
  pieces (`JobMatch`, `jobMatchingRepositoryProvider`, `JobMatchingController`) — the Jobs
  platform is a *consumer* of the matching capability. Documented, not accidental.

**Feature `lib/features/jobs/`:**
- `application/`: `JobsBrowseController` (live `JobQuery` search/filter + derived filter
  options), `JobDetailController` (`.family` by id; loads job + on-demand per-job match).
- `presentation/`: `JobsScreen` — **segmented** All / Best matches / Saved (segmented, not
  TabBarView, so the Best-matches AI ranking only runs when that segment is opened);
  `JobDetailScreen`; widgets `job_list_tile`, `job_filter_sheet`.
- **Integrations:** detail shows an on-demand resume **match** (new
  `JobMatchingRepository.matchJob()` scores a single job; falls back to a "analyze your
  resume" prompt when none cached); **Best matches** reuses `JobMatchingController`
  unchanged; **"Ask the coach about this job"** deep-links to `/career-coach` with a seeded
  prompt via GoRoute `extra` (Career Coach now accepts an optional `seedPrompt`).
- **Mock Apply:** records an in-app "Applied" state via `JobInteractionsStore`.
- Wiring: `RouteNames.jobs` (`/jobs`) + `jobDetail` (`/jobs/:id`); a **"Browse Jobs" CTA**
  on Home; ~25 `jobs*` EN+AR keys (incl. pluralized counts).
- Tests: **99 total pass** (was 76; +23): `seed_jobs_repository_test` (7 — search/filter/
  by-id/pagination via a fake `AssetBundle`), `jobs_browse_controller_test` (3),
  `job_detail_controller_test` (3), `job_interactions_test` (3), `matchJob` (1),
  `jobs_screen_test` (2 EN+AR), `job_detail_screen_test` (2 EN+AR), + Jobs in the locale
  sweep. `flutter analyze` clean.

**Verification status (READ THIS):**
- **Live-verified (Arabic, Skia):** Home "Browse Jobs" CTA renders; the **Jobs browse
  screen** renders fully — 14 seed jobs, All/Best-matches/Saved segments, search field,
  filter button, tiles (title/company/meta-chips/bookmark). Navigation Home→Jobs→detail
  works.
- **Bug found on-device & FIXED:** the job **detail** screen crashed layout with an
  unbounded-width button (`Column(Expanded(ListView) + action bar)` gave the bottom bar
  infinite width). **Fix:** moved the action bar to the Scaffold `bottomNavigationBar`
  slot (bounded) and made the body just the scrollable. Verified: no layout errors in
  logcat post-fix; covered by the EN+AR `job_detail_screen_test`.
- **Not cleanly captured live:** detail render post-fix, English UI, save/apply/coach
  deep-link — the emulator degraded mid-session (wedged Home input, then a corrupted GPU
  surface → all-black; a `-gpu host` cold-boot restored rendering but the Home "Browse
  Jobs" CTA still dropped taps intermittently). This is the documented emulator quirk
  (§10), **not an app defect** — app-side correctness is backed by the 99-test suite
  (which renders both `JobsScreen` and `JobDetailScreen` in EN + AR). **A fresh session
  should re-verify the detail + integrations on a healthy `-gpu host` emulator.**

---

## 7.8 Phase 3 · Milestone 2 — Applications Center ✅ COMPLETE (`b7e4b53`)

**Scope (approved):** My Applications, Saved Jobs, Application Status (Pending/Reviewed/
Interview/Accepted/Rejected), mock Apply integrated with Jobs, Application History,
search/filter, Statistics (Applied/Saved/Interviews/Offers) — repository-based,
Firestore-ready, **no feature-to-feature dependencies**.

**Shared applications foundation (core/services + shared/models):**
- `lib/shared/models/application.dart` — `Application` (Equatable) + `ApplicationStatus`
  enum + `ApplicationEvent` history; **denormalized job snapshot** (title/company/location)
  captured at apply time; defensive `toJson`/`fromJson` (tolerates snake_case, bad status →
  pending, ISO/millis dates) for Firestore round-trip.
- `lib/core/services/applications/`: `ApplicationsRepository` interface — **Stream-based**
  `watchApplications()` (maps 1:1 to Firestore `.snapshots()`) + `apply` (idempotent per
  jobId) / `updateStatus` (appends history) / `withdraw` / `findByJobId`.
  `InMemoryApplicationsRepository` (broadcast stream + **injectable clock**).
  `applicationsRepositoryProvider` (swap point) + `applicationsProvider` (StreamProvider) +
  `appliedJobIdsProvider` (derives "applied" — single source of truth).
- **Narrowed** the old `JobInteractionsStore` → `saved_jobs_store.dart` (`SavedJobsStore`,
  saved-only); `savedJobsProvider`. Applied state is no longer a bare id-set.

**Feature `lib/features/applications/`:**
- `application/applications_controller.dart`: `ApplicationsFilter`(+controller),
  `filteredApplicationsProvider`, `applicationStatsProvider` (interviews = reached-interview
  via history; offers = accepted), `savedJobsListProvider` (resolves saved ids → `Job` via
  the core `jobsRepositoryProvider`), `applicationByIdProvider`.
- `presentation/`: `ApplicationsScreen` (Stats header + segmented **My Applications /
  Saved** + search/status filter), `ApplicationDetailScreen` (status **history timeline** +
  **user-driven status controls** + View job + interview-prep coach deep-link + withdraw).
  Widgets: `status_chip`, `stats_card`, `application_tile`, `status_timeline`,
  `application_filter_sheet`.

**Integrations — all via shared core + navigation (zero feature-to-feature imports, verified):**
- **Jobs:** mock Apply → `applicationsRepository.apply(job)` (Pending); the "Applied" badge
  derives from `appliedJobIdsProvider`; a "View application" snackbar action → the app.
- **Job Matching:** reached by navigation (application → `/jobs/:id`, where `matchJob` lives).
- **Career Coach:** interview-stage → `/career-coach` with a seeded prompt (GoRoute `extra`).
- **Resume Analyzer:** empty states link to `/resume-analyzer`.
- Wiring: `RouteNames.applications` (`/applications`) + `applicationDetail`
  (`/applications/:id`); a **"My Applications" Home CTA** + a **Jobs app-bar action**;
  ~30 `apps*`/`status*`/`stat*` EN+AR keys. `intl` `DateFormat` for localized dates.

**Tests: 118 total pass** (was 99; +19 net): `application_model_test` (5),
`applications_repository_test` (6), `applications_providers_test` (4 — stats + filter),
`applications_screen_test` (2 EN+AR), `application_detail_screen_test` (2 EN+AR),
`saved_jobs_store_test` (2); Applications added to the locale sweep; removed the old
`job_interactions_test`. `flutter analyze` clean.

**Verification status:** Home renders **both CTAs** (Browse Jobs + My Applications) live in
Arabic. The Applications hub/detail + apply flow are **test-verified (incl. EN+AR renders)
but were NOT cleanly captured live** — the emulator hit the same documented quirk (§10):
Home-CTA taps dropped intermittently and the job-detail surface froze (no logcat errors;
env, not app). **Next session: re-verify Applications live on a healthy `-gpu host` emulator
(same follow-up as M1's job detail).**

---

## 7.9 Phase 3 · Milestone 3 — User Profile & Settings ✅ COMPLETE (`071902c`)

**Scope (approved):** Profile screen · Edit Profile · profile **completion indicator** ·
upload/change profile photo (Firebase Storage) · language selection · granular notification
preferences · change password (email users) · logout · Settings — plus the approved optional
fields **skills**, **experience level** (enum Entry/Junior/Mid/Senior/Lead), **preferred job
titles**, and **portfolio/github/linkedin links** (all optional, all feed the completion %,
all shaped to be reused by AI features + a future Employer Dashboard). Repository-based,
Firestore-ready, **no feature-to-feature dependencies**.

**Shared profile foundation (core/services + shared/models):**
- `lib/shared/models/user_profile.dart` — `UserProfile` (Equatable, `copyWith`, defensive
  `toJson`/`fromJson` tolerating snake_case / list-or-comma-string / bad enums / ISO+millis+
  Timestamp dates) + `ProfileField` enum. `completion`/`completionPercent`/`missingFields`
  over 10 tracked fields. `ExperienceLevel` enum in `features/profile/domain/`.
- `lib/core/services/user_profile/` — `UserProfileRepository` **interface** (`watchProfile`
  Stream + `fetchProfile`/`saveProfile`/`ensureProfile`/`setUserType`/`setPhotoUrl`);
  `FirestoreUserProfileRepository` (default, `.doc(uid).snapshots()`, degrades to no-op/empty
  when Firebase not ready) + `InMemoryUserProfileRepository` (tests). Providers:
  `userProfileRepositoryProvider` (swap point) + `userProfileProvider` (StreamProvider,
  tracks the auth uid). The **old** concrete `features/profile/data/user_profile_repository.dart`
  was promoted to this interface; the two call sites (`auth_navigation.ensureProfile`,
  `user_type_selection.setUserType`) updated to the new import.
- `profile_image_storage.dart` — `ProfileImageStorage` seam (Firebase impl delegates to the
  existing `CloudStorageService.uploadBytes` + `profilePhotoPath`; fake for tests).
- Photo picking reuses **`file_selector`** (image type group) — **no new plugin** (§10 KGP).

**Notification preferences:** `features/settings/domain/notification_preferences.dart`
(`NotificationPreferences` master+jobAlerts+applicationUpdates+coachTips, with `effective*`
getters gating on master) behind a `NotificationPreferencesStore` seam (`notification_preferences_store.dart`,
local storage). `NotificationsController` now holds the model (`setMaster`/`setJobAlerts`/…).

**Auth contract extension (reused existing infra):** `changePassword({currentPassword,
newPassword})` (EmailAuthProvider reauth → updatePassword) + `updateProfile({displayName?,
photoUrl?})` on `AuthRepository` + `FirebaseAuthRepository` + `FakeAuthRepository`.

**Feature `lib/features/profile/`:**
- `application/`: `ProfileEditController` (save → `saveProfile` + auth `updateProfile`),
  `ProfilePhotoController` (pick→`uploadBytes` seam→`setPhotoUrl`+auth; `uploadBytes` is
  `@visibleForTesting`), `ChangePasswordController` (local validation emptyFields/tooShort/
  mismatch, then auth), `currentUserProfileProvider` (stored merged with auth fallback) +
  `profileCompletionProvider`.
- `presentation/`: enhanced `ProfileScreen` (avatar/headline/location + completion ring +
  Edit button + info card with experience level + Skills/Preferred-titles/Links sections),
  new `EditProfileScreen` (photo editor + fields + `ChipInput` for skills & preferred titles
  + experience `ChoiceChip`s + links + save), new `ChangePasswordScreen`; enhanced
  `SettingsScreen` (granular notification switches + change-password entry for email users).
  Widgets `completion_indicator.dart`, `chip_input.dart`; `profile_l10n.dart` maps the enums.
- Routes: `RouteNames.editProfile` (`/settings/profile/edit`, nested under profile) +
  `changePassword` (`/settings/change-password`). ~35 EN+AR l10n keys.

**Firebase / Storage:** extended fields live in the existing `users/{uid}` doc — **no
Firestore rules change** (own-doc access already allowed). **`storage.rules` added** (authed
user r/w `users/{uid}/**`) + wired into `firebase.json`. ⚠️ **Firebase Storage is NOT
provisioned yet** — `firebase deploy --only storage` fails with "Storage has not been set up";
needs the Console → Storage → **Get Started** (default `.firebasestorage.app` bucket, may need
Blaze), then deploy the rules. Until then the photo upload returns null → a localized
"couldn't upload your photo" error; **all other M3 features work on live Firestore + Auth.**

**Tests: 153 total pass** (was 118; +35): `user_profile_model_test` (7 — completion math,
missing fields, round-trip, snake_case/comma-string, bad-value tolerance, dates),
`user_profile_repository_test` (4), `change_password_controller_test` (5), `profile_photo_controller_test`
(3), `notification_preferences_test` (3), `profile_screen_test` (2 EN+AR),
`edit_profile_screen_test` (2 EN+AR), `change_password_screen_test` (4 EN+AR render+mismatch);
EditProfile+ChangePassword added to the locale sweep. `flutter analyze` clean.

**VERIFIED live on emulator — both English and Arabic:** Settings (granular notifications +
change-password entry), Profile (completion ring, Edit button, info card), Edit Profile (all
fields incl. Skills/Experience level/Preferred job titles/Links) with a **functional
Edit→Save** — snackbar "Profile saved", **completion 10%→50%**, experience level + chips
persisted to Firestore and re-rendered after a language switch — and Change Password
(mismatch validation snackbar). Reached Settings via `flutter run --route=/settings` because
the documented Home app-bar tap-drop quirk (§10) blocked the gear; body taps worked fine.

**Note for verification:** `flutter run --route=/settings` (or any deep route) is a handy
workaround for the flaky Home app-bar — but Git Bash mangles the path; prefix the command
with `MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL="*"`.

---

## 7.10 Phase 4 · Milestone 1 — AI CV Builder ✅ COMPLETE (`b237481`)

**Scope (approved):** build a CV **from the profile whenever possible**, allow **manual
editing before generating**, support **multiple templates** (start with one ATS-friendly),
export a **professional PDF**, and be structured so **new templates need no refactor**. Plus
two approved additions: **reuse the cached `ResumeAnalysis`** (summary/strengths/skills/ATS
suggestions), and **register 4 templates now** (ATS, Modern, Minimal, Harvard) with only ATS
implemented (others "Coming soon").

**Dependency decision (approved Option A):** added **`pdf`** (pure-Dart document build) +
**`printing`** (in-app `PdfPreview` + native share/print). **Debug APK build verified first —
no Gradle/KGP conflict** (the risk flagged from `file_picker`). The `CvPdfGenerator` interface
preserves the Syncfusion fallback with no feature-code change.

**Feature `lib/features/cv_builder/` (zero feature-to-feature deps — reaches Profile only via
the core `currentUserProfileProvider` + `lastResumeAnalysisProvider`):**
- `domain/cv_data.dart` — `CvData` (+ `CvExperience`/`CvEducation`/`CvProject`), defensive
  JSON, and **`CvData.fromProfile(UserProfile, {user, analysis})`** which seeds contact/skills/
  links/target-role from the profile and **the summary from the reused `ResumeAnalysis`** (else
  the profile bio).
- `domain/cv_enhancement_repository.dart` (+ impl) — builds a localized prompt from the CV
  (+ the resume analysis strengths/missingSkills/suggestions + target role) → `AiService.
  generateJson` → **merges** a polished summary, achievement bullets, and ATS skills back into
  `CvData`, **preserving factual fields**. Defensive-parsed; throws `CvBuilderException`.
- `domain/cv_template.dart` — `CvTemplateId {ats, modern, minimal, harvard}` +
  `cvTemplateCatalog` (ATS `available:true`; rest `false`). `domain/cv_pdf_generator.dart` =
  the `CvPdfGenerator` **swap seam** + `CvLabels`. `data/pdf/pdf_cv_generator.dart` maps id →
  `PdfTemplate` (throws `templateUnavailable` for coming-soon), loads fonts via `CvFonts`
  (`PdfGoogleFonts` Noto + Arabic, built-in fallback). `data/templates/ats_template.dart` =
  single-column ATS layout (`pw` widgets, RTL-aware, brand accents). **Add a template later:
  new `PdfTemplate` + flip the catalog flag — nothing else changes.**
- `application/`: `CvBuilderController` (needsProfile/editing/enhancing; seeds from profile+
  analysis or resumes a `CvDraftStore` draft) + `CvDraftStore` seam (in-memory → Firestore
  later). `presentation/`: `CvBuilderScreen` (edit form + experience/education **entry-editor
  sheets** + skills `ChipInput` + target role + **Enhance with AI**), `widgets/cv_template_picker.dart`
  (ATS selectable, others "Soon"), `CvPreviewScreen` (`printing` `PdfPreview` → share/print).
- **Wiring:** routes `cvBuilder` (`/cv-builder`) + `cvPreview` (`/cv-builder/preview`); Home
  CV Builder card now `available`. ~45 EN+AR `cv*` l10n keys. **`ChipInput` promoted from
  `features/profile/presentation/widgets/` to `lib/shared/widgets/`** (reused by CV skills;
  keeps zero feature-to-feature coupling). **`PrimaryButton`** now ellipsizes long labels
  (Flexible) — fixed an RTL overflow on the long "Enhance with AI" Arabic label.

**Tests: 179 total pass** (was 153; +26): `cv_data_test` (7 — seed + resume reuse + json +
defensive), `cv_enhancement_repository_test` (5 — merge/omit/lang/empty/error via a fake
`AiService`), `cv_pdf_generator_test` (4 — EN/AR bytes with built-in fonts + coming-soon
throws), `cv_builder_controller_test` (5), `cv_builder_screen_test` (2 EN+AR); CvBuilder +
CvPreview added to the locale sweep. `flutter analyze` clean.

**VERIFIED live on emulator:**
- **English (full flow):** `--route=/cv-builder` → manual edit (name/headline + an experience
  with a crude highlight "built-app-and-improved-speed") → **Enhance with AI** wrote a
  professional summary, **rewrote the crude bullet into two achievement statements**, and
  **expanded skills** with ATS keywords (real Gemini) → **ATS PDF preview rendered WYSIWYG**
  (bullets/·/— all render via Noto) with the **print + share** bar.
- **Arabic (RTL):** form + entry-editor sheets + template picker all RTL with Arabic labels
  (القالب: ATS selected, عصري/بسيط = قريبا); the **Enhance button fits (no overflow)**; the
  Arabic PDF renders **RTL with correct Arabic section headers** (الخبرات …).

**Known limitation (follow-up):** pure-**Latin** runs can render **reversed** inside the
Arabic (RTL) PDF — a `pdf`-package bidi limitation. **Arabic content renders correctly** (and
the AI writes content in the user's language, so an Arabic-mode CV gets Arabic content). Fix
later via per-run bidi / not forcing page-level rtl.

**Seed note:** entering `/cv-builder` *directly* via `--route` constructs the controller
before the auth→Firestore stream resolves, so the form starts empty (the "Reset from profile"
↻ action re-seeds once resolved). The **normal Home → CV Builder path** has the profile already
cached, so it seeds fully — the empty start is a `--route` artifact, not a bug.

---

## 7.11 Phase 4 · Milestone 2 — AI Interview Prep ✅ COMPLETE (`fc35db4`)

**Scope (approved):** generate interview questions (AI); **HR / Technical / Behavioral** types;
reuse profile + CV + resume analysis + job matching when available; **stream where
appropriate**; evaluate answers with **detailed feedback** + **scores** (overall, communication,
technical accuracy, confidence, clarity) + **improvement suggestions**; **interview history**
through a repository seam; Firestore-ready; provider-agnostic; EN+AR; integrate with Career
Coach + Jobs. Plus the approved addition: models shaped for a future **Interview Report PDF**
(no refactor). **Streaming decision (approved):** `generateJson` for questions + per-answer
evaluation (reliable scores); `streamText` only for the final debrief.

**Store promotion (approved):** `CvDraftStore` + `cvDraftStoreProvider` moved from
`features/cv_builder/application/` → **`lib/core/services/cv_store/`** (alongside resume/chat
stores) so Interview Prep reuses the CV via a core provider — zero feature→feature coupling.
`CvData` stays in `cv_builder/domain` (imported as a type, like `ResumeAnalysis`).

**Domain `lib/features/interview_prep/domain/`:** `interview_models.dart` — `InterviewType`
{hr,technical,behavioral} + `InterviewStatus`; `InterviewQuestion`/`InterviewAnswer`;
`InterviewScores` (5 dims, **clamped 0–100**); `AnswerFeedback` (scores+feedback+strengths+
improvements+sampleAnswer); `InterviewSummary` (scores + overallFeedback + keyStrengths +
improvementSuggestions + **improvementPlan**); `InterviewSession` (denormalized role/jobTitle;
`create`/`withAnswer`/`completed`; `overallScore`/`answerFor`/`feedbackFor`). **Report-ready:**
Overall Score / Type / Date / Strengths / Suggestions / Plan all derive from the session.
Defensive `toJson/fromJson` (ISO/millis/Timestamp, bad enum→default). `interview_context.dart`
(primitive reuse bundle) · `interview_repository.dart` (interface) · `interview_exception.dart`.

**Data:** `interview_repository_impl.dart` (+ `interviewRepositoryProvider`) — pure (takes an
`InterviewContext`), builds localized prompts, defensive-parsed. `generateQuestions`
(`generateJson`, throws `noQuestions`), `evaluateAnswer` (`generateJson`, throws
`emptyEvaluation`), `summarize` (`generateJson` scorecard), `streamDebrief` (`streamText`).
Prompts instruct plain text / no Markdown (coach convention).

**History seam (core, Firestore-ready — Applications pattern):**
`lib/core/services/interview_store/` — `InterviewHistoryRepository` interface (`watchSessions`
Stream + `saveSession`/`findById`/`delete`) + `InMemoryInterviewHistoryRepository` (broadcast) +
`interviewHistoryRepositoryProvider` (swap point) + `interviewSessionsProvider` (StreamProvider).
**Rebind for Firestore `users/{uid}/interviews` later — needs a subcollection rule then (the
current `users/{uid}` rule doesn't cascade); in-memory now, so no rules change this milestone.**

**Application/presentation `lib/features/interview_prep/`:** `InterviewController`
(phases setup/generating/inProgress/summarizing/summary/error; `buildContext` from
`currentUserProfileProvider` + `lastResumeAnalysisProvider` + `cvDraftStoreProvider` + job;
`start`/`submitAnswer`/`nextQuestion`/`finish` (streams debrief → `summarize` → persist);
`InterviewFailure` enum). `InterviewPrepScreen` (AnimatedSwitcher over phases; type picker →
one-question-at-a-time Q&A with a 5-dim `_FeedbackCard` → summary with `OverallScoreGauge` +
`ScoreBars` + strengths/suggestions/plan + coach deep-link + practice-again),
`InterviewHistoryScreen`, `InterviewSessionDetailScreen`, `interview_l10n.dart`,
`widgets/score_display.dart`.

**Wiring/integrations (via core providers + navigation, zero feature→feature imports):** routes
`interviewPrep` (`/interview-prep`, optional `extra: Job`) + `interviewHistory`
(`/interview-prep/history`) + `interviewSessionDetail` (`…/history/:id`); Home Interview Prep
card now live; **Jobs detail app-bar "Practice interview"** → `/interview-prep` `extra: job`;
**summary "Discuss with the coach"** → `/career-coach` seeded prompt. ~55 EN+AR `interview*` keys.

**Tests: 212 total pass** (was 179; +33): `interview_models_test` (5), `interview_repository_test`
(8 — fake `AiService`: questions/eval/summary/stream/empty/error/language), `interview_history_repository_test`
(3), `interview_controller_test` (5 — start→answer→finish→persist + failure mapping),
`interview_prep_screen_test` (2 EN+AR), `interview_history_screen_test` (2 EN+AR),
`interview_prep_flow_test` (4 — feedback + summary render EN+AR); InterviewPrep+InterviewHistory
in the locale sweep. `flutter analyze` clean.

**VERIFIED live on emulator with REAL Gemini — both English and Arabic:**
- **Arabic (full loop):** Technical interview → generated real DS&A / DB / system-design /
  debugging questions (RTL, focus chips) → typed answer → per-answer evaluation renders (score
  gauge + Arabic feedback + strengths ✓ + improvements → + sample answer) → multi-question
  progression (Question 1→2→3 of 5, progress bar).
- **English:** setup (type cards LTR) → generated HR question ("Focus: Motivation") → answer →
  feedback card (score gauge + Strengths + To improve, clean plain text, no Markdown).

**Bugs found on-device & FIXED:** (1) a **non-uniform `Border` + `borderRadius`** in the card
widget threw "borderRadius can only be given on borders with uniform colors" → blanked the
feedback card; fixed to a uniform accent-tinted border. (2) an **`ExpansionTile` inside a
`DecoratedBox`** (no Material ancestor) threw a ListTile-background assertion → replaced the
sample-answer with a plain block. (3) a small **score-gauge overflow** at size 44 (fixed:
scale font to size, hide "/100" when small). (4) the model emitted **Markdown** in the sample
answer → added a "plain text, no Markdown" instruction to the eval/summary prompts. Added
`interview_prep_flow_test` (feedback + summary render) so this class of bug is caught by CI.

**Seed note (same as CV Builder):** entering `/interview-prep` directly via `--route` starts
with an empty (general) context because auth→Firestore hasn't resolved; the **normal Home →
Interview Prep path** has the profile cached and personalizes fully.

---

## 7.12 Phase 4 · Milestone 3 — AI Recommendations / For You ✅ COMPLETE (`c1d044b`)

**Scope (approved):** a personalized "For You" module reusing **all** existing user data
(profile, resume analysis, CV, job matching, interview prep, applications) to produce
**Recommended jobs, Skills to learn, Certifications, Courses, Career roadmap, Next best
actions** — provider-agnostic, repository-based, Firestore-ready, EN+AR, **zero
feature-to-feature deps**. Approved additions: (1) every item has a personalized reason;
(2) job recs carry a **confidence 0–100**; (3) roadmap uses **practical horizons** (This
week / Next month / Next 3 months / 6–12 months); (4) next actions have an optional
**estimated time**; (5) a **refresh guard** that skips the AI call and says "up to date"
when nothing changed.

**Three approved architecture decisions:** (1) **one holistic `generateJson` call** for all
six sections with per-section defensive parsing; (2) **AI-generated job recs using the shared
jobs foundation** (not by importing `job_matching`) — the model picks by id from the real
jobs universe; (3) **cache only the latest** via a `RecommendationsStore` seam.

**Domain `lib/features/recommendations/domain/`:** `recommendation_models.dart` —
`Recommendations` (+ `generatedAt` + **`sourceSignature`** + `headline`/`summary` + six
section lists; `hasContent`; `stamp(...)`) · `JobRecommendation` (jobId/title/company/reason/
**confidence**) · `SkillRecommendation` (skill/reason/**priority**) · `CertificationRecommendation`
· `CourseRecommendation` (title/provider/reason/url?/skill?) · `RoadmapStep` (**horizon**/title/
description/focusSkills) · `NextAction` (**type**/title/description/priority/**estimatedTime**/
targetId). Enums `RecPriority`, `RecHorizon {thisWeek,nextMonth,next3Months,sixToTwelveMonths}`,
`NextActionType {analyzeResume,buildCv,practiceInterview,browseJobs,reviewApplications,
completeProfile,applyToJob,learnSkill,none}` — all defensively parsed (bad enum → default).
`recommendation_context.dart` — `RecommendationContext` (**primitives only**, like
`InterviewContext`) + `AvailableJob` mini-type + `hasSignal` + a **`signature`** fingerprint
(all salient signals except the static jobs universe; includes appliedJobIds). Plus
`recommendations_repository.dart` (interface) + `recommendations_exception.dart` (`RecErrorCode.
emptyRecommendations`).

**Data:** `recommendations_repository_impl.dart` (+ `recommendationsRepositoryProvider`) — pure,
builds one localized holistic prompt (`_system` forbids Markdown; `_contextBlock` +
`_jobsBlock` listing available jobs by id, excluding applied), calls `AiService.generateJson`,
**filters recommended jobs to the real universe by id** (drops invented/applied ids; backfills
title/company), throws `emptyRecommendations` only when every section is empty.

**Store seam (core, Firestore-ready):** `lib/core/services/recommendations_store/` —
`RecommendationsStore` interface (`watchLatest` Stream + `read`/`save`/`clear`) +
`InMemoryRecommendationsStore` (broadcast) + `recommendationsStoreProvider` (swap point) +
`latestRecommendationsProvider`. Rebind for a Firestore `users/{uid}/recommendations/latest`
doc later — no feature changes (needs a subcollection rule then; in-memory now, no rules change).

**Application/presentation:** `RecommendationsController` (phases loading/ready/error;
`buildContext()` reads **core providers only** — `currentUserProfileProvider` (precedent:
Interview Prep/CV Builder), `lastResumeAnalysisProvider`, `cvDraftStoreProvider`,
`applicationsProvider`/`interviewSessionsProvider` (via `.future`), `savedJobsProvider`,
`jobsRepositoryProvider`; ctor hydrates from the store else `Future.microtask(generate)`;
`refresh()`/`retry()`; **refresh guard** compares `"$lang::${context.signature}"` to the
cached signature → "up to date" without an AI call; injectable clock; `.seeded` ctor).
`RecommendationsScreen` (AnimatedSwitcher over loading/error/ready; header card with headline/
summary/updated-date/low-signal nudge; six sections; app-bar Refresh; deep-links job cards →
`/jobs/:id` and next-actions → their routes). `recommendations_l10n.dart` (enum→label maps),
`widgets/recommendation_sections.dart` (RecSection/RecCard/RecChip/RecReason/RecJobCard/
RecSkillTile/RecCertTile/RecCourseTile/RecRoadmap timeline/RecActionCard).

**Wiring:** `RouteNames.recommendations` (`/recommendations`) + GoRoute; Home "For You" card
flipped `route: null` → live. ~45 `rec*` EN+AR l10n keys (incl. `recConfidence(int)` +
`recUpdated(String)` placeholders). Localized dates via `intl DateFormat`.

**Tests: 238 total pass** (was 212; +26): `recommendation_models_test` (7 — defensive parse,
clamp, enum aliases, round-trip, stamp), `recommendations_repository_test` (4 — parse + job
filtering/backfill + empty throw + AI-error + language/no-Markdown), `recommendations_store_test`
(2), `recommendations_controller_test` (5 — cold gen+cache, cached hydration, refresh
up-to-date, failure map, clock), `recommendations_context_test` (1 — flatten + applied
exclusion + stable signature), `recommendations_screen_test` (6 — ready/loading/error EN+AR);
Recommendations added to the locale sweep. `flutter analyze` clean.

**VERIFIED live on emulator with REAL Gemini — both English and Arabic:**
- **English:** Home → For You → loading ("Personalizing…") → real result: header + summary +
  "Updated …" + **Recommended jobs** (real seed jobs, **confidence % badges** 15/10/5%, reasons),
  **Skills to learn** (priority High/Medium + reasons), **Certifications**, **Courses** (CS50x/
  Harvard, Git/Udemy + skill chips), **Career roadmap** (This week/Next month timeline + focus
  chips), **Next best actions** (**estimated-time chips** 2 hours/30 min/1 week/15 min + CTAs;
  `learnSkill` correctly shows no CTA). Job card deep-links to `/jobs/:id`. Low-signal **nudge**
  shown when the profile hadn't hydrated; **personalized** ("Hello Senior!…Flutter") once it did.
- **Arabic (RTL):** cold generation returns **all content in Arabic** (header/summary/nudge/job
  reasons/roadmap/actions), correct RTL layout (mirrored, Arabic-numeral confidence badges), no
  overflow. **Cache path** verified (switch language → re-enter shows cached instantly). **Refresh
  guard** verified live: with stable data, Refresh shows "كل شيء محدَّث — توصياتك محدّثة بالفعل."
  and does NOT re-call the AI.

**Bug found on-device & FIXED:** the Next-best-action footer `Row` (estimated-time chip + CTA)
overflowed on narrow widths / wide test fonts (a `Spacer` can't rescue over-wide non-flex
children) → replaced with a **`Wrap` (space-between)** so the CTA drops to its own line when
tight. Also **folded the language into the refresh signature** so switching language busts the
"up to date" guard and regenerates in the new language (was: stale-language content after a
switch).

**Seed note (same as CV Builder / Interview Prep):** entering `/recommendations` before the
auth→Firestore profile stream resolves generates from an empty (generic) context (shows the
nudge); the **normal Home path** personalizes once the profile is cached. A **Refresh** re-runs
once data has loaded.

---

## 7.13 Phase 5 · Milestone 1 — Employer Dashboard: Company Foundation ✅ COMPLETE (`baf5801`)

**Scope (approved):** introduce the employer side — role integration with auth, Company Profile,
Company Settings, completion, logo (Storage-ready), all company info fields, Employer Home
dashboard, repository/store architecture, Firestore-ready models, EN/AR — provider-agnostic,
repository-based, reusing existing auth/localization, **zero feature-to-feature deps**, same
feature-first architecture. Approved additions: (1) **Quick Stats** on Employer Home (Active jobs/
Applications/Interviews/Hires, zero for now); (2) **`verificationStatus`** (Pending/Verified/
Rejected, no UI); (3) **`companySlug`** (public URLs later, no migration); (4) optional **social
links** (LinkedIn/X/Facebook); (5) model shaped for a future **AI Company Strength** score with no
refactor.

**Three approved architecture decisions:** (1) **role-based landing** (not a second app); (2)
**reuse the shared Settings screen** (role-aware account card) for "Company Settings"; (3)
**`companies/{companyId}` top-level collection, `companyId == ownerUid`** for M1.

**Role integration (auth):** `splash._bootstrap`, `auth_navigation.goAfterAuth`, and
`user_type_selection._confirm` branch on `UserType` → employers `goNamed(employerHome)` + job
seekers `goNamed(home)` (navigation-only, no employer-feature import). `goAfterAuth`/user-type-select
call `companyRepository.ensureCompany(uid, email, name)` for employers (idempotent, seeds the doc
from the auth identity). **Logout now clears the persisted `userType`** (`SettingsScreen._confirmLogout`
→ `userTypeControllerProvider.clear()`) so a different account on the device picks its own role —
required now that roles land on different dashboards.

**Shared model `lib/shared/models/company.dart`:** `Company` (Equatable, `copyWith`, defensive
`toJson`/`fromJson` tolerating snake_case / bad enums / ISO+millis+Timestamp dates) — companyId,
ownerUid, name, industry, size, website, headquarters, description, contactEmail, contactPhone,
logoUrl, **companySlug**, **verificationStatus**, **linkedinUrl/xUrl/facebookUrl**, **strength**
(`CompanyStrength` nested: score/summary/strengths/improvements/analyzedAt), createdAt/updatedAt.
`completion`/`completionPercent`/`missingFields` over **8 tracked fields** (name, logo, industry,
size, website, headquarters, description, contactEmail). `CompanyField` enum + `Company.slugify(name)`.
Enums in `features/employer/domain/`: `Industry` (14), `CompanySize` (6, tolerant `fromName`),
`CompanyVerificationStatus`. Ephemeral `CompanyStats` (dashboard) in the same domain.

**Core service `lib/core/services/company/`:** `CompanyRepository` interface (`watchCompany` Stream
+ `fetchCompany`/`saveCompany`/`ensureCompany`/`setLogoUrl`) + `FirestoreCompanyRepository` (degrades
gracefully; `companies/{companyId}`) + `InMemoryCompanyRepository` (tests) + `companyRepositoryProvider`
(swap point) + `companyProvider` (StreamProvider, tracks the auth uid). `CompanyLogoStorage` seam
(`company_logo_storage.dart`) over `CloudStorageService.companyLogoPath(id)` = `companies/{id}/logo.jpg`
(+ `companyLogoStorageProvider`). Mirrors the `user_profile` stack exactly.

**Feature `lib/features/employer/`:** `application/` — `company_providers.dart` (`currentCompanyProvider`
merges stored + auth-email fallback, `companyCompletionProvider`, `companyStatsProvider` = zeros for
M1, rebindable later), `company_edit_controller.dart` (save → `saveCompany`, keys by uid, auto-derives
`companySlug` from name when empty; `CompanyFailure` enum), `company_logo_controller.dart` (pick via
`file_selector` → `uploadCompanyLogo` seam → `setLogoUrl`; `uploadBytes` `@visibleForTesting`).
`presentation/` — `employer_home_screen.dart`, `company_profile_screen.dart`, `edit_company_screen.dart`,
`company_l10n.dart` (Industry/CompanySize/CompanyField label maps + failure message).
**Promoted** `completion_indicator.dart` → `lib/shared/widgets/` (parameterized title/nudge/complete;
profile + company reuse it; `profile_screen` + its test updated).

**Wiring:** routes `employerHome` (`/employer`) + `companyProfile` (`/employer/company`) + `editCompany`
(`/employer/company/edit`, nested); `SettingsScreen` account card → role-aware (`/employer/company` for
employers); ~62 `company*`/`employer*`/`industry*` EN+AR l10n keys.

**Firestore/Storage:** new `companies/{companyId}` collection. **`firestore.rules` deployed** — read by
any signed-in user (future job listings), write only by the owner (`request.auth.uid == companyId`).
**`storage.rules` updated** for `companies/{companyId}/**` (same owner rule). ⚠️ **Firebase Storage is
still unprovisioned** (carried from P3·M3) — logo upload degrades to a localized error until the Console
bucket + `firebase deploy --only storage`; everything else works on live Firestore + Auth.

**Tests: 270 total pass** (was 238; +32): `company_model_test` (7 — completion/missing/round-trip incl.
new fields/snake_case+range/verification default+dates/slugify/strength), `company_repository_test` (3),
`company_providers_test` (2 — fallback+completion), `company_edit_controller_test` (3 — save+slug/no-clobber/
not-signed-in), `company_logo_controller_test` (3), `employer_screens_test` (7 — 3 screens EN+AR + name/
industry); EmployerHome/CompanyProfile/EditCompany added to the locale sweep. `flutter analyze` clean.

**VERIFIED live on emulator — both English and Arabic:**
- **Role routing:** registered a **new employer account** (`employer01@cb.app`) → User Type → **Employer**
  → landed on **Employer Home** (not the job-seeker Home); role persists across an app restart. A job-seeker
  account still lands on `/home` (regression check).
- **Employer Home:** quick-stats grid (0/0/0/0), completion ring, Company Profile CTA, "Soon" recruiting
  tools — EN + AR (RTL, mirrored, Arabic stat labels).
- **Company Profile + Edit:** filled name (Acme-Robotics) + Industry (Technology) + size + website + HQ →
  **Save → Firestore persist** (`companies/{uid}`), completion **13%→38%**, re-rendered after an app restart;
  Arabic Edit shows all 14 industry + 6 size chips localized (التقنية, 11–50 موظفًا, …). Role-aware Settings
  account card → Company Profile (verified in Arabic).

**On-device fixes during verification:** (1) `_ToolCard` grid overflowed 2.7px → lowered `childAspectRatio`
1.42→1.3; (2) **logout didn't clear `userType`** → a new account inherited the device's old role and landed on
the wrong dashboard → added `userTypeController.clear()` on logout. **Firestore-rules gotcha:** company writes
were denied until `firestore.rules` was deployed; a snapshot listener that hits a permission error **terminates**
(same `.handleError` swallow as the profile repo), so after deploying rules the running app needed a restart to
re-subscribe — a fresh launch reads the persisted doc fine.

**Firebase state note (§5):** the `companies/{companyId}` Firestore rule is **deployed**. Storage rules for
`companies/**` are authored but not deployed (bucket unprovisioned).

---

## 7.14 Phase 5 · Milestone 2 — Employer Job Management ✅ COMPLETE

> **A machine freeze had interrupted this milestone mid-way** (foundation built, presentation/wiring/tests/verify
> remaining). A fresh session confirmed the working tree matched the documented progress, then **completed the
> remaining items and live-verified EN + AR**. `flutter analyze` clean; **329 tests pass** (was 270; +59);
> `jobs/{jobId}` Firestore rules deployed.

**Design recap (see the approved plan):** a new `JobPosting` **management superset** (shared model) that
`toJob()`-projects to the existing seeker `Job` (reuse by projection, not duplication); a **separate** core
`EmployerJobsRepository` (write CRUD, Firestore `jobs/{jobId}`) leaving the read-only seeker `JobsRepository`
untouched; a shared `JobDetailView` widget so the employer **preview** renders exactly as a seeker sees it. Zero
feature-to-feature deps. Approved additions baked into the model/logic: soft-delete (`deletedAt`), availability
dates (`opensAt`/`expiresAt`), multiple openings, draft **auto-save**, unsaved-changes guard, publish confirmation
**after preview**, archive reason, **metrics foundation** (`JobMetrics` incl. future `firstPublishedAt`/
`lastViewedAt`/`lastApplicationAt`), audit (`createdBy`/`updatedBy`), status **history** (`JobStatusChange`), and
**optimistic UI** with rollback.

### ✅ COMPLETE (in the working tree, analyzer-clean, untracked/modified — NOT committed)

**Domain enums** `lib/features/employer/domain/`:
- `job_status.dart` — `JobStatus {draft,published,archived,closed}` + `allowedNext`/`canTransitionTo`.
- `employment_type.dart` — `EmploymentType` (5) with `canonical` strings matching the seed data.
- `job_experience.dart` — `JobExperience` (5) with `canonical` → seeker `Job.seniority`.
- `salary_period.dart` — `SalaryPeriod {yearly,monthly,hourly}`.
- `job_validation.dart` — pure `JobValidator.forDraft`/`forPublish` + `JobField`/`JobError`/`JobValidationResult`.

**Shared model** `lib/shared/models/job_posting.dart` — `JobPosting` (+ `SalaryRange`, `JobMetrics`,
`JobStatusChange`), defensive JSON, `toJob()` projection, `withStatus`/`softDeleted`/`duplicated`/`create`/
`copyWith`, all lifecycle/availability/openings/soft-delete/metrics/audit/history fields.

**Core repository** `lib/core/services/jobs/`:
- `employer_jobs_repository.dart` — interface (`watchJobs`/`fetchJob`/`createJob`/`updateJob`) +
  `employerJobsRepositoryProvider` + `employerJobsProvider` (StreamProvider, tracks auth uid).
- `firestore_employer_jobs_repository.dart` — `jobs/{jobId}`, equality-only query (no composite index), filters
  soft-deleted + sorts in Dart, **writes rethrow on failure** (so the optimistic controller can roll back).
- `in_memory_employer_jobs_repository.dart` — per-company broadcast stream (tests/offline).

**Application layer** `lib/features/employer/application/`:
- `employer_jobs_providers.dart` — `EmployerJobsFilter`(+controller), `JobSort`, **`visibleEmployerJobsProvider`**
  (merges the stream with the controller's optimistic overlay), `filteredEmployerJobsProvider`,
  `employerJobByIdProvider`, `employerJobsStatsProvider`.
- `employer_jobs_controller.dart` — **optimistic** lifecycle actions (publish/close/reopen/archive-with-reason/
  duplicate/softDelete) with an overlay (`overrides`/`removedIds`/`added`/`pending`) that **rolls back on failure**;
  transitions computed by the pure model.
- `job_editor_controller.dart` — `.autoDispose.family<…, String?>` (null=create, id=edit); field mutations,
  two-tier validation, **debounced draft auto-save** (2.5 s, guarded by draft-validity), dirty tracking
  (`hasUnsavedChanges`), `saveDraft()`. Injectable clock + `@visibleForTesting` seed ctor.

**Modified (M1 baseline, additive/justified):**
- `lib/features/employer/application/company_providers.dart` — `companyStatsProvider.activeJobs` now derives from
  `employerJobsProvider` (published count). *(The M1 seam explicitly anticipated this.)*
- `lib/shared/widgets/job_detail_view.dart` — **new** shared widget (public job body from a `Job`, optional
  `afterMeta` slot).
- `lib/features/jobs/presentation/job_detail_screen.dart` — **refactored** `_Content` to render via `JobDetailView`
  (match panel injected via `afterMeta`); removed the now-shared `_MetaChip`/`_SectionTitle`. **Behavior-preserving**
  — must stay green in the existing `job_detail_screen_test`/`jobs_screen_test` (regression guard).

**Localization** — all ~90 `job*`/`employer*` M2 keys in `app_en.arb` **and** `app_ar.arb`; `flutter gen-l10n` run.

### ✅ COMPLETED IN THE RESUMING SESSION (presentation + wiring + rules + tests + verify)

**Presentation** `lib/features/employer/presentation/`:
- `employer_jobs_l10n.dart` — enum→label extensions (`JobStatus`/`EmploymentType`/`JobExperience`/`SalaryPeriod`/
  `JobSort`) + `jobErrorMessage(field, error)` (title vs description share `tooShort`) + `jobsActionFailureMessage` +
  `jobEditorFailureMessage`.
- `job_actions.dart` — `JobAction` enum + `availableJobActions(job)` (status-aware; Publish vs Reopen by status;
  Delete last). `job_action_handler.dart` — `runJobAction()` shared by the list + detail (navigation, confirm/archive
  dialogs, optimistic calls, success snackbars; failures via each screen's `ref.listen`).
- `widgets/job_status_chip.dart`, `widgets/employer_job_tile.dart` (status chip + meta + lifecycle overflow menu +
  in-flight progress bar).
- `employer_jobs_screen.dart` (My Jobs: search + status filter chips + sort menu + list/empty/no-results + FAB;
  failure snackbars). `job_editor_screen.dart` (form, inline validation, openings/salary/availability, auto-save
  indicator, `PopScope` unsaved-changes sheet, Publish → validate → saveDraft → Preview). `job_preview_screen.dart`
  (renders `JobDetailView(JobPosting.toJob())`, banner, Publish-confirm CTA when `isPublishable`).
  `employer_job_detail_screen.dart` (status header, metrics row, info/availability/audit lines, archive reason,
  Applicants-soon, status-aware action buttons; pops when the posting is soft-deleted).

**Wiring:** 5 routes nested under `/employer` (`employerJobs`/`createJob`/`jobPreview`/`employerJobDetail`/`editJob`,
static before `:id`; `jobPreview` takes `extra: JobPosting`, not `Job` — the preview needs the posting to publish).
`employer_home_screen.dart` — **"Manage jobs"** CTA + the **"Post a Job"** tool tile now live (↗); Applicants stays "Soon".

**`firestore.rules`** — `jobs/{jobId}` block added + **deployed**. Read: `status=='published' || ownerUid==uid`;
create: `request.resource.data.ownerUid==uid`; update/delete: `resource.data.ownerUid==uid`.

**Tests: 329 pass** (was 270; +59): `job_validation_test` (8), `job_posting_model_test` (12), `employer_jobs_repository_test` (4),
`employer_jobs_controller_test` (6, incl. rollback via a throwing fake), `job_editor_controller_test` (6, auto-save reuses
id / dirty), `employer_jobs_providers_test` (6), `job_detail_view_test` (3), `employer_jobs_screens_test` (10, EN+AR renders
of all 4 screens **using the real `AppTheme`** — see bug #2); EmployerJobs + JobEditor added to the locale sweep. Seeker
`job_detail_screen_test`/`jobs_screen_test` stayed green through the `JobDetailView` extraction.

### 🐞 Three device-only bugs found & fixed during live verification (not caught by the original tests)
1. **Firestore `permission-denied` on the list query.** The repo queried `where('companyId', …)` but the read rule
   authorizes by `ownerUid`; Firestore can't prove the query only returns readable docs → denies it. **Fix:**
   `firestore_employer_jobs_repository.watchJobs` now queries `where('ownerUid', …)` (== companyId here) to match the rule.
2. **Infinite-width button crash.** `AppTheme` styles buttons `minimumSize: Size.fromHeight(56)` (= **infinite width** —
   full-width buttons). A bare themed button in a `Row`/`Wrap` (unbounded main-axis) asserts. The editor's `_EditorBar`
   (Row) and the detail `_Actions` (Wrap) crashed on device but **not in tests, because the tests used a bare
   `MaterialApp` without `AppTheme`.** **Fix:** `_EditorBar` → both buttons `Expanded`; `_Actions` → `minimumSize: Size(0,40)`
   per button; **and `employer_jobs_screens_test` now wraps screens in the real `AppTheme.light(locale)`** so this class of
   bug is caught in CI. (The seeker `_ActionBar` has the same latent shape but was never verified live — a possible follow-up.)
3. **`TextEditingController` used after dispose.** The archive-reason dialog created a controller and `dispose()`d it
   synchronously after `showDialog` returned, while the dialog was still rebuilding during its exit animation → red screen.
   **Fix:** moved the controller into a `_ArchiveReasonDialog` `StatefulWidget` so it's disposed only after the route unmounts.

### VERIFIED live on emulator (`-gpu host`) — both English and Arabic, real Firestore
Deep-linked via `flutter run --route=/employer/jobs` (sidesteps the flaky Home app-bar — §10). Signed in as
**`employer01@cb.app`** (company "Acme-Robotics").
- **Arabic (RTL):** My Jobs empty state → **create** (title/description/skill chip/experience+employment chips/location) →
  **debounced auto-save** ("جارٍ الحفظ…" → "تم الحفظ 10:22 م", create→edit transition) → **publish validation** (inline
  "مطلوب" on location + "يرجى تصحيح الحقول المميزة" snackbar) → **Preview** (banner + shared `JobDetailView`) →
  **publish-confirm** dialog → **published** (card shows منشورة + "تم نشر الوظيفة") → **archive-with-reason** dialog →
  archived (تمت أرشفة) → **reopen** → published (تمت إعادة فتح). Status-aware overflow menu confirmed (published: Archive/
  Close; archived: Reopen).
- **English (LTR):** Settings language switch → Employer Home (**Manage jobs** CTA + **Post a Job** live ↗ + Applicants
  "Soon"; **Active jobs** derives from published count) → My Jobs (filter chips/search/FAB) → **detail** (Views/Applications
  metrics, Published/Updated dates, **Archive reason "Role filled"**, Applicants-soon, content-sized action buttons).

### Notes for the next session
- Repository writes **rethrow** (unlike the M1 company repo) so `EmployerJobsController` rolls back optimistic overlay
  entries on failure; `JobEditorController._persist` catches and surfaces `saveFailed`.
- The `job_editor_controller` is an **`autoDispose.family`** keyed by nullable jobId; its auto-save `Timer` is cancelled in `dispose`.
- `JobPosting.toJob()` **excludes** management/metrics/audit/openings — the preview shows only the public seeker fields.
- **Test-host lesson:** widget tests that only use a bare `MaterialApp` miss theme-driven layout bugs; prefer wrapping in the
  real `AppTheme` for screens with full-width themed buttons (see bug #2).

---

## 7.15 Phase 5 · Milestone 3 — Employer Applicants Management ✅ COMPLETE

> Employers review + manage applicants for every published job, over the **same shared applications foundation**
> the seeker Applications Center uses. `flutter analyze` clean; **375 tests pass** (+46); rules deployed.
> **Four approved additions baked in:** `ApplicantSnapshot.snapshotVersion` (forward-compat), an **employer activity
> log** foundation (recorded fire-and-forget, no UI), an optional `Application.source` (defaults CareerBridge), and
> the M2 **optimistic-with-rollback** strategy for *both* status actions and note ops.

**The privacy-wall insight (drove the whole design):** Firestore rules keep every user's `users/{uid}` profile,
resume analysis, and interview history **private to that user** (and resume/interview data is only session-cached).
An employer therefore can't read an applicant's private docs — so **everything the employer needs is denormalized onto
the application at apply time** (seeker-side, where it's the current user's own data). Mirrors how `Application`
already snapshots the job. This keeps rules tight, avoids employer-side AI cost, and preserves zero feature deps.

**Shared foundation (extended/new in `lib/shared/models/`):**
- `application.dart` — **extended additively**: `applicantUid`/`ownerUid`/`companyId`/`companyName` (dual-keyed:
  seeker reads by applicantUid, employer by ownerUid), `source` (`ApplicationSource {careerBridge,referral,
  externalImport,companyWebsite}`), nested `applicant` (`ApplicantSnapshot?`); `ApplicationEvent` gained `by`/`note`
  audit; `withStatus(...,by,note)` still **appends** (never replaces). `_parseDate` now duck-types Firestore Timestamp.
- `applicant_snapshot.dart` — **new** `ApplicantSnapshot` (profile+resume-analysis+AI-match+interview-readiness) with
  `snapshotVersion` (defaults `currentVersion=1`); plain values only (no feature enums into `shared/`).
- `application_note.dart` (`ApplicationNote`), `employer_activity.dart` (`EmployerActivity` + `EmployerActivityType`).

**Core repositories (`lib/core/services/`) — each interface + Firestore + in-memory + providers, mirroring M2:**
- `applications/employer_applicants_repository.dart` — `watchApplicants(ownerUid)`/`fetchApplicant`/`updateApplication`;
  Firestore queries **`where('ownerUid', …)`** (matches the rule — pre-empts the M2 permission-denied bug); writes rethrow.
  `employerApplicantsProvider` tracks the auth uid. **Separate** from the untouched seeker `ApplicationsRepository`.
- `notes/employer_notes_repository.dart` — owner-private `applicationNotes` (query by ownerUid+applicationId, two
  equality filters, no composite index). `employerActivityRepository` (`activity/`) logs actions (fire-and-forget).

**Application layer (`lib/features/employer/application/`):**
- `employer_applicants_providers.dart` — `ApplicantsFilter`(text/statuses/jobId/sort)+controller, `visibleApplicants`
  (stream + optimistic overrides), `filteredApplicants`, **`groupedApplicantsProvider`** (by job, most-recent first),
  `applicantsForJobProvider`, `applicantByIdProvider`, `employerApplicantsStatsProvider`.
- `employer_applicants_controller.dart` (optimistic status: review/interview/accept/reject/reopen — gated by the pure
  `ApplicantStatusFlow`, appends history, logs activity, rolls back) + `employer_notes_controller.dart` (optimistic
  add/edit/delete with `visibleNotesProvider` overlay + activity). `company_providers.dart` — stats now derive
  Applications/Interviews/Hires from the applicants stream.

**Presentation (`lib/features/employer/presentation/`):** `employer_applicants_screen.dart` (grouped inbox or per-job
via `jobId`), `employer_applicant_detail_screen.dart` (all sections + status action bar + notes), `applicant_actions`
+ `applicant_action_handler` (`runApplicantAction`, confirm/reject-reason dialogs — controller owned by a
`StatefulWidget`, the M2 dialog-dispose lesson), `employer_applicants_l10n`, + 8 widgets. **Promoted**
`StatusChip`/`StatusTimeline`/status-style → `shared/widgets` (the only cross-surface link — like `JobDetailView`).

**Wiring:** 3 routes under `/employer` (`employerApplicants` `/employer/applicants`, `:appId` child; `employerJobApplicants`
`/employer/jobs/:id/applicants`). Home **"Applicants" tile live**; Job Detail **"Applicants (N) →"** (was "coming soon").
**Rules deployed:** `applications` (create=applicant, read=either party, update=owner, delete=applicant), owner-private
`applicationNotes` + `employerActivity`. ~45 `employerApplicants*`/`applicant*`/`note*` EN+AR keys (ICU plurals).

**Tests +46 → 375:** model extension, `applicant_snapshot`, `application_note`(+activity), `applicant_status_flow`,
applicants + notes repos, applicants + notes controllers (optimistic + **rollback via throwing fakes** + activity
logged), providers (group/filter/stats), `employer_applicants_screens` (EN+AR, **real `AppTheme`**), + inbox in the
locale sweep. Seeker applications tests stayed green through the widget promotion.

**VERIFIED live (EN + AR, real Firestore, `employer01@cb.app`):** seeded 3 applications (Sara/Omar/Lina, distinct
statuses + full snapshots) into Firestore `applications` via a seeder that signs in as the seeker (the create rule
needs `applicantUid==auth.uid`) — see `scratchpad/seed_applicants.py`. Then: grouped-by-job inbox (stats
Total/New/Interview/Accepted, search, status chips, match badges) → detail (AI match %, matching/missing skills,
ATS score + summary + strengths, resume-file graceful "not available", skills, links, interview readiness, timeline)
→ **added a private note** (persisted, owner-only) → **Move to Interview** (snackbar + timeline **appended** the
Interview event, optimistic + Firestore) → dashboard stats went **Applications 3 / Interviews 2**. Repeated in AR
(RTL): all strings translated, ICU plurals (متقدّمان / متقدّم واحد), the earlier status change persisted. **No device
bugs this milestone — the three M2 lessons were pre-applied** (real `AppTheme` in tests, `minimumSize` action buttons,
`StatefulWidget`-owned dialog controllers, query-by-`ownerUid`).

**Notes for the next session:**
- **Seeker apply doesn't write to Firestore yet** — the seeker Applications Center is still in-memory (P3·M2, untouched),
  and seekers browse **seed** jobs (no ownerUid). So live seeker→employer needs two follow-ups: rebind the seeker
  `ApplicationsRepository` to Firestore (durable persistence) **and** surface real published `jobs/{jobId}` to the seeker
  Jobs Platform + assemble the `ApplicantSnapshot` at apply time. Until then, applicants are seeded (as above). The
  **architecture is ready** — the same shared model/collection means the two sides live-sync the moment both are Firestore.
- **Resume file view/download** is a graceful-degrade stub (`resumeUrl` null until Firebase Storage is provisioned +
  the apply flow uploads the PDF); a thin `url_launcher` follow-up opens it (kept out now to avoid a KGP/Gradle risk).
- **Employer activity log** is recorded but has no UI — a future audit screen reads `employerActivityProvider`.
- **Full interview history** (read-only) for an applicant needs a Firestore interview store + a sharing rule; only the
  lightweight readiness snapshot is denormalized today.

---

## 7.16 Phase 5 · Milestone 4 — Employer Analytics ✅ COMPLETE

> A read-only hiring analytics/insights surface over the data the employer side already emits — **no new data
> sources, no new Firestore collections or rules**. `flutter analyze` clean; **412 tests pass** (+37).
> **Scope: Analytics + AI Recruiter Insights** (the approved option); **AI Company Strength deferred**.

**Design principle:** the deterministic dashboard must render **instantly** from the existing streams, so all math
lives in a **pure `AnalyticsCalculator`** (Flutter-free, injectable `now`, exhaustively unit-tested). The AI card is
**on-demand** (not auto-called) because it sits inside an already-instant dashboard and each call costs money — but it
**reuses the Recommendations AI architecture verbatim** (context → signature → repository → store seam → refresh guard).

**Domain (`lib/features/employer/domain/analytics/`):**
- `employer_analytics.dart` — value objects: `OverviewKpis` (jobs/applicants/interviews/hires/hireRate/avgMatch),
  `StatusFunnel` (reached-stage counts, monotonic, + stage-to-stage conversion), `JobPerformance` (`status` is
  **nullable** — null when a job is only referenced by applications, so the UI shows no misleading chip — see the
  device fix below), `TimeToHire` (avg/median/fastest days-to-hire + avg days-in-pipeline), `ApplicantQuality`
  (match bands + avg ATS + skill demand), `ActivityTrend` (weekly buckets + last-7-day counts), and the top-level
  `EmployerAnalytics` (+ `empty`, `hasApplicants`/`hasJobs`). Pure read-model — no JSON (nothing persisted).
- `analytics_calculator.dart` — `AnalyticsCalculator.compute({jobs, applicants, activity, now})`. Funnel "reached
  rank" scans current status + history (a rejection doesn't undo prior progress; accepted implies interview/reviewed
  → monotonic). Time-to-hire reads the accepted history event; skill demand counts each skill once per applicant
  (case-insensitive). Excludes soft-deleted jobs.
- **AI layer** (mirrors `recommendations/domain`): `recruiter_insights.dart` (`RecruiterInsights` + `InsightItem`/
  `InsightAction` + **local** `InsightPriority` enum — not the recommendations `RecPriority`, to keep zero coupling;
  defensive `fromJson`, `stamp()`), `recruiter_insights_context.dart` (primitives + `signature`), `_repository.dart`
  (interface) + `_exception.dart` (`emptyInsights`).

**Data:** `data/recruiter_insights_repository_impl.dart` (+ `recruiterInsightsRepositoryProvider`) — one localized
prompt from the analytics facts → `AiService.generateJson` (no-Markdown system instruction) → defensive parse; throws
`emptyInsights` only when nothing usable comes back. **Identical shape to `RecommendationsRepositoryImpl`.**

**Application:** `employer_analytics_providers.dart` — `employerAnalyticsProvider` (a plain `Provider` recomputing
`AnalyticsCalculator.compute(...)` reactively from `employerJobsProvider` + `employerApplicantsProvider` +
`employerActivityProvider`) + `analyticsClockProvider` (test seam). `recruiter_insights_controller.dart` —
`RecruiterInsightsController` (phases idle/loading/ready/error; **starts idle, never auto-calls**; `generate()` /
`refresh()` with the signature-based refresh guard; `.seeded` ctor; failure map reusing `AiException`) +
`contextFromAnalytics(...)` (pulled out for direct unit testing).

**Store seam (core, Firestore-ready):** `lib/core/services/recruiter_insights_store/` — `RecruiterInsightsStore`
interface + `InMemoryRecruiterInsightsStore` (broadcast) + `recruiterInsightsStoreProvider` +
`latestRecruiterInsightsProvider`. **In-memory now → rebind to a Firestore `companies/{companyId}/insights/latest`
doc later (needs an owner-scoped subcollection rule then; none added this milestone).**

**Presentation:** `employer_analytics_screen.dart` (loading/empty/dashboard; `_InsightsCard` ConsumerWidget with
idle-CTA / loading / error / ready states + refresh; up-to-date & failed-refresh snackbars via `ref.listen`),
`analytics_l10n.dart` (band/priority/failure label maps), `widgets/analytics_widgets.dart`
(`AnalyticsSection`/`AnalyticsCard`/`KpiTile`/`HorizontalBars`/`MiniBarChart`/`PriorityChip` — **all plain-Flutter,
RTL-safe** via `AlignmentDirectional`/`FractionallySizedBox`; reuses the promoted `JobStatusChip`). Top-jobs rows
deep-link to `/employer/jobs/:id/applicants`.

**Wiring:** route `employerAnalytics` (`/employer/analytics`, nested under `/employer`); an **"Analytics & insights"
CTA** on Employer Home (below "Manage jobs"). ~55 `analytics*`/`insights*` EN+AR keys (ICU plurals for
applicants/days/rejections/trend). No Firestore rules change.

**Tests (+37 → 412):** `analytics_calculator_test` (12 — empty, active-jobs filter, avg-match, funnel monotonicity +
rejection-keeps-progress, time-to-hire avg/median/fastest + avg-wait, quality bands + skill demand, job-perf sort +
zero-applicant + **null-status-for-application-only-job**, activity trend buckets), `employer_analytics_providers_test`
(4 — recompute from streams, signed-out empty, `contextFromAnalytics` mapping + stable signature),
`recruiter_insights_repository_test` (4 — parse, prompt embeds numbers + language, emptyInsights, error propagation),
`recruiter_insights_controller_test` (7 — idle start, generate+cache, cache hydrate, refresh guard, error map, empty
map, clock), `recruiter_insights_store_test` (3), `employer_analytics_screen_test` (5 — EN+AR dashboard + EN+AR
ready-insights, real `AppTheme`; idle CTA); Analytics added to the locale sweep.

### 🐞 One device-only issue found & fixed during live verification (not caught by the original tests)
**Misleading "Published" chip on application-only jobs.** `employer01` has **0** `JobPosting` docs, so Overview showed
**Active jobs = 0** — yet "Top jobs" listed two jobs (Senior Flutter Engineer, Backend Developer) chipped **"Published"**.
Those jobs exist only via the seeded applications' `jobId`; the calculator was defaulting their status to
`JobStatus.published`. **Fix:** `JobPerformance.status` is now **nullable** — set only from a known `JobPosting`, null
otherwise — and the UI omits the chip when null (added a calculator test for it). This also fixed the apparent
inconsistency with the Active-jobs KPI.

### VERIFIED live on emulator (`-gpu host`, Skia) — both English and Arabic, real Firestore + real Gemini
Deep-linked via `flutter run --route=/employer/analytics`, signed in as **`employer01@cb.app`** (company "Acme-Robotics"),
against the **M3 seeded applicants** (3 apps: statuses give applied 3 / reviewed 3 / interview 2 / hired 0).
- **Arabic (RTL):** full dashboard — Overview (المقابلات 2 / المتقدمون 3 / متوسط التطابق 76), funnel bars growing from
  the **right** (تقدّموا 3 100% → تمت مراجعتهم 3 100% → مقابلة 2 67% → تم تعيينهم 0), top jobs, time-to-hire (3 أيام
  متوسط الانتظار), match distribution (قوي 1 / جيد 2), skill demand chips (Flutter · 2), trend (newest week rightmost).
  **AI insights (real Gemini):** tapped "أنشئ الرؤى" → grounded Arabic insights citing the actual numbers (67% reach
  interview, 0% hire, 3 new in 7 days, avg match 76/ATS 77, Flutter/Dart skills), with **strengths / bottlenecks /
  suggested-actions + medium-priority chips + a localized "Updated 7 Jul 2026" timestamp**.
- **English (LTR):** switched language in Settings, re-entered analytics — all sections mirror correctly LTR; the
  **status-chip fix confirmed** (top jobs show no chip, consistent with Active jobs = 0).

### Notes for the next session
- **The AI card is on-demand** (idle → "Generate insights"), unlike the always-on "For You" flow — a deliberate
  cost/latency choice, not a different architecture. It still caches per-session and honors the refresh guard.
- **Job view analytics are N/A** this milestone — `JobMetrics.views` isn't instrumented and seekers browse seed jobs;
  the screen footnote says so. Wire view counts once the seeker→employer loop is Firestore-backed.
- **Firestore-backing the insights store** (`companies/{id}/insights/latest`) is the only follow-up seam; in-memory now.
- **AI Company Strength** (`Company.strength` is already shaped for it) remains a clean future milestone.

---

## 7.17 Phase 6 · Milestone 1 — Production Ready (Firebase & Backend) ✅ COMPLETE

> Production Firebase infrastructure behind **five vendor-neutral core services**, each following the app's one
> dominant pattern: **interface (plain Dart only) → single Firebase impl (the only file importing that plugin) →
> Noop/in-memory impl → one Riverpod swap-point provider**. Providers default to the Firebase impl **when
> `FirebaseService.isReady`, else a Noop**, so tests and unconfigured runs never touch a plugin. **All telemetry is
> best-effort, non-blocking, and non-throwing — a telemetry failure can never affect the app** (the mandated M1
> principle). `flutter analyze` clean; **438 tests pass** (+26); **no new Firestore rules**.

**Scope additions (approved) baked in:** (1) a `PushPreferences` category foundation + repository seam; (2) an
analytics **consent** lever; (3) Crashlytics **user context** (uid + account type); (4) optional `StorageMetadata`
(contentType/cacheControl/customMetadata); (5) the strict non-blocking telemetry principle.

**1 · Firebase Storage** (`lib/core/services/cloud_storage/`): `StorageService` interface (`upload({path, bytes,
metadata, onProgress}) / delete / downloadUrl`) + `FirebaseStorageService` (only file importing `firebase_storage`;
progress via `UploadTask.snapshotEvents`) + `InMemoryStorageService` + `storage_paths.dart` + `storageServiceProvider`.
Plain `StorageUploadProgress` / `StorageMetadata` value types. The former `CloudStorageService` is **removed**; the two
media seams `ProfileImageStorage` / `CompanyLogoStorage` are **rebased on `StorageService`** and gain `delete` +
progress. `ProfilePhotoController` / `CompanyLogoController` gained a `progress` field + `removePhoto` / `removeLogo`;
the profile-photo + company-logo editors show a determinate ring + a **Remove** action (confirm dialog). Uploads are
wrapped in a performance trace + log an analytics event.

**2 · Push Notifications** (`lib/core/services/messaging/`): `NotificationService` interface (permission / token /
`onTokenRefresh` / `onMessage` / `onMessageOpened`, plain `PushMessage` + `NotificationPermission`) +
`FirebaseNotificationService` (**absorbs the removed `MessagingService`**, keeps the top-level `@pragma('vm:entry-point')`
background handler) + `NoopNotificationService` + `notificationServiceProvider`. `PushTokenRegistrar` seam (no-op now →
Firestore `users/{uid}/fcmTokens` later; no rule change — own-doc). **`PushPreferences`** (categories
jobRecommendations / applicationUpdates / interviewReminders / employerNotifications, master-gated, defensive JSON) +
`PushPreferencesRepository` (in-memory → Firestore later). **No UI** (kept separate from the existing settings
`NotificationPreferences` to avoid refactoring that feature; a future milestone can map settings → these categories).

**3 · Analytics** (`lib/core/services/analytics/`): `AnalyticsService` (`logScreenView`/`logEvent`/`setUserId`/
`setUserProperty`/`setEnabled`) + `FirebaseAnalyticsService` + `NoopAnalyticsService`. **`AnalyticsRouteObserver`**
(vendor-neutral `NavigatorObserver`, wired via `GoRouter(observers:)`) logs `screen_view` from the route name.
`AnalyticsEvents`/`AnalyticsParams` constants (validated by a test); events logged at key seams — seeker `job_apply`;
employer `job_publish`/`job_archive`, `applicant_status_change`, `recruiter_insights_generate`; media
`profile_photo_upload`/`company_logo_upload`. **Consent:** persisted `AnalyticsConsentController` (default on) applied
via `setEnabled` at bootstrap + a `container.listen` — feature code never branches on consent. *Distinct from the
employer hiring-**Analytics** feature (`employerAnalyticsProvider`).*

**4 · Crashlytics** (`lib/core/services/crashlytics/`): `CrashReporter` (`recordError`/`recordFlutterError`/`log`/
`setUserIdentifier`/`setCustomKey`/`setEnabled`) + `FirebaseCrashReporter` + `NoopCrashReporter`. `main()` wires
`FlutterError.onError` + `PlatformDispatcher.instance.onError`. **User context** (uid + `account_type`) is bound from
the existing `authStateProvider` + `userTypeControllerProvider` and pushed to both Crashlytics and Analytics.

**5 · Performance** (`lib/core/services/performance/`): `PerformanceMonitor` + `PerfTrace` interfaces +
`FirebasePerformanceMonitor` + Noop; representative upload traces.

**Bootstrap** (`main.dart`): one `ProviderContainer` shared with the tree via `UncontrolledProviderScope`; resolves
crash/analytics/perf, sets error handlers, applies consent, binds user context, builds the router with the analytics
observer. `AppRouter.create({observers})` + `CareerBridgeApp(router:)`.

**Deps:** `firebase_analytics ^11.3` / `firebase_crashlytics ^4.1` / `firebase_performance ^0.10`; **build-verified**
(`flutter build apk --debug` green — only a benign KGP *warning* on `firebase_analytics`). **The Crashlytics +
Performance Gradle plugins were intentionally NOT added** — AGP is **9.0.1** (bleeding-edge) and those plugins are the
exact KGP/Gradle risk class (§10); the runtime SDKs work without them (the plugins only add release
mapping-upload + auto-instrumentation). Adding them is a documented production-hardening follow-up.

**l10n:** +8 EN/AR keys (`uploadInProgress`, `profileRemovePhoto*`, `companyRemoveLogo*`, `remove`).

**Tests (+26 → 438):** `storage_service_test`, `push_preferences_test`, `notification_service_test`,
`analytics_events_test`, `analytics_route_observer_test`, `analytics_consent_test`, `telemetry_noop_test`; extended
`profile_photo_controller_test` + `company_logo_controller_test` (progress + remove). Firebase impls are not
unit-tested (need live backends — same policy as `FirebaseAuthRepository`/`FirebaseAiService`).

### 🐞 One device-only defect found & fixed during live verification
**Screen-view names were null.** The router's `CustomTransitionPage`s never set `settings.name`, so
`AnalyticsRouteObserver` saw null names and every manual `screen_view` silently no-opped. **Fix:** `_fadePage` now sets
`name: state.name` on the page (and `_fade`/all inline page builders pass the `GoRouterState`). Confirmed live: named
`screen_view`s (`employerHome`, `employerAnalytics`) then appeared.

### VERIFIED live on emulator (`-gpu host`, Skia) — EN + AR, real on-device Firebase (`employer01@cb.app`)
- **Init:** `[FirebaseService] Initialized`; `[FCM] Permission: granted` + token via the new `FirebaseNotificationService`;
  `FA: App measurement initialized`; `FirebaseCrashlytics: Initializing 19.4.4` + session started.
- **Analytics (EN):** auto + **named** `screen_view` (`ga_screen=employerHome`/`employerAnalytics`); `setUserId` =
  employer01 uid; **user property `account_type=employer`**; **custom event `recruiter_insights_generate`** on a
  successful generate. A transient Gemini network error showed the graceful Retry UI and **correctly did not** log the
  event (non-blocking failure path).
- **Analytics (AR):** language switched in Settings; Employer Home + Analytics render **RTL**; named `screen_view`s +
  `account_type` + Crashlytics init all confirmed. No regressions.
- **Storage:** live upload **deferred** — the default bucket is still unprovisioned and it can't be created headlessly
  (`gcloud`/`gsutil` absent; Console "Get Started"/Blaze needed). Upload/delete/progress are covered by
  `storage_service_test` + the extended controller tests + graceful-degrade (upload → null → localized error).

### Notes for the next session
- **To finish Storage production-readiness:** provision the default bucket (Console → Storage → Get Started), then
  `firebase deploy --only storage` (rules already authored). Then live-verify photo/logo upload + Remove (EN + AR).
- **To harden Crashlytics/Performance:** add the `com.google.firebase.crashlytics` + `com.google.firebase.firebase-perf`
  Gradle plugins **once AGP-9-compatible versions are confirmed** (build-verify immediately — §10 KGP risk). Unlocks
  release mapping upload + automatic HTTP/screen traces.
- **Token registrar + push preferences + analytics consent** are Firestore-/UI-ready seams with no consumer yet — a
  future "notification settings" milestone wires them (map settings toggles → `PushCategory`; a consent switch →
  `AnalyticsConsentController`).
- Crashlytics/Analytics/Performance collection is currently **enabled in debug** for verification; gate by
  `kDebugMode` for production noise reduction if desired (one line in `_bootstrapTelemetry`).

---

## 7.18 Phase 6 · Milestone 2 — Security & Performance ✅ COMPLETE

> A hardening / optimization pass — **behavior-preserving** for every existing flow while making the backend
> production-safe and the client lighter. Three pillars (Security / Performance / Image optimization), all built
> to the established patterns (vendor-neutral service → single impl → noop → provider; best-effort/non-blocking;
> typed seams; zero product-feature-to-feature deps). `flutter analyze` clean; **449 tests pass** (+11);
> `firestore.rules` **deployed**; `firebase_app_check` added + **build-verified** (no new KGP warning).
> **Four approved additions baked in:** (1) a **Security Audit Log** foundation; (2) **App Check graceful
> fallback**; (3) **Security configuration documentation** (§5 manual-steps checklist); (4) a **performance
> baseline** (below).

**A · Security**
- **Firebase App Check** — a sixth vendor-neutral core service (`lib/core/services/app_check/`):
  `AppCheckService` interface (`activate`/`getToken`) + `FirebaseAppCheckService` (**only** file importing
  `firebase_app_check`; debug provider in debug, Play Integrity/Device Check in release; token auto-refresh) +
  `NoopAppCheckService` + `appCheckServiceProvider` (Firebase when `isReady`, else Noop). **Activated in `main()`
  AFTER `runApp`, un-awaited** (`unawaited(_bootstrapAppCheck(container))`) so attestation **never delays the
  first frame** (the mandate). A failed activation records a `SecurityEventType.appCheckFailure` via the audit
  log and continues — the app stays usable.
- **Security Audit Log** (`lib/core/services/security/security_audit_log.dart`) — `SecurityAuditLog` interface +
  `SecurityEventType {authFailure, permissionDenied, ruleViolation, appCheckFailure, other}` (snake_case
  `wireName`) + `TelemetrySecurityAuditLog` (routes to Analytics `security_event` event dimensioned by
  `event_type`, + a Crashlytics breadcrumb, + a non-fatal when an error object is supplied) + `NoopSecurityAuditLog`
  + `securityAuditLogProvider` (composes the existing analytics + crash services — no `isReady` gate needed).
  Added `AnalyticsEvents.securityEvent` + `AnalyticsParams.eventType`/`reason` (validated by the events test).
  **Concrete callers now:** the App Check failure path + the two owner-scoped employer Firestore streams
  (`FirestoreEmployerJobsRepository`/`…ApplicantsRepository`), which record `permissionDenied` in their
  `.handleError` when a `FirebaseException.code == 'permission-denied'` arrives (best-effort; injected via the
  providers). **No UI** — a write-only foundation.
- **Hardened `firestore.rules` (deployed).** Added reusable functions — `signedIn()`, `unchanged(field)`
  (scalar immutability; tolerant so absent/absent passes), `capped(field, max)` (absent/null/`≤max` string).
  Applied: **identity immutability** on update (`applications`: `applicantUid`/`ownerUid`/`companyId` can no
  longer be repointed by the owner-update path — the key hardening; `jobs`/`companies`/`applicationNotes`:
  `ownerUid` immutable) + **size caps** on free-text fields (users/company/job/note) + `employerActivity`
  stays append-only. **Tolerant by design** so it can't deny a write the current models' `toJson` already
  produces (would terminate the live listener — §7.13); verified live (all employer flows still read/write).
  *Deliberately NOT enforced:* `createdAt` immutability (the update path re-serializes it, so a scalar equality
  check would legitimately fail — documented) and a status *value* whitelist (kept a size cap instead, to avoid
  an enum-drift deny).
- **Hardened `storage.rules` (authored, not deployed — bucket unprovisioned).** Content-type + size caps:
  `users/{uid}/profile.jpg` image `<5 MB`; `users/{uid}/resumes/**` `application/pdf` `<10 MB`;
  `companies/{companyId}/**` image `<5 MB`. **Removed the broad `users/{uid}/**` catch-all** — Storage grants
  access if ANY matching rule allows, so an unconditioned catch-all would BYPASS the caps; the app only writes
  `profile.jpg` + `resumes/**`, so the specific matches cover it (default-deny is stricter). Delete (null
  `request.resource`) is allowed past the image checks.

**B · Performance**
- **Firestore client settings** (`FirebaseService._configureFirestore`, run right after init, best-effort):
  `Settings(persistenceEnabled: true, cacheSizeBytes: 40 MB)` — bounds the offline cache explicitly and serves
  warm re-entry (employer dashboards) from cache first.
- **Query runaway guards** — `.limit(300)` on `FirestoreEmployerJobsRepository.watchJobs` +
  `FirestoreEmployerApplicantsRepository.watchApplicants` (equality-only query + Dart sort **unchanged**; the
  cap only bounds a pathological owner — no behavior change at seed scale). **Composite indexes were
  intentionally NOT added** (queries stay equality-only to avoid the `orderBy`-excludes-missing-field regression;
  the index for a future server-side-ordered/cursor-paginated query is a documented follow-up when the
  seeker→employer loop lands).

**C · Image optimization**
- **Display side** — `lib/shared/widgets/app_network_image.dart`: `AppImage.provider(url, {context, logicalSize})`
  wraps `NetworkImage` in the built-in **`ResizeImage`** sized to the display box × devicePixelRatio
  (decode-downsizing — a multi-MP photo no longer decodes at source res). **Dependency-free** — deliberately NOT
  `cached_network_image` (pulls `flutter_cache_manager` + `sqflite` = native/KGP risk, §10). Routed through **all
  7** raw-`NetworkImage` sites (profile, edit-profile, home, company-profile, edit-company, employer-home,
  applicant-avatar). `ApplicantAvatar` is now a `StatefulWidget` that **falls back to the initial** on image error
  (was a blank circle). *(No standalone `AppNetworkImage` widget was shipped — every site is a `DecorationImage`/
  `CircleAvatar` provider, so the provider factory is the right seam; a widget can be added if a direct
  `Image.network` use ever appears.)*
- **Upload side** — `lib/core/services/cloud_storage/image_optimizer.dart`: `ImageOptimizer` interface +
  `UiImageOptimizer` (pure `dart:ui`: decode → if longest edge > `maxDimension` re-decode at target → re-encode
  PNG, and **only adopt the result when it's smaller** so it can never enlarge; any failure returns the original)
  + `NoopImageOptimizer` + `imageOptimizerProvider`. Folded into `FirebaseProfileImageStorage`/
  `FirebaseCompanyLogoStorage` before `StorageService.upload` (best-effort; content-type set to `image/png` only
  when the re-encode is adopted). Complements the Storage size caps.

**Bootstrap (`main.dart`):** App Check kicked off un-awaited after `runApp` (see above); the rest of the
telemetry bootstrap unchanged.

**Deps:** `firebase_app_check ^0.3.1` added; **build-verified** (`flutter build apk --debug` green — only the
pre-existing benign `firebase_analytics` KGP *warning*; App Check introduced **no** new warning or break).

**Tests (+11 → 449):** `security_audit_log_test` (5 — routing to analytics+crash, non-fatal on error, data
merge, Noop, wire-name shape), `app_check_service_test` (1 — Noop activates/token), `image_optimizer_test` (4 —
Noop passthrough, undecodable→original, within-cap unchanged, never-enlarge + still-decodable, via
`tester.runAsync`), `app_network_image_test` (1 — `ResizeImage` width = logical×DPR, no-upscale, wraps
`NetworkImage`). Existing suites stayed green (media-seam constructors gained an optional, defaulted param; the
image-site edits are provider-only). Firebase impls (App Check) not unit-tested — same policy as the other
Firebase impls.

### VERIFIED live on emulator (`-gpu host`, Skia) — EN + AR, real Firebase (`employer01@cb.app`)
- **App Check (device):** `DebugAppCheckProvider` registers the debug secret; `DefaultTokenRefresher.onRefresh`
  runs → **App Check is active**. Token fetch returns `403 … App Check API has not been used …` → SDK uses a
  **placeholder token** and **the app is fully usable** (enforcement off) — the **graceful fallback proven live**.
  No `app_check_failure` security event (activation itself succeeded).
- **Non-blocking startup:** moving activation after `runApp` cut the splash on-screen time (FA
  `engagement_time_msec` for `screen_view=splash`) from **~50 s (awaited) → ~6.2 s (un-awaited)**; `am start -W`
  WaitTime **~18.6 s → ~13.8 s**. (Debug build on a cold emulator — absolute numbers are baselines, not targets.)
- **No regressions (rules):** after deploying the hardened rules + restarting, **EN + AR** both render Employer
  Home (Acme-Robotics, **Applications 3 / Interviews 2** from the M3 seeded data), Settings, the language
  switch, and the **Analytics dashboard** (Overview KPIs Applicants 3 / Interviews 2 / Avg-match 76, funnel
  Applied 3 → Reviewed 3 → Interview 2 67%) — i.e. the `applications`/`jobs` reads + writes still pass the
  tightened rules. Named `screen_view`s intact (`splash`/`employerHome`/`settings`/`employerAnalytics`).
- **Images:** the logo/avatar sites render (fallback icon, since no logo/photo is set + Storage unprovisioned) —
  the `AppImage` path is exercised; decode-downsizing + never-enlarge are covered by unit tests. Live upload/
  downscale **deferred** with the Storage bucket (same caveat as P6·M1).

### 📊 Performance baseline (addition #4 — for future comparison; debug build, cold `emulator-5554`, `-gpu host`)
| Metric | Value | How measured |
| --- | --- | --- |
| Cold start (App Check **awaited**, pre-fix) | ~18.6 s WaitTime / ~50 s splash | `am start -W` + FA `engagement_time_msec(splash)` |
| Cold start (App Check **un-awaited**, shipped) | **~13.8 s WaitTime / ~6.2 s splash** | same |
| `FirebaseService` init logged | ~a few s after process start | `[FirebaseService] Initialized` |
| Analytics dashboard load | renders within the 3 s capture window (instant from streams) | screenshot after tap |
| Warm nav (home→settings→home→analytics) | sub-3 s per hop | FA `screen_view` cadence |
| Profile/logo image load | N/A this pass (no remote images set; Storage unprovisioned) | — |

> These are **debug, cold-emulator** numbers — deliberately rough. The point is a repeatable baseline: the
> App-Check-after-`runApp` change is the one clear, measurable win (~8× faster splash).

### Notes for the next session
- **App Check is monitoring-only.** Do the §5 checklist (enable API → allow-list debug token → Play Integrity)
  and only THEN enforce, or clients lock out. The debug token is per-install and must not be committed.
- **Hardened-rules gotcha still applies** (§7.13): if you tighten a rule further, diff it against the model's
  real `toJson()` first — a deny terminates the live snapshot listener until app restart.
- **Image widget vs seam:** the shipped seam is the `AppImage.provider` factory (decoration/avatar sites). If a
  direct `Image.network` surface appears (e.g. a resume thumbnail once Storage is live), add an `AppNetworkImage`
  widget with `loadingBuilder`/`errorBuilder` alongside it.
- **Composite indexes / cursor pagination** are the remaining perf follow-up, to land with the seeker→employer
  Firestore loop (server-side `orderBy` + `startAfter`).

---

## 7.19 Phase 6 · Milestone 3 — Release Preparation ✅ COMPLETE

> Production release readiness — **branding, release build/signing, assets, offline behavior, QA + release docs**.
> Deliberately **behavior-preserving** (config + assets + docs + a small dependency-free offline layer); reuses the
> established seam patterns and adds **no native plugin**. `flutter analyze` clean; **460 tests pass** (+11); the
> **release APK builds with R8/minify ON** (71.4 MB). **Five approved additions baked in:** BuildInfo foundation,
> asset verification, release-checklist-automation foundation, accessibility verification, fully-reproducible
> RELEASE.md. Two new docs live under `docs/`.

**A · Branding (already built — verified in sync).** Launcher/adaptive icons + native splash were already generated
from the 1024² `assets/icon/*` sources; **regenerating produced zero diff** → confirmed consistent. Brand colors
align end-to-end: icon bg emerald `#0E9F6E`, splash `#0B7D57` / dark `#101413` (= `AppColors`), app label
"Career Bridge". No art created; the audit codifies consistency (RELEASE.md §4).

**B · Release build & signing** (`android/app/build.gradle.kts`): release signing now reads an **optional
`android/key.properties`** (gitignored) → a real `release` `signingConfig`, with a **graceful fallback to debug
signing** when absent (dev/CI/validation builds still run — the app's "degrade when unconfigured" convention). Added
**`android/app/proguard-rules.pro`** (Flutter/Firebase/Play-Core/Kotlin keeps) and enabled **`isMinifyEnabled` +
`isShrinkResources`** on release. `android/key.properties.example` is a committed template. **Release APK + AAB build
green under R8** (top risk cleared — no fallback needed; only the pre-existing benign `firebase_analytics` KGP
*warning*). Signing preparation is **documented, not performed** (no real keystore minted/committed) — RELEASE.md has
the exact `keytool` + `key.properties` steps.

**C · Offline readiness** (dependency-free, `AiService`-pattern seams):
- **Bundled fonts** — Inter + Cairo (the exact families `AppTypography` used) are now committed at
  `assets/fonts/{Inter,Cairo}.ttf` (variable, OFL) and declared in `pubspec.yaml` `fonts:`. **`AppTypography` switched
  off `google_fonts` to native `fontFamily`** so the UI never needs the network for fonts; `main()` also sets
  `GoogleFonts.config.allowRuntimeFetching = false` as a guard. *(Genuine-blocker adaptation: only variable fonts are
  available upstream, which `google_fonts`' bundling can't match; flipping the flag alone would have regressed online
  users to the platform font — so the native-family switch was the safe path. Live-verified fonts render EN + AR.)*
- **`ConnectivityService`** core seam (`lib/core/services/connectivity/`): interface + `IoConnectivityService`
  (`dart:io` DNS-lookup poll, injectable probe, **not** `connectivity_plus`/KGP) + `NoopConnectivityService` +
  `connectivityServiceProvider` + `connectivityStatusProvider` (StreamProvider). Advisory only — never gates a feature.
- **`OfflineBanner`** shared widget wired once in `app.dart`'s `MaterialApp.builder`; slim, localized, RTL-safe,
  auto-hides. Firestore offline persistence (P6·M2) already covers data.

**D · BuildInfo foundation (addition #1)** (`lib/core/services/build_info/`): `BuildInfo{appName,version,buildNumber,
buildType}` (+ `fullVersion`/`displayLabel`) via `buildInfoProvider`. Version/build via `--dart-define`
(`APP_VERSION`/`BUILD_NUMBER`, defaults mirror pubspec) + `kReleaseMode`/`kProfileMode` — **no plugin**. Reusable by a
future About screen / bug reports; wired **now** into telemetry — every crash report is stamped with `app_version` +
`build_type`. No UI.

**Additions #2/#3/#5 (docs).** `docs/RELEASE.md` = a **fully-reproducible** runbook (prereqs, Firebase config, keystore
`keytool` + `key.properties`, branding regen, versioning + dart-defines, build commands AAB/APK/split, **all manual
console steps** — App Check enable/enforce + debug-token allow-list + Play Integrity, Storage bucket provisioning +
`firebase deploy --only storage`, Firestore rules, Crashlytics/Perf plugins — Play upload, fonts/OFL, **reserved-asset
verification**, an **ordered validation table structured for future CI automation**, rollback). `docs/QA_CHECKLIST.md`
= EN+AR × light/dark matrix incl. an **accessibility** section.

### VERIFIED live on emulator (`-gpu host`, Skia) — **release build** (obfuscated + minified), EN + AR
Installed `app-release.apk` (R8/minify on; debug-signing fallback). Launch `Status: ok`.
- **Branding/label:** OS shows "Career Bridge"; emerald splash window; clean Material-3 screens.
- **Fonts (EN):** Language screen renders **Inter** ("Choose Your Language") + Arabic "العربية" in **Cairo** — bundled,
  no network.
- **AR (RTL):** Country screen fully mirrored (title `اختر دولتك`, RTL search, back arrow top-right, dial codes
  LTR-forced) in Cairo.
- **Offline:** airplane mode → after the poll, the **offline banner** appears (AR: `أنت غير متصل بالإنترنت — يتم عرض
  البيانات المحفوظة`, wifi-off icon, white on `#101413`); content stays usable; restoring network **auto-hides** it.
- **Accessibility:** font scale **1.5×** → titles/labels/rows enlarge, subtitle wraps, **no clipping/overlap**
  (graceful). Code scan: **24 `tooltip:` on 20 IconButtons** (icon buttons labelled for TalkBack); standard Material
  semantics; DecorationImage avatars/logos are non-focusable (decorative).

### ♿ Accessibility — remaining limitations (documented, not blocking)
- **Screen reader:** icon buttons carry tooltips (→ semantic labels); a **full TalkBack pass** across every flow
  wasn't automated here — recommended before store launch. Decorative flags/avatars have no explicit `semanticLabel`
  (they're background/decorative, so non-focusable — acceptable).
- **Contrast:** offline banner (white/`#101413`) and body text pass comfortably; **white-on-emerald primary buttons**
  are borderline for AA *normal* text (~2.5:1) though bold/large — an existing brand-design choice, flagged for review
  (not changed here — out of scope + no-regression mandate).
- **Text scaling** verified to 1.5× on representative screens; extreme scales (2×+) on the densest dashboards weren't
  exhaustively swept.

### Notes for the next session
- **App Check is still monitoring-only** and **Storage bucket still unprovisioned** — both are in the RELEASE.md
  manual-steps checklist (§7 there). Nothing in code blocks on them.
- **Real signing:** create the upload keystore + `android/key.properties` per RELEASE.md §3 before the first Play
  upload; enroll in **Play App Signing**.
- **BuildInfo** is a foundation with no UI — an About screen can consume `buildInfoProvider` directly.
- If R8 ever breaks under a future AGP bump, RELEASE.md §6 documents the safe `isMinifyEnabled = false` fallback.

---

## 7.20 Phase 6 · Milestone 4 — Production Polish ✅ COMPLETE

> A **consolidation + hardening** pass — no new features, no new dependencies, no change to the security/Firebase/
> repository layers. It unifies the duplicated UI-state code into one shared widget, layers in accessibility
> semantics, and does audit/perf/validation sweeps. **Behavior-preserving**; `flutter analyze` clean; **466 tests
> pass** (+6); release APK builds under R8. **Five approved additions baked in** (visual/l10n/reuse/code audits +
> the production-readiness report below).

**A · Shared `StatusView` (UX consistency + dead-code removal).** New `lib/shared/widgets/status_view.dart` —
`StatusView.loading / .empty / .error`, the single full-screen state surface (beside `JobDetailView`/`OfflineBanner`;
depends only on core theme/l10n → zero feature coupling). It **canonicalizes the audited drift**: the badge motif
was 88-rounded / 84-circle / bare-56 / bare-64 with `lg`/`md` spacing and 0.35–0.7 opacities → **one 84 tinted
circular badge, 40 icon, `lg`/`sm`/`xl` rhythm, 0.6 muted**. Migrated **8 screens** onto it and **deleted their
private `_Loading`/`_Error`/`_Empty`/`_Busy` classes** (real dead-code removal): `job_matching`, `resume_analyzer`,
`recommendations`, `interview_history`, `cv_preview`, `employer_jobs`, `employer_applicants`, `employer_analytics`.
Bespoke animated hero states (`_NeedsResumeView`, `_AnalyzingView`, career-coach starter-chips empty) were
**deliberately kept** — migrating them would be a redesign, not consistency. `StatusView` **does not self-animate**
(matching the prior widgets, which were animated by their `AnimatedSwitcher` parents — avoids a double-animation and
a pending-timer in tests).

**B · Accessibility.** `StatusView` marks its title `header: true` and wraps the spinner in a `Semantics(label:
commonLoading)` announcement. `OfflineBanner` is now a `Semantics(liveRegion: true)` (announced on connectivity
change; decorative icon/text `ExcludeSemantics`). Filled **5 missing `IconButton` tooltips** (3 password-visibility
toggles → localized Show/Hide password; CV entry delete; job-editor date picker) — every icon-only control now
carries a semantic label. Avatars/logos are `DecorationImage` backgrounds (non-focusable/decorative, with the entity
name as adjacent text → already correct). **Contrast:** the white-on-emerald gradient CTA is the established brand
element used app-wide; per "do not redesign", it's **documented, not restyled** (bold text; darker gradient stops
pass large-text AA).

**C · Performance.** The migration removed ~13 duplicate state classes (fewer rebuild paths); `StatusView` is
const-friendly and timer-free; no new continuous animations; the `main()` startup path is unchanged. Reviewed
`ref.watch` scopes on the heaviest screens — already narrow; no risky changes forced (no-regression mandate).

**D · Audits (the 5 additions).**
- **Widget-reuse (#3):** confirmed none of the 13 shared widgets covers loading/empty/error → `StatusView` is a new
  responsibility, not a duplicate.
- **Visual consistency (#1):** audited spacing/typography/radius/elevation/animation/icon-size across the state
  widgets — the drift found is exactly what `StatusView` canonicalizes; tokens (`AppSpacing`/`AppRadius`/…) already
  consistent elsewhere.
- **Localization (#2):** **zero hardcoded user-facing `Text` literals** in `lib/features` + `lib/shared` — every
  string is `l10n.*`; RTL re-verified live. Terminology consistent. *Limitation:* AI-generated content language
  follows the prompt (already handled since Phase 2).
- **Production code (#4):** `flutter analyze` clean ⇒ the flutter_lints `unused_import` + `unused_element` lints are
  **0** (no unused imports / dead private methods / unused classes); no `withOpacity` (all `withValues`); no
  TODO/FIXME. The one real duplication (the state widgets) is removed by `StatusView`.

**l10n:** +4 keys EN/AR (`commonLoading`, `commonRetry`, `commonShowPassword`, `commonHidePassword`).

**Tests (+6 → 466):** `status_view_test` (5 — loading spinner + "loading" semantics, empty icon/title/message/action,
error message + retry callback, custom retry label, AR localized default); `offline_banner_test` +1 (liveRegion).
The **`render_all_locales` sweep stayed green** through all 8 migrations (renders each migrated screen's states in
EN + AR with no overflow) — the primary regression gate.

### VERIFIED live on emulator (`-gpu host`, Skia) — **release build** (R8/minify on), EN + AR
Registered a fresh employer (`m4polish@cb.app`) to reach empty states.
- **`StatusView.empty` (My Jobs) — AR + EN:** the unified **tinted circular badge** (briefcase) + title ("لم تنشر
  أي وظائف بعد." / "You haven't posted any jobs yet.") + "Post your first job" CTA. Previously a bare icon — the
  consistency win is visible on-device.
- **Offline banner (AR):** airplane mode → the (now `liveRegion`) banner appears over the empty state; content stays
  usable; restore → auto-hides.
- **Accessibility:** password-visibility toggle shows its tooltip; **font scale 2×** on the empty state wraps the
  title to two lines with **no clipping/overlap**.
- **Fonts/RTL/branding:** Inter + Cairo render from the bundle; full RTL; release build launches clean (no crash /
  no R8 regression).

### 🏁 Production readiness report (addition #5)
| Dimension | Status |
| --- | --- |
| **Architecture** | Feature-first + vendor-neutral seams intact; polish added one shared widget (`StatusView`) + semantics at shared seams; **zero feature-to-feature deps**; no new dependencies. |
| **Accessibility** | Every icon-only control tooltip-labelled; `StatusView` headers + loading announcement; offline banner a live region; text-scale-safe to 2×; decorative images excluded. *Remaining:* full TalkBack sweep + white-on-emerald contrast are documented, non-blocking. |
| **Performance** | ~13 duplicate classes removed; const/timer-free `StatusView`; Firestore 40 MB bounded cache + `.limit()` (P6·M2); image decode-downsizing (P6·M2); non-blocking App-Check-after-`runApp` startup (P6·M2). |
| **Localization** | EN + AR complete; **no hardcoded strings**; full RTL; +4 common keys; live-verified both languages. |
| **Testing** | **466 tests** (analyze clean); `render_all_locales` EN+AR sweep is the regression backbone; release APK + AAB build under R8. |
| **Remaining manual deployment steps** | Per `docs/RELEASE.md` §7: create the real upload keystore + `key.properties`; provision the Storage bucket + `firebase deploy --only storage`; enable + enforce App Check (allow-list debug token, Play Integrity); optionally add the Crashlytics/Perf Gradle plugins once AGP-9-ready. **Nothing in code blocks on these.** |

### Notes for the next session
- **`StatusView` is the seam for all future state UX** — new screens should use it (loading/empty/error) rather than
  hand-rolling; further screens with the standard motif can be migrated incrementally.
- Bespoke hero empties (`_NeedsResumeView`, `_AnalyzingView`, coach starter-chips) intentionally stay custom.
- The white-on-emerald CTA contrast + a full TalkBack pass remain the only documented a11y follow-ups.

---

## 7.21 Phase 7 · Milestone 1 — Deployment Preparation (Google Play) ✅ COMPLETE

> **Goal:** prepare every production artifact required for a successful Google Play submission — **without deploying**.
> Deliberately **documentation-only**: **zero** changes to `lib/`, `pubspec.yaml`, Gradle, rules, or dependencies. The
> app that builds today is the app that is documented. `flutter analyze` clean; **466 tests pass** (unchanged); the
> **release `.aab` builds** under R8 (the substantive "release readiness" verification). Approved with 5 additions
> (Arabic listing, AI transparency, screenshot order, equal two-sided positioning, permanent ad-free commitment).

**Deliverables — a self-contained Play submission kit (8 new docs):**

`docs/store/` (submission material):
- **`README.md`** — kit index, submission order, a **fill-in tracker** (every `⟨FILL-IN⟩`: support email, legal entity,
  jurisdiction, hosted Privacy-Policy/Terms/website URLs, keystore, test logins), and the authoritative product-facts table.
- **`STORE_LISTING.md`** — app name, short + full description in **English (primary)** **and a naturally-adapted Arabic
  draft** (not machine-translated; brand title kept, descriptions localized, both seeker + employer sides balanced),
  category **Business**, contact/website placeholders, the **AI-transparency notice** (assist, not professional/legal
  advice), and the **free + permanently ad-free** monetization statement.
- **`STORE_ASSETS.md`** — **specs only, no art generated**: 512² icon (from `assets/icon/app_icon.png`), 1024×500
  feature graphic, phone screenshots with a **recommended order that leads with the strongest features**
  (Resume Analyzer → Job Matching → toolkit → Coach/CV → Employer analytics → Applicants → Interview → Arabic/RTL),
  tablet/promo optional, capture guidance referencing the §10 emulator quirks.
- **`DATA_SAFETY.md`** — the Play Data Safety form answered field-by-field, derived from the **real** data flows
  (Auth/Firestore/Storage/Analytics+consent/Crashlytics/Performance/**Gemini via Firebase AI Logic**/FCM/App Check);
  explicitly discloses résumé/profile text → Gemini; declares no location/financial/ads-ID; encrypted-in-transit +
  deletion-on-request.
- **`PLAY_CONSOLE.md`** — content rating (expected Everyone/PEGI 3), **target audience 18+**, permissions review (only
  `INTERNET` + `POST_NOTIFICATIONS` → no sensitive-permission form), **ads = No / IAP = No** + ad-free commitment,
  **app access** (email test logins + reviewer instructions, phone-OTP caveat), **closed-testing-before-production**
  track plan, `AD_ID` verify-and-declare note.
- **`RELEASE_CHECKLIST.md`** — the master ordered, tickable checklist (A–J: code/build → signing → assets → legal
  hosting → Firebase console → store presence → declarations → QA → rollout → rollback), **cross-linking** RELEASE.md /
  QA_CHECKLIST.md / the other kit docs rather than duplicating.

`docs/legal/` (must be publicly hosted before submission):
- **`PRIVACY_POLICY.md`** — production-ready, grounded in real flows, names every Google processor, dedicated
  **AI-transparency** section, consent lever, deletion rights, 18+, **ad-free** clause. Marked as a template (counsel
  review recommended); `⟨FILL-IN⟩`s for entity/contact/date.
- **`TERMS_OF_SERVICE.md`** — eligibility 18+, acceptable use, user content + AI license, **AI-is-assistance-not-advice**,
  no-outcome-guarantee, IP (incl. OFL fonts), free/ad-free with future-premium clause, disclaimers/liability, governing
  law `⟨FILL-IN⟩`.

**Reused conventions:** new docs live under the existing `docs/` tree beside `RELEASE.md`/`QA_CHECKLIST.md`, and
**cross-link** them (single source of truth for build/console mechanics — no drift). Positioning throughout presents
CareerBridge as **one AI platform serving Job Seekers and Employers equally**.

### Verification (docs milestone — no runtime behavior changed)
- `flutter analyze` → clean. `flutter test` → **466 pass** (nothing in `lib/` touched).
- **`flutter build appbundle --release`** → the Play artifact builds under R8 (release readiness proven).
- **Config audit reconciled into the docs** (all confirmed against the repo): package `com.careerbridge.careerbridge`,
  `minSdk 23`, `version 1.0.0+1`, optional-`key.properties` signing with debug fallback, manifest permissions =
  exactly `INTERNET` + `POST_NOTIFICATIONS`. No live emulator run is meaningful (no code changed); the `.aab` build is
  the substantive check.

### Notes for the next session
- **Nothing in code blocks submission.** Before the *actual* Play upload, complete the `docs/store/README.md` fill-in
  tracker (support email, legal entity, jurisdiction, effective dates), **host** the Privacy Policy (+ Terms) at public
  URLs, and mint the **real upload keystore** + `key.properties` (RELEASE.md §3). Have the legal docs **counsel-reviewed**.
- The pre-existing manual console steps (Storage bucket, App Check enable/enforce, optional Crashlytics/Perf plugins)
  are folded into `RELEASE_CHECKLIST.md` §E — they degrade gracefully and don't block submission.
- Optional polish: native-speaker review of the Arabic listing; capture the EN (and AR) screenshot sets per the
  recommended order.

---

## 7.22 Phase 7 · Milestone 2 — Authentication Enhancements ✅ COMPLETE (feat `09d78cb`)

> **Production-grade account security: phone verification by linking + biometric login + Security Settings.** All behind
> the established vendor-neutral seams (interface + single plugin impl + Noop/in-memory + one provider — the `AiService`
> pattern), **zero product-feature-to-feature deps**, **existing auth/session behavior preserved**. Two new plugins
> (`local_auth`, `flutter_secure_storage`) — the milestone's genuine blockers, **build-verified immediately** (no new
> KGP warning). `flutter analyze` clean; **494 tests pass** (+28). **Live-verified EN + AR** on the emulator.

**Two new core services** (`lib/core/services/`):
- **`biometric/`** — `BiometricService` (`capability()` → available/notEnrolled/unavailable, `authenticate()` →
  success/failed/unavailable/lockedOut) + `LocalAuthBiometricService` (**only file importing `local_auth`**;
  `biometricOnly:false` so device-credential/PIN also satisfies) + `NoopBiometricService` (reports unavailable → app
  never blocks) + `biometricServiceProvider`.
- **`secure_store/`** — `SecureStore` (read/write/bool/delete/deleteAll) + `FlutterSecureStore` (**only file importing
  `flutter_secure_storage`**; Android EncryptedSharedPreferences) + `InMemorySecureStore` (tests) + `SecureKeys` +
  `secureStoreProvider`. Stores **only** the biometric preference + trusted-device marker + the "Not Now" flag —
  **never passwords or session tokens** (Firebase persists its own session securely; the biometric gate sits in front).

**Phone verification = LINK to the existing account (never phone-only sign-in — Decision 1):**
- `AuthRepository` phone methods replaced: `verifyPhoneForLink` + `confirmAndLinkSmsCode` (use
  `currentUser.linkWithCredential`, **preserving the original `AuthMethod`**) + `reauthenticateWithPassword`. New
  `AuthErrorCode`s `requiresRecentLogin`/`phoneAlreadyInUse`/`credentialAlreadyLinked` (+ Firebase-code mappings + l10n).
- `PhoneLinkController` (`autoDispose`) drives send→enter-code→link with a **resend cooldown / expiry countdown** Timer;
  a single **`PhoneVerificationScreen`** (AnimatedSwitcher: number entry w/ country dial-code reuse → OTP) reached from
  Security Settings. **The old `phone_auth_screen.dart` + `otp_verification_screen.dart` (phone SIGN-IN) were deleted**;
  the Welcome "Continue with Phone" button was removed.

**Biometric login (app-launch gate over the already-persisted Firebase session — Decision 3):**
- `BiometricSettingsController` (`{capability, enabled, loaded}`; `enable()` requires a successful biometric confirm
  then persists + sets a trusted-device id + clears "Not Now"; `disable()`; `reset()`; `shouldOfferEnrollment()`;
  `declineEnrollment()`; `ensureLoaded()` for the splash gate; `gateActive = enabled && available`).
- **Enrolment sheet** offered **once** after a fresh **email/Google** sign-in (`maybeOfferBiometricEnrollment`, awaited
  before `goAfterAuth`), gated on capability, and a **"Not Now" is remembered** (never re-nags; re-enable in Settings).
- **`SplashScreen`** now branches: session exists **AND** `gateActive` → **`AppLockScreen`** (auto-prompts biometrics;
  success → `goToRoleHome`; fail/cancel → "Sign in another way" = sign-out → Welcome). Otherwise the flow is
  **byte-for-byte identical to before** → **existing users unaffected, no migration** (biometric defaults off).
- **Invalidation rules:** logout (`SettingsScreen._confirmLogout`) and a successful **password change**
  (`ChangePasswordController`) both call `reset()` → a normal sign-in is required before biometric can be re-enabled
  ("re-authentication when required", enforced by invalidation rather than gating the toggle).

**New `lib/features/security/`** (depends only on core + the auth repository interface → zero feature-to-feature deps):
`security_settings_screen.dart` (biometric toggle — **available→interactive / not-enrolled→disabled+hint /
unavailable→hidden**; remove-trusted-device; verify-phone row showing "Verified ✓ ••••NNNN" once linked),
`app_lock_screen.dart`, `biometric_enrollment_sheet.dart`, `biometric_settings_controller.dart`. Settings gains a
**Security** entry (shield) between Change Password and Log out.

**Native + deps:** `MainActivity` → **`FlutterFragmentActivity`** (required by `local_auth`); `USE_BIOMETRIC` in the
manifest; iOS `NSFaceIDUsageDescription`. `local_auth ^2.3.0` + `flutter_secure_storage ^9.2.2` added; **debug APK +
(earlier) release AAB build green** — no new KGP warning. **+~40 EN/AR l10n keys** (security/biometric/app-lock/
phone-verify + `otpResendIn` placeholder), full RTL.

**Tests (+28 → 494):** `secure_store_test` (in-memory store), `biometric_settings_controller_test` (offer/decline/
enable-requires-auth/disable/reset/gateActive, with a `FakeBiometricService`), `phone_link_controller_test`
(send→code→link + empty/short-code/error paths via `FakeAuthRepository`), `security_settings_screen_test`
(available/not-enrolled/unavailable UI states), `auth_exception_test` (new code mappings); `render_all_locales` now
renders `PhoneVerify`/`AppLock`/`Security` EN+AR; `FakeAuthRepository` extended with link/reauth spies;
`change_password_controller_test` + `render_all_locales` + `widget_smoke_test` override the biometric/secure providers.

### VERIFIED live on emulator (`-gpu host`, Skia `--no-enable-impeller`), EN + AR
Enrolled a device PIN + fingerprint (`emu finger touch 1`). Persisted employer session (`m4polish@cb.app`).
- **Existing user unaffected:** first launch (biometric off) → straight to Employer Home, no gate.
- **EN:** Settings → **Security** (biometric toggle **available/interactive** since a fingerprint is enrolled) → enable →
  **system fingerprint prompt** → "Biometric login enabled" + "Remove trusted device" appears. **Relaunch → AppLock →
  auto fingerprint prompt → unlock → Home** (biometric persisted). **Verify phone**: 🇶🇦 +974 dial-code + field + Send
  Code → request fires (loading) → **graceful backend-failure** (logcat `17499` reCAPTCHA/region not configured →
  `onVerificationFailed` → localized snackbar, no crash, stays on entry). *(Full OTP→link needs Firebase phone-auth
  backend config — reCAPTCHA Enterprise key / SMS region / a test number — the documented manual dependency; the link
  logic itself is fully unit-tested.)*
- **AR (RTL):** switched to العربية → **Security** screen fully mirrored (الأمان, toggle ON with icon on the right,
  إزالة الجهاز الموثوق, التحقق من رقم الهاتف, chevrons/back mirrored) → **relaunch → AppLock gate → fingerprint unlock →
  Arabic Employer Home**.

### Notes for the next session
- **`BiometricService` + `SecureStore` are the seams for any future sensitive gate** (re-auth before payments, etc.).
- **Phone OTP→link end-to-end** needs the Firebase Console: enable phone-auth reCAPTCHA/App-Check or add a **test phone
  number** (Auth → Phone), or allow the SMS region (§5). Until then it degrades gracefully.
- Emulator biometric verification recipe: `adb shell locksettings set-pin 1234`; enroll via
  `am start -a android.settings.FINGERPRINT_ENROLL` → I AGREE → `adb emu finger touch 1` ×~10 (watch `dumpsys
  fingerprint` `"count"`); satisfy an in-app prompt with a single `emu finger touch 1`. The **system BiometricPrompt
  screencaps as black** (it's a system surface) — expected, not a bug.
- Consider promoting the OTP input to a shared widget if a second consumer appears (kept inline now — single consumer).

---

## 7.23 Phase 7 · Milestone 3 — Multiple CV Repository ✅ COMPLETE (feat `0b01504`)

> A **Firestore-backed** repository for keeping **multiple CVs**, each with its own AI results, integrated with the
> existing AI features **via core seams only** (zero feature-to-feature deps). `flutter analyze` clean; **527 tests**
> (+33); **live-verified EN + AR** on the emulator with **real Firestore** (`resumes/{resumeId}` rules deployed).

**Core service `lib/core/services/cv_repository/`** (the `AiService`/`UserProfileRepository` seam — placed in **core** so
CV Builder + the AI features depend on core, never on the CV feature):
- **`CvDocument`** aggregate = metadata (`name`, `tags`, `status{active,archived}`, `isDefault`, `version`, `source
  {built,imported}`, `createdAt`/`updatedAt`, soft-delete `deletedAt`, last-used `lastUsedAt`/`lastAppliedJobTitle`/
  `lastAppliedCompany`, `importHash`) + **content** (reuses `CvData`) + **per-CV AI** (`ResumeAnalysis` + derived
  `atsScore`, **owned** `CvMatchResult` list, `CvRecommendationSummary` — the last two decoupled from job_matching/
  recommendations). Pure lifecycle methods (the `JobPosting` pattern): `renamed`/`archived`/`restored`/`asDefault`/
  `withContent`(++version)/`withAnalysis`/`withMatches`/`markUsed`/`softDeleted`/`duplicatedAs`. Deterministic FNV-1a
  `contentHash` + `hashBytes` for import dedup. (Reuses `CvData`/`ResumeAnalysis` **models** exactly as the existing
  `cv_draft_store`/`resume_analysis_store` core seams already do — model reuse, not feature-logic coupling.)
- **`CvRepository`** interface + **`FirestoreCvRepository`** (ONLY cloud_firestore importer for CVs; `resumes/{resumeId}`;
  `where ownerUid == uid` + `.limit(300)` + **client-side sort + soft-delete exclusion** to avoid a composite index;
  `setDefault` = a batch enforcing a single default; graceful-degrade when `!isReady`) + `InMemoryCvRepository` +
  `cvRepositoryProvider` + `cvDocumentsProvider`/`activeCvsProvider`/`defaultCvProvider`/`cvByIdProvider.family`.
- **`LastSelectedCvController`** (persists the apply-picker's last choice via `LocalStorageService`, `StorageKeys.lastSelectedCvId`).

**Feature `lib/features/cv_repository/`** (depends only on core + the auth/resume-analyzer/job-matching *providers* +
navigation): **`CvLibraryController`** (search over **name + tags**, status filter, sort) + `visibleCvsProvider`;
**`CvActionsController`** (create/import/rename/duplicate/archive/restore/set-default/soft-delete) enforcing the five
approved additions — **(1)** the first CV is **auto-default**, **(2)** removing the default **auto-promotes** another
active CV, **(3)** the user always keeps **≥1 active CV** (delete/archive of the last is **blocked** with a localized
message), **(4)** **tags** (searchable), **(5)** **import dedup** by source-PDF hash → Replace / Import-as-new / Cancel;
**`CvAiController`** writes each CV's own analysis/matches/recommendations back onto the doc (reads the shared core
seams + the job-matching repo — the AI features stay unaware of CVs). Screens: **CV Library** (search/filter/sort chips,
`StatusView` empty/loading, Create/Import FAB sheet, per-card overflow menu) + **CV Detail** (metadata badges, content
card → Edit in Builder, AI-insights card: ATS gauge / matches / recommendations with analysis-gating). Shared
`cv_picker_sheet.dart` (choose-CV-to-submit).

**Integrations (core seams + navigation only — no new feature-to-feature deps):**
- **CV Builder** gains an optional **`cvId`** (route `extra`): loads that CV's content, edits + AI-enhances, and a
  **"Save to My CVs"** action writes it back (`withContent`, ++version). **No `cvId` ⇒ byte-for-byte the old
  single-draft behavior** (no regression).
- **Import** reuses the **resume-analysis pipeline** (approved) → creates a `CvDocument(source: imported)` with the
  analysis attached.
- **Apply flow** (`job_detail_screen`): with **≥2 active CVs** a `cvPickerSheet` appears (preselects last-used/default,
  **remembers** the choice, stamps the CV's **last-used**); 0–1 CV applies directly. Shared **`Application`** gained
  optional `cvId`/`cvName` (additive; `apply({job, cvId?, cvName?})`).
- Home **"My CVs"** tile (`RouteNames.cvLibrary`); routes `cvLibrary` (`/cvs`) + `cvDetail` (`/cvs/:id`).
- **`resumes/{resumeId}` `firestore.rules`** (owner-scoped, `ownerUid` immutable on update, `name` capped) — **DEPLOYED**.

**Tests (+33 → 527):** `cv_document_test` (lifecycle + JSON round-trip + content/byte hashing), `cv_repository_test`
(soft-delete exclusion, owner-scoping, **setDefault single-default invariant**), `cv_library_controller_test`
(search name+tags / filter / sort), `cv_actions_controller_test` (**auto-default**, **last-CV protection**,
**default auto-promotion**, import-new/replace), `last_selected_cv_test`, `apply_with_cv_test`; `render_all_locales`
now renders `CvLibrary` + `CvDetail` EN + AR.

### VERIFIED live on emulator (`-gpu host`, Skia `--no-enable-impeller`), EN + AR — **real Firestore**
On a **seeker** account (`appreg030157@cb.app`): Home → **My CVs** → CV Library loads from Firestore (empty state) →
**Create CV** (name + a "Flutter" tag) → **persisted to `resumes/{…}`** → CV **Detail** shows **Default** (auto-default)
+ **Built** + **v1** + "Not used yet" + content card (Edit in CV Builder) + AI-insights (Not analyzed / Find-matching
gated on analysis). List **card** shows the badges + overflow menu (**"Set as default" correctly hidden** when already
default). **Default protection proven:** deleting the only active CV is **blocked** with *"You must always have at
least one active CV…"*. **AR (RTL):** switched to العربية → CV Library fully mirrored (**سِيَري الذاتية** title, RTL
search **ابحث في السير والوسوم**, **نشطة/مؤرشفة** chips, the same persisted **My CV** card with **افتراضية/مُنشأة**
badges + left-side ⋮, **إنشاء سيرة** FAB bottom-left).

### Notes for the next session
- **The `resumes` rules are deployed** — the CV feature is fully live. A running app must be **relaunched** after any
  future rules change (a denied Firestore listener stays in loading state and doesn't auto-recover — the §7.13 lesson;
  this was hit live before deploying and fixed by deploying + relaunch).
- **Emulator was wiped** this session (GPU-surface corruption after cold-boot — §10; `-wipe-data` cleared it). The
  device now has a **fresh seeker session `appreg030157@cb.app`** with **one CV ("My CV", default)** and language
  persisted **Arabic**; no biometric enabled (fresh install).
- **AI write-back scope:** analysis + ATS are fully wired (imported at import; attachable from the last analysis);
  matches use the job-matching repo → owned `CvMatchResult`; recommendations snapshot from the core store. Per-CV
  analysis for *built* CVs is attached from the Resume Analyzer's cached result (a PDF-less CV isn't auto-scored).
- Forward-ready (shaped, not built): **version history** (`version` + a `resumes/{id}/versions` subcollection),
  **sharing** (owner rule ready), **templates** (`CvSource` + Builder templates), **export history**
  (`resumes/{id}/exports`).

---

## 7.24 Phase 7 · Milestone 4 — Internships & Learning ✅ COMPLETE (feat `0dc6274`)

> Extend the job platform with **internships** and a **learning-interests** profile, **reusing** the existing
> Job/JobPosting/Application architecture (the milestone's "don't duplicate Jobs" mandate) and the vendor-neutral
> core-seam pattern. `analyze` clean · **571 tests** (+44) · **live-verified EN + AR**; `users/{uid}/learning` rules **deployed**.

### Internships (reuse by embedding + projection — no parallel jobs stack)
- **`lib/shared/models/internship_details.dart`** — `InternshipDetails` value object embedded on `Job` + `JobPosting`
  (exactly like `SalaryRange`/`JobMetrics`), with **7 enums in shared** (`InternshipFunding`, `InternshipCategory`,
  `InternshipLevel`, `InternshipDuration`, **`WorkMode` remote/hybrid/on-site**, **`InternshipEligibility`**
  university/fresh-grad/everyone, **`InternshipSchedule`** full/part/flexible) + `certificateProvided` + `stipendAmount`/
  `currency` + **`startDate`/`applicationDeadline`**. Enums live in **shared** (not `features/employer`) so the seeker
  `Job` embeds them without a seeker→employer dep. Fully defensive JSON + `copyWith` **clear-flags** per nullable field
  (so editor chips can deselect-to-null). `internship_details_l10n.dart` (also shared) maps each enum → localized label.
- **`Job`** (+`internship`/`trainsBeginners`/`isInternship`) and **`JobPosting`** (+ same + `isInternship`) extended
  additively. **`JobPosting.toJob()`** projects `internship` (only when the type is Internship + non-empty) +
  `trainsBeginners` so the seeker surface sees them with no per-feature change.
- **`JobDetailView`** (shared) now renders **Internship / Trains-beginners highlight badges** + an **"Internship details"**
  card (label→value rows using `intl` `DateFormat` for the dates). The employer **preview** and seeker **detail** render
  identically (one widget).
- **`lib/features/internships/`** — `InternshipsController` (a **scoped consumer** of `JobsRepository`: fetches jobs,
  keeps `isInternship`, applies text + facet filters `funding/workMode/category/level` in-memory), `InternshipsScreen`
  (search + filter sheet + `StatusView` states + count), `InternshipTile`, `InternshipFilterSheet`. **Detail reuses
  `/jobs/:id`** (no dedicated detail screen — approved).
- **Employer editor** (`job_editor_controller`/`job_editor_screen`) gains `setTrainBeginners`, `updateInternship`, and
  `setInternshipWorkMode` (also derives the legacy `remote` bool so the seeker's `remoteOnly` filter keeps working) +
  a **Train-Beginners switch** and an **internship section** (choice-chip groups + certificate switch + stipend field +
  start/deadline date rows), shown only when `employmentType == Internship`. **Train Beginners is a persisted flag +
  badge + documented recommendation-weight hook only — NO AI implemented** (per the milestone).

### Learning Interests (new core seam)
- **`lib/core/services/learning/`** — `LearningProfileRepository` interface + `FirestoreLearningProfileRepository`
  (**only** cloud_firestore importer; one small doc at `users/{uid}/learning/interests`; graceful-degrade when not ready;
  **offline-bounded save**: `set().timeout(2s)` → a timeout means the write is durably queued in the offline cache and is
  treated as an **optimistic success** so the UI never hangs offline) + `InMemoryLearningProfileRepository` +
  `learningProfileRepositoryProvider`/`learningProfileProvider`.
- **`lib/shared/models/learning_profile.dart`** — `LearningProfile` (one flat list, 5 `LearningCategory` values) +
  `LearningInterest` (deterministic FNV-1a de-dup id from category+label). Pure `added`/`edited`/`removed`/`search`/
  `byCategory` transitions (the `CvDocument` pattern).
- **`lib/features/learning/`** — `LearningController` (reads the reactive profile, applies a pure transition, persists;
  search held in state), `LearningInterestsScreen` (5 category cards + search + failure snackbar), `InterestCategoryCard`
  (add button + `InputChip`s), `InterestEditorSheet` (add/edit label+note).

### Applications integration
- **`Application`** gains a denormalized **`isInternship`** (stamped from `job.isInternship` in `Application.create`,
  defensive JSON). `ApplicationsFilter` gains **`internshipsOnly`** + a chip in the filter sheet + `filteredApplications`
  narrowing. Apply/track/withdraw + the **multi-CV picker** are reused **unchanged**.

### Wiring / rules / tests
- Home gains **Internships** + **Learning Interests** CTAs; routes `internships` (`/internships`) + `learning`
  (`/learning`). ~70 EN + AR l10n keys (naturally-adapted Arabic). `firestore.rules`: owner-scoped
  `users/{uid}/learning/{docId}` (read/write if `request.auth.uid == uid`) — **deployed**.
- **+44 tests → 571**: `internship_details_test`, `job_internship_test` (`toJob` projection + backward-compat),
  `learning_profile_test`, `learning_repository_test`, `learning_controller_test`, `internships_controller_test`,
  `application_internship_test`; `job_detail_screen_test` now wraps in real `AppTheme` + adds an internship-detail render
  guard; `render_all_locales` renders Internships + Learning EN + AR.

### 🐞 Latent bug fixed (surfaced live)
- The seeker **`_ActionBar`** in `job_detail_screen.dart` had the **§7.14 bug #2** shape — the "Ask coach"
  `OutlinedButton` was **not** wrapped in `Expanded`, so the theme's full-width (`Size.fromHeight`, i.e. infinite-width)
  button style asserted in the `Row`. Never verified live before (documented follow-up); the internships→`/jobs/:id`
  flow surfaced it. **Fix:** wrap it in `Expanded` (both buttons now bounded). Regression guard: `job_detail_screen_test`
  now uses the real `AppTheme`.

### VERIFIED live on emulator (`-gpu host`, Skia `--no-enable-impeller`), EN + AR — real Firestore (offline cache)
Seeker **`appreg030157@cb.app`**. **AR:** Internships list (٤ فرص تدريب, work-mode/funding/duration chips + يدرّب المبتدئين
badge) → internship **detail** (تفاصيل التدريب card — all fields incl. work-mode هجين / eligibility طلاب الجامعات فقط /
certificate شهادة مُقدَّمة / stipend USD 1200) → **Learning** (5 category cards) → **add** "Data Science" (persisted to
Firestore offline cache, **survived a full app restart**, count → عنصر واحد) → **delete** (back to empty). **EN:**
Internships list → **filter** Paid (→ 2 results, badge "1") → UX Design Intern **detail** (Funding Paid / Work mode
On-site / Schedule Full-time / Duration 6–12 months / Category Design / Level Graduate / Eligibility Fresh graduates /
Certificate No certificate / Stipend 900 USD) → **Apply** ("Application submitted", button → Applied) → **Learning** (5
categories, LTR). Settings language switch AR↔EN confirmed.

### Notes for the next session
- **Emulator DNS is currently broken** (`unknown host firestore.googleapis.com`; WiFi up but the 10.0.2.3 forwarder
  isn't resolving) → the app runs **offline** (offline banner shows, Firestore writes queue in the local cache and sync
  on reconnect). This is an **env issue** (§10-style), not an app defect — all seeker flows verified against the offline
  cache. A fresh session on a healthy emulator can confirm the server round-trip + re-verify.
- **Employer internship editor was NOT live-verified this session** — switching to `employer01@cb.app` needs auth, which
  the broken DNS blocks. It is **test-verified** (`render_all_locales` JobEditor EN+AR under real `AppTheme` +
  `job_editor_controller` unit tests + the shared `JobDetailView` internship render). Re-verify live when DNS is healthy:
  employer → create job → type Internship → fill funding/work-mode/eligibility/schedule/certificate/dates + Train
  Beginners → Preview (shows the same `JobDetailView`) → publish.
- **AI is intentionally NOT implemented** — `trainsBeginners` + the learning interests are persisted signals + a
  documented hook for a future beginner-weighted recommendations pass; the milestone said "prepare the architecture only".
- **Future-ready (shaped, not built):** Mentors / Learning Marketplace / Career Learning Paths / University Partnerships
  all anchor on the `users/{uid}/learning/*` namespace + the internship `level`/`eligibility` axes.

---

## 7.25 Phase 7 · Milestone 5 — Deployment & Publishing ✅ COMPLETE

> **Goal:** finish **every remaining production task except the actual Google Play upload.** This is a **review →
> reconcile → verify → sign-off** milestone, not a feature build — almost all production infra already existed
> (release build/R8/signing config, the `docs/store/` Play kit, `docs/legal/` templates, `RELEASE.md`/`QA_CHECKLIST.md`,
> hardened+deployed `firestore.rules`). Its value is (a) closing the **documentation drift** that P7·M2–M4 introduced
> after the P7·M1 store kit was frozen, (b) **executing** the one deferred production verification (advertising-ID),
> and (c) producing a single evidence-backed **Go/No-Go readiness report**. Behavior-preserving: **no new deps, no
> rules change, no architectural impact.** `analyze` clean · **574 tests** (+3) · release `.apk`+`.aab` build under R8.

### The one code change — advertising ID (AD_ID) stripped
- **Finding (verified):** the merged **release** manifest pulled in `com.google.android.gms.permission.AD_ID` (merged by
  `firebase_analytics`). Career Bridge uses **no advertising ID**, so `PLAY_CONSOLE.md` §7 had left this as a
  "verify-at-build-time" TODO. This milestone executed the verification.
- **Fix:** `android/app/src/main/AndroidManifest.xml` now declares `xmlns:tools` and
  `<uses-permission android:name="com.google.android.gms.permission.AD_ID" tools:node="remove"/>`. **Re-built the
  release APK and confirmed `AD_ID` is absent from the merged manifest** (`grep` count 0; `USE_BIOMETRIC` present).
  `tools:` attributes are build-time-only (no runtime effect) — cannot affect behavior/rendering.
- **Regression guard:** new **`test/android_manifest_test.dart`** (3 tests → **574**) asserts the app requests exactly
  `INTERNET`/`POST_NOTIFICATIONS`/`USE_BIOMETRIC`, that `AD_ID` is removed, and that no dangerous permission appears.

### Documentation drift closed (P7·M1 store kit predated M2–M4)
- **`docs/store/PLAY_CONSOLE.md`** — permissions table now lists **3** perms (added `USE_BIOMETRIC`, normal, no runtime
  prompt); the AD_ID note resolved to the verified "removed → declare not-used" outcome.
- **`docs/store/DATA_SAFETY.md`** — declares **biometric data = not collected** (`local_auth` `BiometricPrompt` is
  on-device; never transmitted) and **secure-storage flags = on-device-only** (`flutter_secure_storage` holds only the
  biometric preference + trusted-device marker, never passwords/tokens); confirms `resumes` + `users/{uid}/learning` are
  already covered by the existing "Résumé / CV & career content" row.
- **`docs/store/README.md`** — product-facts permissions row updated (3 perms + AD_ID removed).
- **`docs/store/RELEASE_CHECKLIST.md`** — baseline 466→**574**; AD_ID line resolved; AI-transparency line added;
  cross-links the new readiness report.
- **`docs/RELEASE.md`** — validation table gains a manifest/permissions row + an AD_ID merged-manifest check; test
  baseline → 574.
- **`docs/store/STORE_LISTING.md`** — light EN **+ AR** additions surfacing what shipped since M1: **biometric login,
  multiple CVs, internships browsing, learning interests** (kept well under the 4,000-char limit).

### New headline deliverable — `docs/PRODUCTION_READINESS.md`
An **evidence-backed Go/No-Go report** (not a duplicate of the mechanics checklist — it **cross-links** RELEASE.md /
RELEASE_CHECKLIST.md / DATA_SAFETY.md). Contents: **(1)** a **final production status table** separating ✅ completed
engineering (Release build · Play paperwork · Firebase code/rules · Security · AI · Monitoring) from ⚠️ manual
pre-launch (Legal hosting · Upload keystore · App Check enforce · Storage bucket); **(2)** the verification evidence
(analyze/test/build results); **(3)** all **9 dimensions** — Release build · Firebase · Security · Google Play · Legal ·
Privacy · QA · AI · Monitoring · Rollback; **(4)** the **versioning strategy** (`1.0.0+1` confirmed for the first
submission; semver marketing + strictly-increasing build code); **(5)** a closing **"Remaining Before Publish"**
checklist containing **only** the non-automatable manual actions.

### Security audit (results → the readiness report §5)
- `.gitignore` covers `google-services.json` / `android/key.properties` / `*.jks`; **none is git-tracked**;
  `firebase_options.dart` is committed (client identifiers, not secrets); **no hardcoded secrets** in `lib/`; the App
  Check **debug token is not in code**. Manifest: single exported launcher activity, no `usesCleartextTraffic`, no
  `android:debuggable`. All egress HTTPS. The merged manifest's other permissions (`ACCESS_NETWORK_STATE`, `WAKE_LOCK`,
  `USE_FINGERPRINT`, c2dm `RECEIVE`, `READ_GSERVICES`, install-referrer, Privacy-Sandbox `ACCESS_ADSERVICES_*`) are all
  **normal**, merged by Firebase/Messaging/`local_auth`, and trigger **no Play permissions-declaration form**.

### VERIFIED live on emulator — **release build** (R8/minify, AD_ID stripped), EN + AR
Installed `app-release.apk` on `emulator-5554` (seeker `appreg030157@cb.app`, persisted session).
- **EN:** Home rendered fully — Browse Jobs, My Applications, **Internships** ("Find and apply to internships"),
  **Learning Interests** ("Track what you want to learn"), AI toolkit cards. Navigated Home → **Settings** (Account /
  Security "Biometric login and phone verification" / Language / Theme / notification toggles) — **responsive**.
- **AR (RTL):** switched Settings → Language → العربية → full mirror: "الإعدادات" with back-arrow on the right,
  "الحساب"/"التفضيلات" right-aligned, "الأمان — تسجيل الدخول بالسمات الحيوية والتحقق من الهاتف", toggles mirrored, Cairo
  font. Switched back to EN.
- **⚠️ Emulator GPU note (not an app defect — §10):** under `-gpu host`, the first launch rendered the Home screen but a
  cold-boot **ANR** then a deterministic **`1.raster`-thread `SIGSEGV/SIGABRT` inside `libflutter.so`** (zero app code in
  the backtrace) blocked interaction — the classic host-GPU/**Impeller-on-emulator** crash. Re-launching the emulator
  with **`-gpu swiftshader_indirect`** (software renderer, bypasses the host Vulkan driver) rendered **cleanly and
  stably** through the whole EN+AR sweep. This isolates the crash to the emulator's graphics stack; the release build +
  AD_ID change are unaffected. **A physical-device QA pass (already a documented pre-launch item) should confirm Impeller
  on real hardware** — where Impeller is the supported default.

### Remaining before publish (all user-side, non-automatable — see `docs/PRODUCTION_READINESS.md`)
Real upload keystore + `key.properties`; fill legal/store `⟨FILL-IN⟩`s + counsel-review + **host** Privacy Policy/Terms;
provision the **Storage bucket** + `firebase deploy --only storage`; **App Check** enable→Play-Integrity→enforce;
*(optional)* Crashlytics/Perf Gradle plugins; Play Console create/sign/list/declare/closed-test. **Nothing in code
blocks launch** — all degrade gracefully.

---

## 7.26 Stabilization Milestone — 9 Bug Fixes ✅ COMPLETE (feat `a603549`)

> **Bug-fix / stabilization only — no new features.** Root-cause fixes, existing behavior preserved, no architecture
> change, minimal blast radius. `analyze` clean · **592 tests** (+18) · release `.apk` builds under R8 · **live-verified
> EN + AR** on the release build. Investigation used 5 parallel Explore agents; each bug's root cause was confirmed
> before touching code (and bugs 2/3 were reproduced live first).

**1 · Google Sign-In (config, not code).** The app signs in with Firebase federated `signInWithProvider(GoogleAuthProvider())`
(no `google_sign_in` plugin); `android/app/google-services.json` has an **empty `oauth_client: []`** and **no SHA-1** ever
registered, so the OAuth handshake can't complete → the old opaque "Something went wrong." **Fix (code):** map the
config-failure Firebase codes (`internal-error`/`admin-restricted-operation`/`app-not-authorized`/`invalid-oauth-*`/
`missing-client-identifier`/`unauthorized-domain`) → new **`AuthErrorCode.configurationError`** → `errConfiguration`
(EN/AR). **Fix (docs):** **`docs/GOOGLE_SIGNIN_SETUP.md`** — the debug SHA-1 (`22:A0:…:CE`) + SHA-256, and the exact
console steps (enable Google provider → register SHA → refresh json → verify on a **real device**). These console steps
are **user-side** (chosen: code diagnostics + runbook).

**2 / 3 · Job & Internship Details layout.** Investigation found the current build already renders these screens cleanly
at normal widths, and **all job-detail entry points share ONE `/jobs/:id` route** (Job Matching results aren't even
tappable; Recommendations pushes the same route) — so Coach/Recommended details are byte-identical to Browse. The real
root cause of the reported "character-by-character vertical text" is a **narrow-width starvation**: the internship
label→value row had a fixed `SizedBox(width:130)` label + `Expanded` value, so on a tight layout the value collapses and
a long word wraps per-character. **Fix:** new `_DetailRow` in `job_detail_view.dart` — side-by-side when there's room,
**stacked (value beneath label) under ~260px** so the value always gets full width; hardened `_HighlightBadge`/`_MetaChip`
(`Flexible` + `TextOverflow.ellipsis` — no narrow-width overflow) and the seeker `_MatchSection` loading row. Regression
guard: **`test/internship_detail_layout_test.dart`** renders the internship card at 360px + 220px in EN + AR with no
overflow.

**4 · RTL/bidi "SQL"→"LQS" (PDF only).** The Flutter UI was already correct (no manual reversal, no forced
`Directionality(rtl)`). The reversal was exclusively the CV **PDF**: `ats_template` set a page-level `pw.TextDirection.rtl`
and the `pdf` package runs **no** Unicode bidi, so Latin runs emitted right-to-left. **Fix:** removed the page-level
direction; every content string goes through a new **`_txt`** that picks direction **per run** (Arabic→RTL, else LTR)
with document-aligned paragraphs (`crossAxisAlignment` end for RTL) — Latin (skills/URLs/email) stays LTR while Arabic
stays RTL. Contact line is `forceLtr` (email/phone dominant).

**9 · CV PDF formatting (same file).** Long GitHub/LinkedIn URLs were joined into one `pw.Text` with no break points →
overflow. **Fix:** `_cleanUrl` strips `https://`/`www.`/trailing slash + inserts a zero-width space after each `/`; each
link renders on **its own line**. Empty sections were already suppressed. Both fixes also apply to the on-screen WYSIWYG
`PdfPreview` (same code path); `render_all_locales` CvPreview EN + AR still pass (the PDF generates in both locales).

**5 · Default country = Qatar (full scope).** `CountryController` now defaults to **`CountriesData.defaultCountry`**
(Qatar) instead of null (a persisted choice still overrides). Browse Jobs `_load` seeds the location filter to the user's
country, and `SeedJobsRepository` location match now **includes remote jobs** (open regardless of country). New
**country dropdown** in `JobFilterSheet` (🇶🇦 Qatar default + "All countries"); `setCountry(String?)` on the browse
controller; `clearFilters` restores the default country. Country is threaded as context into **Job Matching** (rank
prompt: "Based in … prefer roles there or remote"), **Career Coach** (system instruction), and **Interview** (via
`InterviewContext.country`). Live-verified: Browse shows **13 jobs** (Qatar + remote; 5 on-site non-Qatar filtered out).

**6 · Currency QAR + dual display.** New **`lib/core/utils/currency_converter.dart`** — offline peg-based table (QAR/AED/
SAR/JOD exact pegs, EGP/EUR/GBP approximate). `formatDual(1200,'USD')` → **"QAR 4,368 (~ USD 1,200)"**; same-currency →
single value; unknown → original untouched. Applied to the internship stipend (`job_detail_view`). Defaults flipped
USD→QAR were **not** forced onto seed data (no salary on seeker jobs); the converter handles the USD stipends. Unit test
`test/currency_converter_test.dart`.

**7 · Arabic job content (all user-facing fields).** Added optional **`titleAr`/`descriptionAr`/`locationAr`** to the
seeker `Job` (+ defensive `fromJson` incl. snake_case) with `titleFor(lang)`/`descriptionFor(lang)`/`locationFor(lang)`
(ar variant when present, **English fallback** otherwise). Translated **all 18 seed jobs** (title + description + location)
into natural Arabic (companies/skills kept — brand/technical). New **`lib/shared/models/job_l10n.dart`** localizes the
controlled-vocab `employmentType`/`seniority` chip strings via existing `empType*`/`jobExp*` keys. Rendered in
`JobDetailView`, `job_list_tile`, `internship_tile`, `job_match_card` (RecJobCard already uses AI-localized content).
Unit test `test/job_localization_test.dart`. Live-verified: Arabic titles ("مهندس تطبيقات جوّال (Flutter)"), Arabic
descriptions, Arabic locations ("الدوحة، قطر").

**8 · Interview copy button.** A copy `IconButton` beside "Sample strong answer" (`interview_prep_screen`) →
`Clipboard.setData` → reuses `showAuthSnack(l10n.commonCopiedToClipboard)` ("Copied to clipboard." / "تم النسخ إلى
الحافظة."). New l10n `commonCopy`/`commonCopiedToClipboard`.

### Test-setup notes (for the next session)
- The country default made `CountryController` (→ `localStorageProvider`) transitively read by the interview controller
  (`buildContext`) and the jobs browse controller. Three test files gained a **`localStorageProvider` override**
  (`interview_prep_flow`, `interview_prep_screen`, `jobs_browse_controller`); the coach fake repo got the new `country`
  param. `jobs_browse_controller_test` was rewritten to assert the Qatar-default + `setCountry` behavior.
- **AD_ID / manifest test** and the P7·M5 deployment docs are unaffected (still 574→now 592 with these +18).

### VERIFIED live on emulator (`-gpu swiftshader_indirect`, seeker `appreg030157@cb.app`) — release build, EN + AR
`-gpu host` still Impeller-crashes on this emulator (§10) → used the **software renderer** (stable). **AR:** Browse Jobs
= **13 jobs** with Arabic titles/locations + localized type/level chips; filter sheet shows **الدولة → 🇶🇦 Qatar** +
localized chips; internship detail = Arabic title + **Arabic description** + stipend **"QAR 4,368 (~ USD 1,200)"** + clean
label→value card. **EN:** internship detail stipend **"QAR 4,368 (~ USD 1,200)"**, English description (fallback), clean
card. Bugs 4/8/9 covered by passing PDF-render (`render_all_locales` CvPreview EN+AR) + feedback-card + unit tests (the
default CV was empty, so no on-device PDF eyeball; the per-run bidi is logic-verified).

### Remaining / notes
- **Bug 1 needs the user:** enable the Google provider + register SHA-1/256 in the Firebase console, refresh
  `google-services.json`, and verify on a **real device** (Google sign-in is flaky on bare emulators) — see
  `docs/GOOGLE_SIGNIN_SETUP.md`. Nothing else here depends on it.
- Emulator now has the **release APK** with a seeker session, **English** locale (last toggle), 1 empty CV.
- The `_countryLine`/country prompt additions are gentle preferences (not hard filters) — the AI still returns all ranked
  jobs.

---

## 7.27 Follow-up Stabilization — Job-Detail Vertical Text + Qatar Defaults ✅ COMPLETE (feat `6cfcc97`)

> **Bug-fix / stabilization only — no new features.** Four real-device reports still open after §7.26. Each root cause
> was **reproduced live on the emulator before touching code** (issues 2/3/4) or re-verified via source audit (issue 1).
> `analyze` clean · **595 tests** (+3) · release `.apk` (73.1 MB) builds under R8 · **live-verified EN + AR** at both
> normal and extreme (360dp + font scale 1.8) conditions. Investigation used 4 parallel Explore agents.

**2 · "Vertical text" in Job Details (For You → Recommended → View Job) — the prior fix was in the wrong file.**
§7.26 hardened the internship label→value `_DetailRow` in `job_detail_view.dart`, but that row only ever wraps by *word*
(all its values are short/multi-word) — it never produced the reported one-character-per-line text. Reproducing the
exact path live (For You → recommended internship → View job) at **360dp + font scale 1.8** showed the real culprit: the
seeker **`_MatchSection` in `lib/features/jobs/presentation/job_detail_screen.dart`**. Each non-loading match-prompt
state (`!hasResume` / `idle` / `error`) was a single `Row` of `Icon + Expanded(message) + <action button>`. The action
buttons ("Analyze resume" / "See match" / "Retry") are **unconstrained** — at a large text scale on a narrow width the
button consumes most of the row and the `Expanded` message collapses to a sliver, so Flutter breaks it
**character-by-character** (`Se / e / ho / w / we / ll / yo / u`). Recommended jobs open this panel in the **no-resume**
state (widest button), which is exactly why the For You path surfaced it while a resume-analyzed Browse session did not.
**Fix:** a shared `prompt(icon, color, message, action)` helper renders the message row (icon + `Expanded` text, always
full width) with the **action stacked beneath it, end-aligned** (`Column` + `Align`). The `loading` state keeps its
`Row` (no button → the `Expanded` text already gets full width). The `_MatchResult` score row (`score% + band chip`)
became a `Wrap` so it can't `RenderFlex`-overflow at large scale either. **All job-detail entry points still share the
one `/jobs/:id` route**, so this fixes Browse / Internships / Coach deep-links identically. Regression guard:
`test/job_detail_screen_test.dart` gained a `textScale` host param + a test (EN + AR) at 360×800 / scale 1.8 asserting
the message keeps a wide layout (`msgRect.width > 180`) and the action sits **below** it.

**3 · Browse Jobs now defaults to Qatar independent of the persisted profile country.** On this emulator Browse already
scoped to Qatar (13 = Qatar + remote) — because its persisted `pref_selected_country` *was* Qatar. On the user's device
the persisted profile country is **not** Qatar (set during onboarding), and §7.26's Browse default read exactly that
persisted country (`countryControllerProvider?.name`), so Browse never opened on the Qatar market. **Fix:**
`jobs_browse_controller` (`_load` + `clearFilters`) now seeds the location filter to **`CountriesData.defaultCountry.name`
(Qatar)** directly, dropping the `country_controller` import. This is a deliberate product call — the app is Qatar-first
(QAR currency, Qatar seed jobs), so Browse opens on the Qatar market for everyone; users still change/clear it in the
filter sheet (`setCountry`), and remote roles are always included. The persisted country still drives phone/profile.
Guard: `jobs_browse_controller_test` gained "Browse defaults to Qatar even when the profile country is not Qatar" (Egypt
persisted → `query.location == 'Qatar'`).

**4 · Career Coach now anchors advice to Qatar.** §7.26 threaded `country` into the coach but only as a **soft system
hint** ("The user is based in … tailor … *when relevant*"), unlike Job Matching's firm user-prompt line — so replies
drifted to generic global advice. **Fix:** `career_coach_repository_impl._systemInstruction` now emits a **firm
directive** ("The job market is <country>. Base ALL job-market, salary, employer, and opportunity advice on <country>:
name <country> cities/employers, quote salaries in the local currency, reflect <country> hiring norms, default every
example and figure to <country> unless the user explicitly asks about another location"). `career_coach_controller` now
defaults the coach market to **`CountriesData.defaultCountry.name` (Qatar)** (consistent with Browse), dropping its
`country_controller` import. Verified live (EN): "In-demand tech jobs in **Qatar**", "Companies across **Doha**",
salaries "**8,000 QAR** and **18,000 QAR**", "employers in **Qatar**?". (AR): "…لبدء مسيرتك المهنية **في قطر**".

**1 · Google Sign-In — re-verified app-side correct, no code change.** Source audit reconfirmed the app uses Firebase
federated `signInWithProvider(GoogleAuthProvider())` (no `google_sign_in` plugin), `configurationError` maps the config
Firebase codes to the clear EN/AR message, and `docs/GOOGLE_SIGNIN_SETUP.md` documents the console steps. Root cause
remains **Firebase console config** — `android/app/google-services.json` still has `oauth_client: []` and no SHA-1
registered. This is **user-side** (enable Google provider → register debug + Play SHA-1/256 → refresh json → verify on a
real device); nothing in the app can complete the OAuth handshake without it. Not reproduced by signing out on-device to
avoid losing the live test session (no password to return) — the config gap is verifiable directly from the empty
`oauth_client`.

### VERIFIED live on emulator (`careerbridge_pixel`, seeker `appreg030157@cb.app`) — EN + AR
Reproduced the bug **before** the fix (match panel showing `Se / e / ho / w / we / ll / yo / u` at 360dp + font 1.8 via
For You → recommended internship), then confirmed fixed on the rebuilt app: message wraps by word full-width, "Analyze
resume" stacked below (EN); "اعرف مدى تطابقك — حلّل سيرتك الذاتية أولًا." + "تحليل السيرة" below (AR). Browse filter sheet
= **🇶🇦 Qatar / 13 results** (EN and AR). Coach → Doha/QAR/Qatar (EN) and "في قطر" (AR). Set/reset device font via
`adb shell settings put system font_scale` and width via `adb shell wm density 480` (→360dp) / `wm density reset`.

### Known limitation (out of reported scope)
At **font scale ≥ ~1.8 on a narrow device**, the Home "Your AI toolkit" feature grid (`home_screen.dart` `SliverGrid`,
`childAspectRatio: 1.42`) overflows its cells ("BOTTOM OVERFLOWED BY … PIXELS", worse in Arabic — longer labels). This
is **pre-existing** (not one of the four reported bugs) and only manifests at extreme accessibility font sizes; a future
pass could switch the grid to `mainAxisExtent` / a lower aspect ratio or let cards size intrinsically. Left untouched
here to keep the blast radius on the reported issues.

---

## 7.28 Final MVP Stabilization — Qatar Everywhere + Google Sign-In Diagnostics ✅ COMPLETE (feat `dbf47cb`)

> **Bug-fix / stabilization only — no new features.** MVP-finishing pass over five prioritized real-device reports.
> Reconciled each against the current code (much was already fixed in §7.26/§7.27), extended where incomplete, and
> **verified on the RELEASE APK EN + AR**. `analyze` clean · **596 tests** (+1) · release `.apk` (73.1 MB) under R8.

**1 · Google Sign-In — diagnostics added; the blocker stays a Firebase-console step.** `signInWithGoogle` was routed
through `_guard`, which only catches `FirebaseAuthException`; the federated `signInWithProvider` handshake commonly fails
on Android with a **`PlatformException`** (missing OAuth client / unregistered SHA-1) or a cancelled Custom Tab, which
`_guard` rethrew raw → opaque UI error, no diagnostics. Now `signInWithGoogle` has its own try/catch that (a) **logs the
exact `runtimeType` + code + message** to logcat (`[Auth] Google sign-in …`) so a real-device failure is diagnosable via
`adb logcat`, and (b) maps a non-Firebase failure through **`_classifyGoogleError`** (message contains cancel/dismiss →
`cancelled`; network/timeout/unreachable → `network`; otherwise → `configurationError`, carrying the raw message).
Re-verified the config blocker: `google-services.json` `client[0].oauth_client` has **0 entries** — the Google provider
still isn't enabled and no SHA-1 is registered, so no code change can complete sign-in. The console steps
(`docs/GOOGLE_SIGNIN_SETUP.md`) remain **user-side**. Not reproduced by signing out on-device (the emulator session is a
passwordless test account — signing out would strand it).

**2 · "Vertical text" (For You → recommended job → Job Details) — re-verified fixed on the RELEASE APK.** Root cause was
found + fixed in §7.27 (the seeker `_MatchSection` in `job_detail_screen.dart` paired `Expanded(message)` with an
unconstrained action button in a `Row`; the action now stacks beneath a full-width message). This pass **re-reproduced
the exact reported flow** (For You → open a recommended job → Job Details → scroll to the match panel) on the installed
**release** build at **`wm density 480` (~360dp) + `font_scale 1.8`**, in **EN** ("See how well you match — analyze your
resume first." wraps across 3 lines, "Analyze resume" below) and **AR** ("اعرف مدى تطابقك — حلّل سيرتك الذاتية أولًا." +
"تحليل السيرة" below). No character-per-character wrap. No code change needed here.

**3 · Qatar default everywhere — extended to Job Matching + Interview + on-demand match.** §7.27 defaulted **Browse** and
**Coach** to `CountriesData.defaultCountry` (Qatar), but **Job Matching** (`job_matching_controller._match`),
**Interview** (`interview_controller.buildContext` → `InterviewContext.country`), and the **job-detail on-demand "See
match"** (`job_detail_controller.computeMatch`) still read the persisted profile country (`countryControllerProvider`).
All three now use `CountriesData.defaultCountry.name`, so every AI market context is Qatar regardless of the persisted
profile country (the country provider still drives phone/profile only). Live on the release APK: **Browse = 13 jobs
(Qatar + remote) in EN and AR**. Note: the Dubai/UAE and Cairo/Egypt cards a tester may read as "other countries" are
**remote** roles (globe icon, not a location pin) — the Qatar filter deliberately always includes remote. If a
Qatar-only (exclude foreign-remote) list is ever wanted, that's a `SeedJobsRepository` filter change, not a default
change. Guard added: `test/interview_controller_test.dart` — "interview context defaults the market to Qatar even with a
non-Qatar persisted profile country" (persists Egypt, asserts `context.country == 'Qatar'`).

**4 · Arabic — both parts already correct; reconfirmed.** (a) **Job descriptions in Arabic:** `Job.descriptionFor(lang)`
+ `titleFor`/`locationFor` with English fallback; all 18 seed jobs carry `descriptionAr` (§7.26). Reconfirmed on the
release APK: the recommended UX-intern detail shows the Arabic description "ادعم فريق تصميم المنتج…". (b) **PDF
"SQL→LQS":** verified **already fixed**, not just assumed. A throwaway probe built the ATS PDF for an Arabic doc
(`rtl:true`) containing mixed strings ("…خبرة واسعة في SQL و Python…", skills `["SQL","Python","تطوير الويب"]`, a bullet
"…backend … Node.js و PostgreSQL") and `pdftotext` extraction showed **`SQL`, `Python`, `Flutter`, `PostgreSQL`,
`Node.js` all with correct letter order** (Latin words keep L→R; only the RTL word *sequence* flips, which is correct
bidi). Mechanism: `pdf` resolves to **3.13.0** whose `pw.Text` defaults `useBidi=true` and runs `bidi.logicalToVisual`
on RTL strings, so the §7.26 per-string `_txt(textDirection)` approach already yields correct mixed-script output. No
change needed.

### VERIFIED live on emulator (`careerbridge_pixel`, seeker `appreg030157@cb.app`) — RELEASE APK, EN + AR
Installed `app-release.apk`, drove **For You → recommended job → Job Details** at 360dp + font 1.8 (EN + AR) — match
prompt wraps normally, action stacked. **Browse = 13 jobs (Qatar + remote)** EN + AR; recommended-job detail shows the
Arabic description + English skill chips (UI Design/Figma) correctly LTR. Screenshot workflow note: after `wm density
480`, some `screencap` frames come back full-res and were rejected by the image API at 1080×2400 — **downscale with
Pillow** (`im.thumbnail((520,1160))`) before reading. Reset with `wm density reset` + `font_scale 1.0`.

### Not directly observable (covered by code + tests)
Job-Matching / Interview / Coach country context is a soft AI-prompt preference (not a visible filter), so it's covered
by the const default + the interview unit guard + the §7.27 live Coach check (Doha / QAR / "في قطر"). Google Sign-In
diagnostics are logcat-only until the console config is done.

---

## 7.29 Email-Only Auth + Email Verification ✅ COMPLETE (feat `356a290`)

> A deliberate **MVP scope cut** (deadline-driven): remove Google Sign-In entirely and gate the app behind email
> verification. Email/password is the only method. `analyze` clean · **602 tests** (+6) · release `.apk` (73.1 MB) under
> R8 · **live-verified on the release APK**.

**Google Sign-In fully removed.** Deleted: `signInWithGoogle` (interface + `FirebaseAuthRepository` impl +
`_classifyGoogleError` + fake), the Welcome Google button + `_google()` handler + `_OrDivider`, the whole
`widgets/auth_method_button.dart` (`AuthMethodButton` + `GoogleGlyph`, welcome-only), `AuthMethod.google` (enum now
`{email, phone}`; `profile_screen` label switch updated), and the `continueWithGoogle` / `authOr` l10n keys (EN + AR,
regenerated). `errConfiguration` was **kept** (the `configurationError` code is still mapped for generic backend
misconfig) but **reworded provider-neutral** ("This sign-in method isn't available right now. Please use email
sign-in."). The Welcome screen is now a `StatelessWidget` (no ref/state) with a single "Continue with Email". No
`google_sign_in` package existed to remove (the app had used federated `signInWithProvider`), so nothing changed in
`pubspec.yaml`.

**Email verification gate (new).** `AppUser` gained **`emailVerified`** (mapped from Firebase `user.emailVerified`,
in `toJson`/`fromJson`/`props`). `AuthRepository` gained **`sendEmailVerification()`** and **`reloadEmailVerified()`**
(`reload()` then re-read, since `emailVerified` only refreshes on reload/re-sign-in); **`registerWithEmail` now calls
`sendEmailVerification()`** on success (the "auto-send on sign-up" requirement). New **`EmailVerificationScreen`**
(`/auth/verify-email`, route name `verifyEmail`): mark-email icon, title, body naming the address, **"I've verified —
Continue"** (`reloadEmailVerified` → verified? `maybeOfferBiometricEnrollment` + `goAfterAuth` : "not yet" snackbar),
**"Resend verification email"** (`sendEmailVerification` + confirmation snackbar + **30s cooldown** via a `Timer.periodic`
that's cancelled in `dispose`), and **"Use a different account"** (`signOut` → Welcome).

**Gating (three points, imperative — the router has no `redirect`).** (1) `email_auth_screen._submit`: sign-up →
`goNamed(verifyEmail)`; sign-in → if `!user.emailVerified` → `goNamed(verifyEmail)`, else the usual biometric +
`goAfterAuth`. (2) `splash_screen._bootstrap`: after `user != null`, `if (!user.emailVerified) → verifyEmail` (before
the biometric gate) — so a persisted unverified session can't enter. The user stays signed-in-but-gated (needed so the
verify screen can call `sendEmailVerification` / `reload`).

**Tests (+6).** `test/email_verification_test.dart` (4): Welcome offers email only / no "Google"; verify screen shows
the email + 3 actions; "Continue" while unverified shows the not-yet message; "Resend" calls `sendEmailVerification`
(fake counter) + shows the sent snackbar. `render_all_locales` gained **EmailVerify** (EN + AR overflow sweep). Fake
auth: dropped `signInWithGoogle`, added `sendEmailVerification` (counter) + `reloadEmailVerified` (returns the user's
`emailVerified`), `_fakeUser.emailVerified = true` so existing sign-in tests still reach home. **flutter_animate
timer gotcha:** tap-based tests on animated screens must `pump(Duration)` (not bare `pump()`) so the one-shot entrance
timers fire, and must flush the snackbar timer / dispose to avoid "pending timer" — never `pumpAndSettle` (the resend
cooldown is periodic).

### VERIFIED live on emulator (`careerbridge_pixel`) — RELEASE APK
The pre-existing unverified session (`appreg030157@cb.app`, created before verification existed) **auto-gated to the
verify screen** on launch (splash gate ✓). Tapped **Resend** → "Verification email sent." snackbar + button → "Resend in
30s" ✓. Tapped **"I've verified"** while still unverified → stayed on the gate (no home access) ✓. **"Use a different
account"** → signed out → **Welcome with only "Continue with Email"** (no Google button / divider) ✓. **Registered a
fresh `verifytest01@cb.app`** → auto-sent verification email → routed to the verify screen naming that address ✓. Not
machine-verifiable: the actual inbox-link click (no real mailbox for `@cb.app`); the verified→home path runs
`reloadEmailVerified()` + `goAfterAuth` and is exercised by the fake in tests.

---

## 7.30 CV Templates — Modern / Minimal / Harvard ✅ COMPLETE (feat `af70cc9`)

> The last open MVP *feature*: the three catalogued-but-unimplemented CV templates. Purely additive as designed
> (a `PdfTemplate` subclass + a registry entry each) — **plus three real bidi/layout bugs found while verifying,
> which also affected the shipped ATS template.**

### What shipped

**Shared `data/templates/pdf_text.dart` (`PdfText`).** The bidi-safe primitives were private statics inside
`AtsTemplate`; three more templates needed them, so they moved to one shared class (`hasArabic`, `txt`, `cleanUrl`,
`period`, `titleLine`). ATS now delegates to it. The move itself was proven output-neutral: the ATS PDF was generated
before and after and was **byte-identical apart from the random per-run `/ID`** (EN + AR).

**Three `PdfTemplate` subclasses**, same `build(CvData, labels:, fonts:, rtl:)` contract, same models, no new deps:

| Template | Layout |
|---|---|
| `ModernTemplate` | Emerald header band + side column (contact/links/skill chips) beside the main flow. Uses **`pw.Partitions`, not `pw.Row`** — Partitions is a *spanning* widget, so a long CV flows to page 2 instead of overflowing (a `Row` cannot split). Partition order reverses under RTL. |
| `MinimalTemplate` | Monochrome single column, wide margins, no rules/fills, letter-spaced headings. |
| `HarvardTemplate` | Centred header, full-width ruled headings, **Education first**, dates on the far edge. |

**Registry + picker.** `kCvTemplates` in `pdf_cv_generator.dart` maps all four ids → templates. `CvTemplateMeta.available`
was **deleted** along with the "Coming soon" badge and `Opacity` dimming in `cv_template_picker.dart` — every catalogued
template is implemented and selectable. (`comingSoonBadge` l10n stays: Home/Employer Home still use it.) The generator
keeps its `templateUnavailable` throw as a defensive guard for an unregistered id.
`CvLabels` gained **`contact`** (→ existing `cvContactSection`; no new l10n keys — all eight `cvTemplate*` keys already
existed EN+AR). `links` was declared-but-unused before; Modern now uses both.

**Preview freshness.** `PdfPreview` only re-rasters when its `build` callback is a *different object*, which for a
closure is incidental. `cv_preview_screen` now keys it on `ValueKey(Object.hash(templateId, data, lang))` so a template
switch — or any edit, or a language change — deterministically regenerates. Export already routes through the same
`state.templateId`, so it follows.

### 🐞 Three pre-existing bugs found by rendering (all also hit the shipped ATS template)

**These changed ATS's PDF output.** "Keep ATS unchanged" was read as *don't redesign/regress it*, not *preserve a bug* —
the same milestone required mixed text to render correctly, and the fixes live in the shared helper.

1. **Latin reversed inside Arabic text.** `pdf` gives two directions and neither renders a mixed line: `ltr` leaves
   Arabic unshaped; `rtl` reverses each lettered word's characters and places words right-to-left (right for Arabic,
   wrong for Latin). So an Arabic CV printed "Flutter" as **"rettulF"**, "SQL" as "LQS", and the phrase "Northwind Apps"
   as "Apps Northwind". Fix: `PdfText._preReverseLtrRuns` reverses each LTR run's word order *and* each word's
   characters, cancelling both passes exactly. Runs with **no Latin letter (a phone, a year) are left alone** — `pdf`
   resolves numbers correctly itself, and compensating them broke the phone into "479 0005 0000".
2. **`forceLtr` broke the Arabic city.** The contact-line `forceLtr: true` (from §7.26) kept the email readable by
   rendering the whole line LTR — which left an Arabic city as "رطق ،ةحودلا". With fix 1 the parameter is unnecessary and
   was **removed**: direction now always follows the text, and both the email and the city render correctly.
3. **`cleanUrl`'s zero-width spaces printed as boxes.** The U+200B after each slash was doubly wrong: `pdf` breaks lines
   on `\s`, which **excludes** U+200B (so it added no break), and neither bundled font has a glyph for it, so each
   printed as a visible `.notdef` box — "sarah.dev/▯portfolio" on every CV with a URL. Removed; scheme-stripping plus
   one-link-per-line is what actually prevents overflow.

Two more, found in the new templates before they shipped: **`fontStyle: italic` is unusable** (the theme carries only a
regular + bold Arabic face, so italic falls back to a Latin oblique that cannot shape Arabic *and* bypasses the RTL text
path) — Minimal/Harvard use weight+colour instead; and a **Column with no full-width child shrink-wraps**, so
`crossAxisAlignment` aligned within that narrow box rather than the page (ATS only avoids this incidentally, via its
full-width rule `Container`). Minimal/Harvard add a zero-height `SizedBox(width: double.infinity)` — kept as a *child*
rather than a wrapping Container so the Column stays spanning and can still break across pages.

> ### ⚠️ Verify bidi changes by RENDERING, not by extracting text
> An RTL PDF's text layer is stored in **visual order**, so `pdftotext` reports Latin reversed whether or not it
> actually is — it misleads in both directions. §7.28 concluded "SQL→LQS is already fixed" from a `pdftotext` probe of
> **Latin-only** strings; the real bug was Latin embedded *inside* Arabic, and it was still there. Rasterise instead
> (`pip install pypdfium2`; `PdfDocument(f)[0].render(scale=2).to_pil()`), and note that **reading RTL off a render is
> itself ambiguous** — embed ASCII digit markers ("1 …2 …3") to make word order objectively checkable.

### Tests (+29 → **631**)

`cv_pdf_generator_test` now loops **every** `cvTemplateCatalog` entry × EN/AR × {normal, empty, multi-page} (the
multi-page case guards Modern's Partitions spanning), asserts every catalogued id has a registered template and that the
catalog covers the whole enum, that distinct ids produce distinct documents, and that an unregistered id still throws
(via an injected empty registry — the old test asserted `modern` throws, which is now wrong). New `pdf_text_test` covers
`hasArabic` / direction / pre-reversal / no-ZWSP / `period` / `titleLine`.

### VERIFIED live on emulator (`careerbridge_pixel`, debug build), EN + AR

Reached via `flutter run --route=/cv-builder` — the persisted session (`verifytest01@cb.app`) is **gated at the splash by
the §7.29 email-verification check** (`@cb.app` has no inbox), but the gate is in the splash bootstrap, so a deep link
enters the builder with the session and profile intact. **EN:** picker shows all four at full opacity, **no "Coming soon"
badge**; ATS→Modern→Minimal→Harvard each selected (check moves) and each **previewed as its own distinct layout**;
export opened the share sheet with `Sarah_Ahmed_CV.pdf` (not sent). **AR:** picker RTL (القالب; cards right-to-left; no
قريبًا); **Modern** preview mirrored — **side column on the right**, Arabic labels (معلومات الاتصال / الروابط), and Latin
(`Sarah Ahmed`, `verifytest01@cb.app`, `github.com/sarah`) **not reversed**; **Harvard** header correctly centred.
Arabic *glyph* content could not be typed live (`adb shell input text` is ASCII-only) — it was instead verified by
rasterising the real generator's output with real Noto fonts for all four templates (Arabic + mixed Arabic/Latin:
Flutter/Dart/SQL/PostgreSQL/Node.js/Riverpod, email, URLs, "Northwind Apps" — all correct).

**Known cosmetic remainder:** in an Arabic document a phone's leading `+` sits on the wrong side of the digits
(`974 5000 0000 +`). It is inside an untouched number run — `pdf`'s own neutral-character resolution — and the digits and
their group order are correct. Not worth compensating; revisit only if a user reports it.

---

## 7.31 Rebrand: Career Bridge → **Wazifly** ✅ COMPLETE (branch `feature/wazifly-rebrand`)

> Phase 1 of the rebrand: **branding, design system, assets, naming, and user-facing identity only** — zero business
> logic / backend change. The Wazifly brand board is the source of truth. Approved decisions baked in:
> **display-name-only** (package IDs / Firebase untouched), **Inter kept** (no Poppins), **SVG-authored logo**,
> **HANDOFF history preserved**.

**Colors (`app_colors.dart`).** New Wazifly palette — Deep Navy `#0B1D3A` (anchor), Royal Blue `#1677FF`
(interactive/CTA primary), Sky Blue `#00C2FF` (accent), Teal `#00B59C` (support/success), Mist Gray `#E6EBF1`. Applied
**minimal-churn**: canonical names added, and the legacy `emerald*`/`mint`/`deepSea` accessors kept as **aliases** onto
the new palette so the ~130 call sites are untouched. Neutrals retinted cool/navy; CTA gradient sky→royal→deep-royal;
`success = teal`. `app_theme.dart` seeds from `royalBlue` (+ `tertiary = skyBlue`). 3 hardcoded CV-PDF template hex →
Royal Blue. **white-on-Royal-Blue button contrast ≈ 3.4:1 — acceptable for large/bold button text (WCAG UI 3:1) and
brand-faithful; verified legible on device.**

**Logo (SVG single source of truth).** Authored **`assets/brand/wazifly_logo.svg`** — the "W" whose right arm rises into a
royal→sky "takeoff" swoosh (white on navy), matching the board. **`tool/generate_brand_assets.py`** regenerates every
raster **from that SVG** (svglib → ReportLab → PDF → pypdfium2 → Pillow composite; no native cairo). Outputs:
`assets/images/wazifly_mark.png` (in-app), `assets/icon/{splash_logo,ic_foreground,ic_background,app_icon}.png`. Replacing
the SVG with the official vector = rerun the script + `flutter_launcher_icons` + `flutter_native_splash`. In-app `AppLogo`
now renders the mark on a navy tile; the splash `_GlowLogo` swapped `Icons.hub_rounded` → the mark (the old glyph is fully
gone). Launcher icons + native splash regenerated (splash bg `#0B1D3A`).

**Naming / strings.** `AppConstants.appName`, `build_info`, `MaterialApp.title`, class `CareerBridgeApp`→**`WaziflyApp`**,
`pubspec` description, the Career-Coach **system prompt** ("Wazifly's AI Career Coach"), and l10n **EN + AR** (`appName`,
`welcomeTitle`, `userTypeTitle`, `sourceCareerBridge` **value**, `biometricReasonUnlock`). Decision: the **Latin wordmark
"Wazifly" is kept even in Arabic** (brand wordmarks aren't translated; consistent with how "ATS" stays Latin). Native
display names → Wazifly (Android `android:label`, iOS `CFBundleDisplayName`/`Name`, web `<title>`/manifest).

**Intentionally NOT changed** (technical identifiers / data — changing them is backend, out of scope): Android
`applicationId` + iOS bundle id **`com.careerbridge.careerbridge`**; Dart package **`careerbridge`** (all
`package:careerbridge/…` imports); Firebase project `careerbridge-97-f58c9` + `google-services.json` +
`firebase_options.dart`; the **persisted `ApplicationSource.careerBridge` enum value** (only its *label* is now "Wazifly");
the `sourceCareerBridge` l10n **key name** (its value is "Wazifly"). Docs: README + `docs/**` rebranded (technical IDs
preserved); this HANDOFF keeps its historical "Career Bridge" entries by design.

**Tests +3 (653).** New `test/branding_test.dart` guards `AppConstants.appName == 'Wazifly'` and that no key EN/AR l10n
string still carries the old brand; `build_info_test` + `cv_pdf_generator` fixture updated. analyze clean; full suite
green; release APK (73.9 MB) under R8. **Live-verified on the device (Samsung A16):** OS launcher shows **"Wazifly"** + the
new navy-W icon; native splash navy+W; in-app splash shows the W mark + "Wazifly"; Home/Settings/toolkit/Coach/CV Builder
all render the Royal-Blue system in **light + dark**; **Arabic RTL** fully mirrored with the new theme (Cairo); Teal
correctly used for the "Trains beginners" support chip. Employer surfaces are covered by construction (the theme is 100%
global and no employer string is hardcoded — the l10n guard + no-literal scan cover them; functionally verified in the
prior QA session). Welcome/Login use the shared `AppLogo` (same mark as the splash, confirmed rendering) — not re-opened
live to avoid a logout + password round-trip.

**Remaining (Phase 2, deferred):** the official vector logo (drop-in replace the SVG), a proper Arabic transliteration if
ever desired, and — if the brand ever needs its own package/bundle identity — a package/`applicationId` rename, which is a
separate Firebase-re-registration effort.

---

## 7.32 Arabic brand localization + Release **v1.0.0** ✅ (commit `54b4b60`, tag `v1.0.0`)

**Arabic brand localization.** Inside **Arabic sentence/label text only**, the brand is now the localized **"وظيفة فلاي"**
instead of the Latin "Wazifly": `welcomeTitle`, `userTypeTitle`, `sourceCareerBridge` (value), `biometricReasonUnlock`.
The **visual wordmark / display name / logo stay the Latin "Wazifly"** — `appName` (the splash wordmark, only use of
`l10n.appName`) is unchanged, as are the Android `android:label`, iOS `CFBundle*`, and web `<title>`. English text
unchanged; no technical identifiers touched. `branding_test.dart` asserts the per-locale brand form (EN "Wazifly", AR
"وظيفة فلاي", no Latin wordmark left inline in Arabic sentences) while keeping `appName == 'Wazifly'`. Live-verified: the
Arabic Welcome screen shows **"مرحبًا بك في وظيفة فلاي"** with the W logo mark intact, no overflow.

**Release tag.** `git tag -a v1.0.0` on `54b4b60`. **Official submission APK** = a clean
(`flutter clean` → `pub get` → `assembleRelease`) build from the tagged commit:
`build/app/outputs/flutter-apk/app-release.apk` · **73.9 MB (77,476,477 bytes)** · versionName `1.0.0`, versionCode `1`
(pubspec `version: 1.0.0+1`). analyze clean; 653 tests. The tag is **local — not pushed** to any remote yet.

> Employer live-flow check was **not** done for this last i18n commit (it needs a sign-in + role switch; the session was
> logged out to show the Arabic Welcome screen). It is text-only and covered by the `render_all_locales` AR tests + the
> fact that none of the four changed strings render on an employer screen with an empty dataset (`sourceCareerBridge` only
> shows on a real applicant). Re-confirm live if desired before store submission.

---

## 7.34 ✅ Resume Analyzer OCR fallback (scanned PDFs) + language-onboarding verification

**Issue 1 — scanned PDFs now supported (FIXED, feature added).** Previously a scanned/image-only CV (Adobe Scan,
CamScanner, Microsoft Lens, a photographed page) had no text layer, so `SyncfusionPdfTextExtractor` returned nothing and
the analyzer showed "We couldn't read any text…". New behavior: text extraction is tried first; if it yields `< _minChars`,
the repository falls back to **OCR**, and the analysis continues on the OCR'd text. If OCR is unavailable or also comes up
empty, the usual `noText` error shows (message updated — it no longer tells users to "upload a text-based PDF").
- **Seam:** `domain/resume_ocr.dart` (`ResumeOcr` interface) + `data/gemini_pdf_ocr.dart` (`GeminiPdfOcr`). Kept
  **feature-local** on purpose — extending the shared `AiService` would have broken its 7 test fakes + Noop.
- **Impl:** `printing` (already a dep) rasterizes pages to PNG on-device (PDFium), then a **single multimodal Gemini
  request** (`firebase_ai` `Content.multi([TextPart, InlineDataPart…])`, model `gemini-2.5-flash`) transcribes them
  verbatim. No new native OCR plugin/model — reuses the Firebase AI backend the analyzer already requires (lower risk given
  the AGP/KGP native-plugin deferrals). Caps: 8 pages, 200 DPI. AI errors are mapped to the shared `AiException` taxonomy so
  network/quota/not-configured surface precisely; rasterization failure → empty → `noText`.
- **Wiring:** `resumeAnalyzerRepositoryProvider` now passes `ocr: GeminiPdfOcr()`. Repo constructor takes an optional
  `ResumeOcr? ocr` (null ⇒ legacy behavior; used by unit tests).
- **LIVE-VERIFIED on emulator** against a generated **image-only** PDF (0 extractable chars): OCR recovered the text and the
  analysis returned field="Software / Computer Science…", **atsScore 99**, on-domain missing skills (~28 s, two Gemini
  calls). 5 new unit tests (fallback runs, doesn't run when text present, both-empty→noText, propagates OCR AiException).

**Issue 2 — "language selection screen disappeared" → NO code bug; behavior already correct (verified).** The reported
regression could not be reproduced: the splash already routes `if (!onboardingDone) goNamed(RouteNames.language)`,
`languages_data.dart` is unchanged since Phase 1 (EN + AR supported, 8 more "coming soon"), and Settings has a working
language picker. **On-device pump of the real app with fresh storage lands on `LanguageSelectionScreen` with English +
Arabic present.** The user's symptom is almost certainly persisted `onboardingCompleted=true` carried over when the new APK
was installed **over** a prior install (SharedPreferences survive an update), so language wasn't re-shown — which is by
design. To see it again: clear app data / fresh install, or Settings → Language. Added a non-flaky guard test
(`test/onboarding_controller_test.dart`) locking the invariant (fresh ⇒ onboarding false ⇒ language; `complete()` persists
true ⇒ not shown again). **No production behavior change was made for issue 2** (none was warranted).

**Validation:** `analyze` clean, **664 tests** (+7). l10n `resumeErrNoText` reworded (EN + AR). Both verified live on
emulator-5554 against Gemini via Firebase AI Logic.

---

## 7.36 ✅ Job Details — salary card + explicit work mode

**Reported:** the Job Details page didn't show salary. **Root cause:** the seeker `Job` model never carried a salary — it
was only on the employer `JobPosting`, and `JobPosting.toJob()` dropped it (seed jobs had no salary key either). So salary
had never rendered in the shared `JobDetailView`. Fix (additive, design-consistent):
- **Model:** extracted `SalaryRange` to its own file `shared/models/salary_range.dart` (job_posting.dart **re-exports** it, so
  existing `import 'job_posting.dart'` users — incl. tests — are unaffected; avoids a Job↔JobPosting circular import). Added
  `Job.salary` (`SalaryRange?`, parsed in `Job.fromJson`), and `JobPosting.toJob()` now carries `salary`.
- **Display:** new `shared/models/salary_range_l10n.dart` `.display(l10n, localeName:)` → e.g. "QAR 15,000 – 20,000 · per
  month", "From USD 90,000 · per year" (self-contained period labels, no employer-layer dep).
- **UI (`JobDetailView`):** added a prominent emerald-tinted **salary card** (payments icon + label + range, `Expanded`
  value to avoid the vertical-text trap) after the meta chips; made **work mode an explicit chip** (Remote / On-site) and
  simplified the location chip (dropped the "· Remote" suffix). The page now shows **Salary, Job Type (work mode),
  Experience Level, Description, Required Skills**. Shared by the employer preview too, so both stay in sync.
- **Seed data:** all 18 `assets/data/seed_jobs.json` jobs got realistic salaries (local currency + monthly for on-site
  regional roles, USD + yearly for remote, smaller intern stipends).
- l10n added `jobsSalary`, `jobsOnsite`, `salaryFrom`, `salaryUpTo` (EN + AR). **Note:** the job schema models work mode as a
  `remote` bool (Remote vs On-site) — there is no "Hybrid" state for regular jobs (only internships have a 3-way work mode);
  adding Hybrid would be an end-to-end model+editor+seed change, not done here.
- `analyze` clean, **677 tests** (+ salary parse/projection/display + JobDetailView salary/work-mode render tests).

---

## 7.37 ✅ FIXED — Role Selection skipped for new users (device-global role leak)

**Reported.** After signing up or signing in, a **new** user no longer saw the **Role Selection** screen — the app opened
the **Job Seeker** flow immediately and the **Employer** option never appeared.

**Root cause.** The post-auth routing decision read the role from the **device-global `SharedPreferences` cache**, never
from the **per-user Firestore profile**. `UserTypeController` seeds its state once from a single global key
(`StorageKeys.userType`), and `goAfterAuth` (plus the splash and `goToRoleHome`) trusted that cached value directly:
`final type = ref.read(userTypeControllerProvider); if (type == null) goNamed(userType) …`. Because the key is
**device-scoped, not user-scoped**, once *any* user on the device chose a role the key stayed set, so the **next** user
inherited it and was routed straight past Role Selection. Firestore already stored the role per-user
(`FirestoreUserProfileRepository.setUserType` → `users/{uid}.userType`, read back via `UserProfile.userType`), but
**nothing in the routing path consulted it** — the "check whether the user has a role in Firestore" step was never
performed. It surfaced now because multi-account testing on one device poisons the global key (sign-up and the
verify-email "Use another" sign-out don't clear it; only Settings → Logout calls `clear()`).

**Investigation findings.** Traced every routing entry point: `email_auth_screen._submit` → `goAfterAuth`,
`email_verification_screen._checkVerified` → `goAfterAuth`, `splash_screen._bootstrap` (inline role switch), and
`app_lock_screen._unlock` → `goToRoleHome`. All four resolved the role from the local `userTypeControllerProvider` only.
The Firestore seam (`fetchProfile` / `setUserType` / `UserProfile.userType`) and the in-memory fake already existed and
were correct — the gap was purely that routing never read them.

**Fix (architecture preserved — no new deps, no schema change).**
- **`auth_navigation.dart`** — new private `_resolveUserType(ref, {trustCache})` makes **Firestore the source of truth**:
  reads `users/{uid}.userType` via the existing `fetchProfile` seam and reconciles the local cache. `goAfterAuth`
  (fresh sign-in / account switch) calls it with **`trustCache: false`** → ignores the device-local cache, reads
  Firestore, and routes to **Role Selection whenever Firestore has no role** — a new user can never inherit a previous
  user's cached role. `goToRoleHome` (splash / biometric unlock of an existing session) uses **`trustCache: true`** → a
  non-null cache (reconciled for *this* user at last sign-in) is used directly for a fast, offline-safe path, falling back
  to Firestore when empty. Both helpers are now `async` and guard with `context.mounted`.
- **`user_type_controller.dart`** — new `sync(UserType?)` reconciles the device-local cache with the authoritative value
  (persists or clears it), so the splash fast-path and Settings display stay correct after an account switch.
- **`splash_screen.dart`** — the inline role switch was replaced by `await goToRoleHome(context, ref)` (same
  Firestore-aware resolution; unused `user_type` imports dropped, `auth_navigation` imported).
- **Call sites** — `email_auth_screen`, `email_verification_screen` (`await goAfterAuth`), `app_lock_screen`
  (`await goToRoleHome`). The selection flow (`UserTypeSelectionScreen._confirm`) was already correct (saves to Firestore
  via `setUserType` + seeds the employer company doc) and is unchanged.

Net behavior now matches the spec: authenticate → check Firestore for a role → none ⇒ Role Selection (Job Seeker **or**
Employer) → choice saved to Firestore → future logins route directly from the saved role.

**Verification.** `flutter analyze` clean; **679 tests** (+2). New `test/role_selection_routing_test.dart` drives the real
`goAfterAuth` through a minimal `GoRouter`: (1) the exact regression — new user + a stale `jobSeeker` device cache + no
Firestore role ⇒ lands on Role Selection and the stale cache is reconciled to null; (2) a returning user whose saved
Firestore role routes straight to the seeker home and rehydrates the local cache. Full suite green.

---

## 7.38 ✅ Employer polish — Company completion + Logo upload FIXED, Interview & Candidates AI tools shipped

Four employer-side items before final submission. `analyze` clean, **691 tests** (+12). All reuse the existing
architecture (Riverpod seams, the shared `AiService`, `StatusView`, l10n EN+AR, `go_router`) — no new dependencies, no
existing behavior changed.

**P1 — Company Profile completion stuck at 13% (FIXED).** Root cause was **not** the app: completion is derived live
from `Company.missingFields` and both the dashboard (`companyCompletionProvider`) and profile screen watch the live
`companyProvider` stream, so the reactive/derive chain was already correct (proven by a new provider-chain test). 13% =
exactly 1/8 fields (only the `contactEmail` auth-email fallback) → the saved company was **reading back empty**. The
`companies` **Firestore rule** was the outlier: it used a *combined* `allow write` with `unchanged('ownerUid')`, whereas
every other collection splits create/update. On a **create**, `resource` is null, so `unchanged('ownerUid')` errors and
the write is **denied** — so `ensureCompany` never created the doc and every Save was a denied create (offline
optimistic write rolls back → completion reverts to 13%). Fix: split the `companies` rule into `allow create` (pins
`ownerUid == companyId`) + `allow update` (keeps `unchanged('ownerUid')`), mirroring jobs/applications/resumes. **Requires
`firebase deploy --only firestore:rules` to take effect on device.** Also hardened the app so a silent failure can't
masquerade as success: `FirestoreCompanyRepository.saveCompany` now lets genuine write errors propagate (keeps the
`!_ready` graceful no-op) → the editor shows a real error instead of a false "Saved".

**P2 — Company logo upload always failed (FIXED).** Root cause: uploads went to **Firebase Storage**, whose bucket is
unprovisioned (and `storage.rules` undeployed) — `putData` failed, `upload()` returned null → "upload failed" every time.
Both are external, paid/manual steps. Fix (self-contained, works on the free tier): a new **`DataUriCompanyLogoStorage`**
(the default `companyLogoStorageProvider` binding) downscales the image (`ImageOptimizer`, 256 px cap) and stores it as a
base64 `data:` URI **directly on the Firestore company doc** via the existing `setLogoUrl` seam — no bucket needed. A ~700
KB guard keeps it under Firestore's 1 MB doc limit. `AppImage.provider` now renders `data:` URIs via `MemoryImage` (still
`ResizeImage`-wrapped) alongside `http(s)` `NetworkImage`. The Cloud-Storage-backed `FirebaseCompanyLogoStorage` is kept
for when a bucket is later provisioned (rebind one provider). Controller/UI/removeLogo flow unchanged.

**P3 — Interview AI tool (was "Coming Soon" → functional MVP).** New employer tool at `/employer/interview`
(`features/employer/{domain/interview_kit.dart, data/interview_kit_repository_impl.dart,
application/interview_kit_controller.dart, presentation/employer_interview_screen.dart}`). Enter a role (+ optional focus)
→ one `AiService.generateJson` call returns an **interview kit**: role-specific questions each with a **model/suggested
answer** + focus chip, an overall **readiness score** (0–100 brand-gradient badge), **what to look for** (strengths) and
**areas to probe** (improvements). `StatusView` for loading/empty/error; failures mapped from `AiException`.

**P4 — Candidates AI tool (was "Coming Soon" → functional MVP).** New employer tool at `/employer/candidates`
(`features/employer/{domain/candidate_match.dart, data/candidate_match_repository_impl.dart,
application/candidate_match_controller.dart, presentation/employer_candidates_screen.dart}`). A new
`employerCandidatePoolProvider` flattens/dedupes the employer's applicant pool (`ApplicantSnapshot`s on applications) into
primitive `CandidateProfile`s; enter a target role → the AI **ranks** them and returns **top candidates** with a **match
score** (reuses `MatchScoreBadge`), **matching skills**, an **experience summary**, and an **AI recommendation**. Grounded
strictly in the real pool (never invents people). Honest empty state when no one has applied yet.

**Wiring & tests.** The two employer-home tool cards lost their `route: null` "Soon" badge and now navigate to the new
routes (`RouteNames.employerInterview` / `employerCandidates`); routes registered under `employerHome`. l10n EN + AR added
for both tools (incl. an Arabic plural for the pool count) and regenerated. New tests: company completion recalculates
through the provider chain after save; `DataUriCompanyLogoStorage` embeds/round-trips a data URI + persists via the
controller; interview-kit + candidate-match repositories parse/stamp/empty-throw; controllers map AI failures; the
candidate-pool provider dedupes. `analyze` clean, full suite **691** green. **Deploy note: P1 needs the updated
`firestore.rules` deployed; P2/P3/P4 need no console changes.**

---

## 7.35 ✅ Settings → "Restart onboarding" (replaces "View intro again")

New Settings item (Preferences section, `Icons.restart_alt_rounded`). The older lighter **"View intro again"** tile was
**removed**, and with it the now-dead replay plumbing it was the sole caller of: `OnboardingScreen.replay`/`replayParam` +
the `_finish()` replay branch, the router's onboarding query-param handling (now `_fade(const OnboardingScreen())`), and the
`settingsReplayOnboarding(+Subtitle)` l10n keys (EN + AR). Tap → confirmation dialog → on confirm it calls
**`OnboardingController.reset()`** (new; sets state false + persists
`onboardingCompleted=false`) and `context.goNamed(RouteNames.splash)`. The splash then re-runs its normal first-launch
routing: **language → country → onboarding → welcome**. **Only the onboarding flag is cleared** — account/session, profile,
jobs, CVs, language, country, and every other pref are untouched (verified by test). Handler:
`SettingsScreen._confirmRestartOnboarding`. l10n added EN + AR (`settingsRestartOnboarding`(+Subtitle),
`restartOnboardingConfirmTitle`/`Body`, `restart`). **Pure Flutter (SharedPreferences + go_router + Material dialog), no
platform code — identical on Android and iOS** (Android verified via tests; no iOS runner on this Windows box). Tests:
2 controller tests (reset clears flag; reset touches only onboarding) + 2 widget tests driving the real
tap→confirm/cancel→reset→Splash flow. `analyze` clean, **668 tests** (+4).

---

## 7.33 ✅ FIXED — Resume Analyzer misclassification / harsh scoring

**Resolution (this session).** Root-caused with the reporter's real CS CV and fixed at two layers:

1. **Extraction (`data/syncfusion_pdf_text_extractor.dart`).** The default `extractText()` shattered the PDF into
   *one-token-per-line soup* and split words/numbers (`2025`→`202`/`5`, `The`→`T`/`he`, `high-pressure`→`high`/`-`/`pressure`).
   The CS signal survived but the document *structure* the model weights was destroyed, and split date tokens (`202` + `5`)
   are exactly what produced the hallucinated "invalid date" flags. Fix: switch to **`extractText(layoutText: true)`** (the
   library's own layout engine → clean, correctly-spaced, human-readable lines with intact dates), with a plain-mode
   fallback if layout collapses, plus a light blank-line `_normalize`. Verified before/after on the real CV.
2. **Prompt (`data/resume_analyzer_repository_impl.dart` `_buildPrompt` + `_systemInstruction`).** The old prompt never
   asked the model to identify the field, had no rubric, left `missingSkills` unconstrained, and never mentioned dates — so
   on a CV heavy in *leadership/volunteer/social* wording (Volunteer Coordinator, Ministry of Social Development, "customer
   channels", Sociology Research, Structural Functionalism) an unanchored fast model drifted to a generic "business
   professional" reading and volunteered stock SAP/ERP/accounting "missing skills". New prompt: **STEP 1 detect
   `careerField` first** (weighting title/major/skills/projects over generic soft-skill wording), **STEP 2 evaluate only
   within that field** and never recommend unrelated-domain skills, an **explicit 0–100 weighted rubric with bands**, and
   **date-validation rules grounded on today's date** (treat well-formed/ordered dates as valid; only flag genuinely
   impossible ones). `careerField` is added to the JSON + `ResumeAnalysis` (optional, backward-compatible) and surfaced as a
   chip on the results screen (`resumeDetectedField` l10n, EN+AR).

Also added a **career-stage calibration** clause to the rubric (judge a student/entry-level CV against strong peers at
*their* level; don't penalize them for lacking senior-scale quantified impact) — the first live run scored the CS CV 68
(harsh) because the rubric applied senior expectations to a student; after calibration it lands 74–83.

**Compatibility & tests.** JSON keys unchanged except the additive `careerField` (old payloads still parse; `isEmpty`
unaffected). 657 tests (+4: careerField parsing, prompt-contract, careerField flow-through), analyze clean.

**LIVE-VERIFIED on emulator-5554 (Gemini via Firebase AI Logic on-device).** Ran the real pipeline (real extractor + new
prompt + real `FirebaseAiService`) against the reporter's CS CV via a temporary `integration_test` (since removed —
the Android key is Firebase-scoped, `API_KEY_SERVICE_BLOCKED` on the raw Generative Language API, so the model is only
reachable in-app + App Check). Across runs: **field = "Cybersecurity & Networking (Student)"** (never Business),
**missingSkills all on-domain** (Linux, Wireshark, Nmap, SIEM, scripting, pentesting — zero accounting/SAP/ERP),
**no hallucinated date errors** (grammar flags were real: university-name inconsistency, `LANGUAGES_` underscore),
**atsScore 74–83** (was 68 pre-calibration). App Check activated fine (enforcement off). Note: init via
`FirebaseService.initialize()` (FCM/Firestore) stalled the harness — initialize `Firebase` core directly for a fast
analyzer-only live check. **Bug fully fixed & confirmed end-to-end.**

---

## 7.33-orig ⚠️ ORIGINAL BUG REPORT (kept for context) — Resume Analyzer misclassification / harsh scoring

**Symptom (reported, not yet reproduced in a debugger this session).** The AI Resume Analyzer, on at least some
**Computer-Science** CVs: (a) **misclassifies the field as Business Administration**; (b) **recommends accounting/ERP
skills** (SAP, ERP, …) that are irrelevant to the candidate; (c) **flags valid dates as invalid**; (d) returns an
**unrealistically low `atsScore`**. This is the top open functional bug for the next session.

**Exactly how the analyzer works (so you can debug fast).** All in `lib/features/resume_analyzer/` +
`lib/core/services/ai/`:

1. **PDF → text:** `data/syncfusion_pdf_text_extractor.dart` → `syncfusion_flutter_pdf`'s
   `PdfTextExtractor(document).extractText()` (pure-Dart, on-device). **No layout/column handling.**
2. **Repository** `data/resume_analyzer_repository_impl.dart`: rejects `<40` chars (`ResumeErrorCode.noText`), clips to
   **20 000 chars**, then calls `AiService.generateJson(prompt, systemInstruction)`, then
   `ResumeAnalysis.fromJson` (defensive parse; empty → `AiException.invalidResponse`).
3. **AI provider:** `lib/core/services/ai/firebase_ai_service.dart` — **Firebase AI Logic**, `FirebaseAI.googleAI()`
   (Gemini Developer API backend), model **`gemini-2.5-flash`**, `responseMimeType: application/json`. **No API key in the
   client** — auth is via the Firebase app. (Swap to Vertex = `FirebaseAI.vertexAI()`; swap model = `modelName` /
   `FirebaseAiService.defaultModel`.) Same service powers Career Coach + CV enhance + Job Matching.
4. **Model** `domain/resume_analysis.dart`: `{ atsScore(0–100, clamped), summary, strengths[], weaknesses[],
   missingSkills[], grammarIssues[{issue,suggestion}], improvementSuggestions[] }`.

**The prompt is almost certainly a big part of the cause** (`resume_analyzer_repository_impl.dart` `_buildPrompt` +
`_systemInstruction`): it **never asks the model to identify the candidate's field / target role**, **does not constrain
`missingSkills` to the candidate's actual domain**, has **no scoring rubric** (so `atsScore` is uncalibrated → harsh),
and **never mentions dates** — so "valid dates flagged invalid" is the model volunteering hallucinated date criticism
(surfacing under `weaknesses`/`grammarIssues`). Fix candidates, cheapest first: (i) **improve the prompt** — make it infer
and state the field first, tie `missingSkills` to that field, add an explicit 0–100 rubric, and add "dates are often
`MMM YYYY` / `YYYY`; do NOT flag a plausibly-formatted date as invalid"; (ii) **verify the extracted text** before blaming
the model — **two-column CS résumés are a strong suspect**: syncfusion `extractText()` can interleave columns and scramble
reading order, so the model sees garbled text peppered with sidebar keywords and misreads the field. Log/inspect the raw
extracted string for a failing CV FIRST. (iii) Consider **`gemini-2.5-pro`** for the analysis call if prompt fixes are
insufficient (flash is fast but weaker at nuanced classification).

**Related, already-documented limitation (may compound this):** Arabic/mixed PDFs generated by the app's own CV builder
have a degraded text layer (Arabic doesn't extract; Latin runs get gaps) — see §7.30 / `PdfText`. That is the *app's PDF
output*; the analyzer's problem is *input extraction* of arbitrary user PDFs via syncfusion, a different code path, but the
"machine-readability of CV PDFs" theme is shared.

**No test reproduces this yet.** Add one: feed a known CS résumé's extracted text (or a fixture PDF) through the pipeline
with a faked `AiService` for the parse path, and — for the real classification — a manual/live check. `test/` has
`resume_analyzer_repository_test.dart` + `resume_analysis_test.dart` for the seams.

---

## 8. Next steps

> ### ⭐ CURRENT MVP STATUS — read this first (the rest of §8 below is historical)
>
> **Branch `feature/wazifly-rebrand` · submission commit `54b4b60` = tag `v1.0.0` (local, not pushed; a HANDOFF docs commit
> may sit on top) · `analyze` clean · 653 tests · official submission APK
> `build/app/outputs/flutter-apk/app-release.apk` (73.9 MB / 77,476,477 bytes, versionName 1.0.0 / code 1).** The app is fully rebranded **Wazifly** (§7.31) with the brand localized to **"وظيفة فلاي"** inside Arabic
> sentences while the wordmark/logo stay Latin "Wazifly" (§7.32); device-validated EN+AR, light+dark. Prior MVP
> feature/QA work landed on `feature/resume-analyzer` (through §7.30, `9d15dc5`); this branch continues from it. Technical
> identifiers stay `careerbridge` / `com.careerbridge.careerbridge` by design (display-name-only rebrand — see §7.31).
> Working tree clean except the local `.claude/settings.local.json` (never committed).
>
> **⚠️ Top OPEN bug for the next session: Resume Analyzer misclassifies CS CVs as Business Administration, recommends
> accounting/ERP skills, flags valid dates as invalid, and scores too low — full implementation map + fix hypotheses in
> §7.33.** AI = **Firebase AI Logic, Gemini `gemini-2.5-flash`, JSON mode** (no client API key), shared by Resume
> Analyzer / Career Coach / CV enhance / Job Matching (`lib/core/services/ai/firebase_ai_service.dart`).
>
> Everything through **§7.30 (CV Templates)** is complete and committed. Auth is **email/password only** (sign up →
> auto-sent verification → gated verify screen with resend; sign in + splash both block unverified users); **Google
> Sign-In was fully removed** (§7.29) — **no longer a blocker or a task**. **All four CV templates now ship** (§7.30);
> there is no "Coming soon" placeholder left in the app's CV flow.
>
> **The MVP feature set is complete.** Remaining before it ships:
>
> 1. **Final MVP review / end-to-end pass on a real Android device.** Not yet done — **the one substantive open item.**
>    Must include the **email-verification happy path with a REAL mailbox** (the emulator used `@cb.app`, which has no
>    inbox, so verified→home is the one path never exercised live — it runs `reloadEmailVerified()` + `goAfterAuth`,
>    covered only by the test fake). Also re-check the four CV templates (EN+AR, incl. a CV with **real Arabic content**
>    typed by hand — `adb input text` is ASCII-only, so live Arabic typing never happened), Qatar defaults, Arabic job
>    content, and the For-You → job-detail layout on the physical phone.
> 2. **User-side manual production steps** (unchanged, none are code): real upload keystore (release currently
>    **debug-signed** — no `android/key.properties`), provision the Firebase **Storage bucket**, App Check
>    enable/enforce, host the legal docs, Play Console submission. See `docs/PRODUCTION_READINESS.md` + §7.25.
> 3. **Known cosmetic gaps (out of scope so far):** the Home "Your AI toolkit" `SliverGrid` overflows at font scale
>    ≥ ~1.8 on narrow devices (§10); in an Arabic CV PDF a phone's leading `+` sits on the wrong side of the digits
>    (§7.30).
>
> **Rebranding to "Wazifly" is explicitly deferred** until the MVP is finished and verified — do not start it early.

**Phase 2 COMPLETE.** **Phase 3 · M1 (Jobs Platform) `6a6a72c`, M2 (Applications Center)
`b7e4b53`, and M3 (User Profile & Settings) `071902c` COMPLETE. Phase 4 · M1 (CV Builder)
`b237481`, M2 (Interview Prep) `fc35db4`, M3 (Recommendations / For You) `c1d044b` COMPLETE —
the AI toolkit is complete; no "Soon" cards remain. Phase 5 · M1 (Company Foundation) `baf5801`,
M2 (Job Management) `1ecba6f`, M3 (Applicants Management) `8d241a6`, M4 (Employer Analytics) `9932422` COMPLETE — the
entire employer side (Company / Jobs / Applicants / Analytics) is done. Phase 6 · M1 (Production Ready — Firebase &
Backend) `2e4c706` COMPLETE — a production Firebase infrastructure layer (Storage / Notifications / Analytics /
Crashlytics / Performance) behind vendor-neutral swap-point providers (§7.17).** Nothing is in progress.
**Recommended next milestone: Phase 6 · M2** — the natural continuation is to (a) **provision the Storage bucket** and
finish live media (photo/logo upload + resume-file view), and/or (b) **close the seeker→employer loop** (Firestore-back
the seeker `ApplicationsRepository` + surface real published `jobs/{jobId}` + assemble `ApplicantSnapshot` at apply
time), and/or (c) a **notification-settings + consent UI** wiring the `PushPreferences` / `AnalyticsConsent` /
`PushTokenRegistrar` seams. Other candidates: **AI Company Strength** (`Company.strength` shaped for it); an employer
**activity/audit UI** (`employerActivityProvider` foundation); Firestore-back the `RecruiterInsightsStore`; add the
Crashlytics/Performance Gradle plugins once AGP-9-compatible. (See the Phase 6 roadmap + §7.17 follow-ups.)

**Open items for the next session:**

1. **Provision Firebase Storage (unblocks live media):** Console → Storage → **Get Started**
   (creates the default bucket; may need Blaze), then deploy the already-authored `storage.rules`
   (`firebase deploy --only storage`). P6·M1 wired the full Storage stack (`StorageService` + progress
   + delete/replace + the photo/logo Remove UI) behind this; until the bucket exists, uploads degrade to
   a localized error. Then live-verify photo/logo upload + Remove (EN + AR) and add the resume-file view.
   (Can't be provisioned headlessly here — `gcloud`/`gsutil` absent; §5, §7.17.)

2. **Live re-verification of earlier milestones (blocked by env before, not app):** on a
   healthy `-gpu host` emulator, re-verify (EN+AR) the **P3·M1 job detail + integrations** AND
   the **P3·M2 Applications hub/detail/apply flow** — test-verified but not cleanly captured
   live (§7.7, §7.8, §10). Tip: `flutter run --route=/jobs` / `--route=/applications`
   (with `MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL="*"`) sidesteps the flaky Home app-bar.

3. **Candidate next milestones** (present a plan + wait for approval, per the workflow):
   Company Foundation (§7.13), Job Management (§7.14), and **Applicants Management (§7.15) are done**. The natural
   next steps: **(a) close the seeker→employer loop** — rebind the seeker `ApplicationsRepository` to Firestore
   (durable persistence) **and** surface real published `jobs/{jobId}` to the seeker Jobs Platform + assemble the
   `ApplicantSnapshot` at apply time (currently applicants are seeded for verification; §7.15). **(b)** an **Employer
   Activity / audit UI** (`employerActivityProvider` foundation is built). **(c)** an **AI Company Strength** score
   (`Company.strength` shaped for it — §7.13) or **AI Recruiter Insights** over `ApplicantSnapshot`. Also open:
   resume-file view via `url_launcher` once Storage is provisioned; the seeker `_ActionBar` latent full-width-button
   shape (bug #2 pattern — never verified live). *(All six AI-toolkit features + the full employer side — Company /
   Jobs / Applicants — are done.)*

4. **Polish follow-ups:** CV Builder Arabic-PDF Latin-run bidi reversal (§7.10) + a 2nd CV
   template; an **Interview Report PDF** (the models are already report-ready — §7.11) reusing
   the `pdf`/`printing` stack from CV Builder; a **Recommendations Report/PDF** (the
   `Recommendations` model is denormalized + report-ready — §7.12).

<details><summary>Historical: the (now completed) approved Phase 3 · M3 plan</summary>
   - **Scope (9 items):** Profile screen · Edit Profile · profile completion indicator ·
     upload/change profile photo (Firebase Storage) · language selection · notification
     preferences (architecture-ready) · change password (email users) · logout · Settings.
   - **Shared foundation (core/shared, no feature coupling):** `UserProfile` model →
     `shared/models/user_profile.dart` (fields: displayName, photoUrl, headline, location,
     bio, `userType?`, **plus the approved optional fields: skills `List<String>`,
     `experienceLevel` (enum, e.g. entry/junior/mid/senior/lead), and portfolio/github/
     linkedin URLs** — all optional, all feed the completion %, and designed to be reused by
     AI features + a future Employer Dashboard). `UserProfileRepository` **interface** in
     `core/services/user_profile/` with `watchProfile(uid)` (Firestore `.snapshots()`) +
     `saveProfile` + `ensureProfile` + `setPhotoUrl`; **Firestore + in-memory impls** +
     `userProfileRepositoryProvider` (swap point) + `userProfileProvider` (StreamProvider).
     Thin testable `ProfileImageStorage` seam (Firebase impl delegates to the existing
     `CloudStorageService`; in-memory fake for tests). `NotificationPreferences` model
     (master + jobAlerts + applicationUpdates + coachTips) behind a repository seam.
   - **Auth contract extension (reuse existing auth infra):** add `changePassword(
     {currentPassword, newPassword})` (email reauth) + `updateProfile({displayName?,
     photoUrl?})` to `AuthRepository` + `FirebaseAuthRepository` + the test `FakeAuthRepository`.
   - **Feature `lib/features/profile/`:** controllers (profile edit, photo, change-password,
     completion) + enhanced `ProfileScreen`, new `EditProfileScreen`, new
     `ChangePasswordScreen`, enhanced `SettingsScreen` (granular notifications + change-password
     entry). Routes `RouteNames.editProfile` (`/settings/profile/edit`) +
     `changePassword` (`/settings/change-password`). EN+AR l10n.
   - **Integrations (core providers + navigation → zero feature-to-feature deps):** Auth
     (identity, changePassword, updateProfile, signOut) · Firestore (`users/{uid}` via the
     repo; rules already allow own-doc access) · Storage (`users/{uid}/profile.jpg` — **needs
     a `storage.rules` allowing the authed user to write their own path; deploy it like
     `firestore.rules`**; the service degrades to a localized error otherwise) · Resume
     Analyzer (`lastResumeAnalysisProvider` chip/nudge) · Applications + Jobs (counts via the
     **core** `applicationsProvider` / `savedJobsProvider`; links to `/applications`, `/jobs`)
     · Career Coach (link to `/career-coach`). Profile reuses the foundational **auth** +
     **user_type** providers (the required "reuse existing auth infrastructure").
   - Model round-trip/completion tests, in-memory repo tests, change-password validation,
     EN+AR screen renders + locale sweep; `flutter analyze` + `flutter test` green; one
     milestone commit + docs commit.

</details>

**Later candidates** (the AI toolkit is complete — these are the remaining big rocks + polish),
pending direction:
- **Durable persistence** — implement Firestore/local impls for the existing seams
  (`ResumeAnalysisStore`, `ChatHistoryStore`, `SavedJobsStore`, `ApplicationsRepository`,
  `UserProfileRepository` (already Firestore-backed), `CvDraftStore`, `InterviewHistoryRepository`,
  `RecommendationsStore`); just rebind (interview + applications + recommendations need a
  `users/{uid}/…` subcollection Firestore rule).
- **Employer/Recruiter side** — the profile fields (skills, experience level, preferred titles)
  were shaped for a future Employer Dashboard.
- **Interview Report PDF** — the `InterviewSession` is already report-ready (§7.11); reuse the
  `pdf`/`printing` stack. **CV Builder polish** — Arabic-PDF Latin bidi fix; a 2nd CV template.
- **Markdown rendering** in the coach chat (currently prompted to emit plain text instead).

Per the workflow: present a plan, wait for approval, one milestone at a time, verify on the
emulator (both languages), `analyze`+`test` before committing, one commit per milestone.

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

**Phase 2 is complete.**

## Phase 3 roadmap
- **M1 — Jobs Platform** ✅ *complete* (see §7.7). Browse/search/filter, job detail, save,
  mock apply; shared jobs foundation (`Job` in `shared/models`, repo/stores in
  `core/services/jobs`) with `fetchJobById`/`searchJobs(JobQuery)` so a real jobs API swaps
  in unchanged. Integrates resume match, Best-matches (reuses M2), and a coach deep-link.
  Test-verified (99 pass); live-verified Arabic browse; detail+integrations pending a clean
  live re-check (§7.7).
- **M2 — Applications Center** ✅ *complete* (see §7.8). My Applications / Saved / Statistics /
  status+history over a Stream-based, Firestore-ready `ApplicationsRepository`; mock Apply
  creates an `Application`; integrates all four earlier features with **zero feature-to-
  feature dependencies**. Test-verified (118 pass); Home CTAs live-verified (Arabic);
  hub/detail pending a clean live re-check (§7.8).
- **M3 — User Profile & Settings** ✅ *complete* (see §7.9). Extended `UserProfile` (skills,
  experience level, preferred job titles, links) + completion indicator, Edit Profile, photo
  upload, change password, granular notifications, over a Stream-based, Firestore-ready
  `UserProfileRepository` with **zero feature-to-feature dependencies**. **Live-verified EN+AR**
  (153 pass). Only pending item: provision Firebase Storage for photo upload (§7.9).

## Phase 4 roadmap
- **M1 — AI CV Builder** ✅ *complete* (see §7.10). Seeds a CV from the profile + reused resume
  analysis, manual editing, AI enhancement (`AiService.generateJson`), a template registry
  (ATS live; Modern/Minimal/Harvard "coming soon"), and a WYSIWYG PDF (`pdf` + `printing`)
  behind a `CvPdfGenerator` swap seam. **Zero feature-to-feature deps.** Live-verified EN (full
  flow) + AR (179 pass). Follow-up: Arabic-PDF Latin bidi fix; more templates.
- **M2 — AI Interview Prep** ✅ *complete* (see §7.11). HR/Technical/Behavioral interviews with
  AI questions, scored per-answer feedback (5 dims), a streamed debrief + improvement plan, and
  Firestore-ready history — reusing profile/resume/CV/job via core providers. Report-ready
  models. **Live-verified EN+AR** with real Gemini (212 pass).
- **M3 — AI Recommendations / For You** ✅ *complete* (see §7.12). One holistic Gemini pass over
  profile/resume/CV/applications/interviews → recommended jobs (confidence + reason), skills,
  certifications, courses, an action-oriented roadmap, and next best actions (estimated time +
  deep links) — provider-agnostic, Firestore-ready `RecommendationsStore` (latest-only) with a
  refresh guard, **zero feature-to-feature deps**. **Live-verified EN+AR** with real Gemini (238
  pass). Flips the last "Soon" Home card live.
- **Candidates:** durable persistence · Interview Report PDF · Recommendations PDF · Employer side.

## Phase 5 roadmap (Employer side)
- **M1 — Employer Dashboard: Company Foundation** ✅ *complete* (see §7.13). Role-based landing
  (employer → `/employer`), Company Profile/Settings/Edit + completion + logo seam, over a
  Firestore-ready `CompanyRepository` (`companies/{companyId}`) + shared `Company` model. Forward-ready
  fields (verificationStatus, companySlug, social links, `CompanyStrength`). **Zero feature-to-feature
  deps.** Live-verified EN+AR (270 pass).
- **M2 — Employer Job Management** ✅ *complete* (see §7.14). Full job lifecycle: My Jobs → create/edit
  (auto-save + validation + unsaved guard) → preview (shared `JobDetailView`) → publish-confirm →
  archive/close/reopen/duplicate/soft-delete, optimistic with rollback. `JobPosting` superset
  `toJob()`-projects to the seeker `Job`; separate `EmployerJobsRepository` (`jobs/{jobId}`). **Zero
  feature-to-feature deps.** Live-verified EN+AR (329 pass); rules deployed.
- **M3 — Employer Applicants Management** ✅ *complete* (see §7.15). Grouped-by-job applicants inbox →
  detail (AI match, resume analysis, skills, links, interview readiness, timeline, private notes) →
  status pipeline + note CRUD, optimistic with rollback. Shared `Application` extended (dual-keyed +
  denormalized `ApplicantSnapshot`); separate `EmployerApplicantsRepository` + owner-private notes +
  activity-log foundation. **Zero feature-to-feature deps.** Live-verified EN+AR (375 pass); rules deployed.
- **M4 — Employer Analytics** ✅ *complete* (see §7.16). Read-only hiring dashboard — KPI overview, application
  status funnel, top jobs, time-to-hire, applicant-quality distribution, applications trend — plus an on-demand
  **AI Recruiter Insights** card (strengths/bottlenecks/suggested actions). All computed live by a pure
  `AnalyticsCalculator` over the employer's jobs/applicants/activity streams; the AI layer reuses the
  Recommendations architecture (context+signature → `AiService.generateJson` → latest-only `RecruiterInsightsStore`
  seam + refresh guard). Plain-Flutter charts (no new deps). **Zero feature-to-feature deps; no new Firestore
  rules.** Live-verified EN+AR (412 pass). AI Company Strength deferred.
- **Other candidates:** close the seeker→employer loop (Firestore-back the seeker `ApplicationsRepository`
  + surface real published jobs to seekers + assemble `ApplicantSnapshot` at apply time); **AI Company Strength**
  score (`Company.strength` is shaped for it); employer activity/audit UI; Firestore-back the
  `RecruiterInsightsStore`; employer verification flow; job view-count instrumentation (analytics views are N/A
  until then).

## Phase 6 roadmap (Production readiness)
- **M1 — Production Ready: Firebase & Backend** ✅ *complete* (see §7.17). Five vendor-neutral core services
  (Storage / Notifications / Analytics / Crashlytics / Performance), each **interface + single Firebase impl +
  Noop/in-memory + swap-point provider**, all best-effort & non-blocking. Storage gains progress + delete/replace +
  metadata (media seams rebased; photo/logo progress UI + Remove); Notifications gains a provider-agnostic
  `NotificationService` + token-registrar seam + `PushPreferences` foundation; Analytics adds a route-observer +
  event catalog + consent lever; Crashlytics adds global error handlers + user context; Performance adds custom
  traces. Deps added + **build-verified**. **Zero feature-to-feature deps; no new Firestore rules.** Live-verified
  EN+AR on device (438 pass). Deferred: live Storage upload (bucket unprovisioned) + the Crashlytics/Performance
  Gradle plugins (AGP 9).
- **M2 — Security & Performance** ✅ *complete* (see §7.18). Firebase **App Check** (6th vendor-neutral core
  service, activated non-blocking after `runApp`, graceful fallback), a **Security Audit Log** foundation
  (Analytics `security_event` + Crashlytics; wired at the employer permission-denied paths), **hardened
  `firestore.rules`** (identity-field immutability + size caps, **deployed**) + **hardened `storage.rules`**
  (content-type + size caps), **Firestore `Settings`** (bounded persistence) + `.limit()` guards, and
  **dependency-free image optimization** (`AppImage` decode-downsizing across all 7 sites + `ImageOptimizer`
  upload downscale). **Zero feature-to-feature deps.** Live-verified EN+AR (449 pass). Manual console steps
  (App Check enable/enforce, Storage bucket, debug-token allow-list, release providers) documented in §5.
- **M3 — candidates (present a plan + wait for approval):** (a) provision Storage → finish live media + resume-file
  view + live App Check enforcement; (b) close the seeker→employer loop (+ composite indexes / cursor pagination);
  (c) a notification-settings + analytics-consent UI wiring the P6·M1 seams; (d) AI Company Strength; (e) add the
  Crashlytics/Performance Gradle plugins once AGP-9-compatible.

See §8 for candidate future work.

**Workflow rules (user-mandated):** present a plan per milestone and **wait for
approval before writing code**; implement one milestone at a time; small tasks;
verify each milestone on the emulator before moving on; `flutter analyze` + `flutter
test` before committing; **one Git commit per completed milestone**; don't start the
next milestone until the current is verified. Prefer real integrations over mock UI.

---

## 10. Known issues & environment quirks

**Home AI-toolkit feature grid overflows at extreme font scale (open, pre-existing — see §7.27).** At system font
scale ≥ ~1.8 on a narrow device (≈360dp), `home_screen.dart`'s `SliverGrid` (`childAspectRatio: 1.42`) overflows its
cells ("BOTTOM OVERFLOWED BY … PIXELS", worse in Arabic). Not one of the reported bugs; only manifests at extreme
accessibility sizes. Fix candidate: `mainAxisExtent` / lower aspect ratio / intrinsic-height cards.

**Emulator (`emulator-5554`) rendering/input — important for on-device verification:**
- **Impeller breaks `adb screencap`** (frozen/stale frames). **Always run with
  `--no-enable-impeller`** (Skia) for reliable screenshots.
- **Software GPU (`-gpu swiftshader_indirect`) is unusably slow / crashes.** Launch the
  emulator with **`-gpu host`**.
- **Input can wedge / the GPU surface can corrupt (all-black) mid-session** — seen badly
  in Phase 3 · M1: Home taps stopped registering, then a rotation/`adb reboot` left the
  display all-black. **`adb reboot` did NOT fix it; a full cold-boot did:**
  `adb -s emulator-5554 emu kill` then relaunch with
  `emulator.exe -avd careerbridge_pixel -gpu host -no-snapshot-load -no-boot-anim`.
  After that the display renders again. The **Home "Browse Jobs" CTA** was especially
  tap-resistant (dropped taps intermittently even when healthy) — the Jobs list *tiles*
  and other screens tapped fine, so it's an input artifact, not a wiring bug.
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

**No functional app bugs open.** `flutter analyze` clean; **466 tests pass** (as of P6·M4).
One known cosmetic limitation: pure-Latin runs can render reversed in the Arabic CV PDF
(pdf-package bidi; §7.10) — Arabic content is correct. See §7.15/§7.16 "Notes" for the M3/M4 scope
limitations, §7.17 "Notes" for P6·M1, and §7.18 + §5 for P6·M2 (Storage default bucket unprovisioned →
live media/upload + `storage.rules` deploy deferred; App Check active but **monitoring-only** until the API
is enabled + debug token allow-listed + enforcement flipped; Crashlytics/Performance Gradle plugins deferred
for AGP 9; token-registrar/push-prefs/consent are wired seams with no UI consumer yet).

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

**Jobs Platform** `lib/features/jobs/`
`application/`: `jobs_browse_controller.dart`, `job_detail_controller.dart`.
`presentation/`: `jobs_screen.dart`, `job_detail_screen.dart`,
`widgets/{job_list_tile,job_filter_sheet}.dart`.
**Shared jobs foundation** `lib/shared/models/job.dart` (Job) ·
`lib/core/services/jobs/` (`jobs_repository.dart` = `JobsRepository`+`JobQuery`,
`seed_jobs_repository.dart` = `SeedJobsRepository`+`jobsRepositoryProvider`,
`saved_jobs_store.dart` = saved-only seam). Seed data `assets/data/seed_jobs.json`.
Per-job match: `JobMatchingRepository.matchJob()` (in `job_matching`).

**Applications Center (seeker)** `lib/features/applications/`
`application/applications_controller.dart` (filter + stats + derived providers).
`presentation/`: `applications_screen.dart`, `application_detail_screen.dart`,
`widgets/{stats_card,application_tile,application_filter_sheet}.dart`.
**Shared applications foundation** `lib/shared/models/application.dart` (Application + status/history;
**P5·M3-extended**: dual-keyed `applicantUid`/`ownerUid`, `source`, nested `ApplicantSnapshot`, event
`by`/`note`) + `applicant_snapshot.dart` + `application_note.dart` + `employer_activity.dart` ·
`lib/core/services/applications/` (`applications_repository.dart` interface,
`in_memory_applications_repository.dart` = impl + `applicationsRepositoryProvider` +
`applicationsProvider` + `appliedJobIdsProvider`). Firestore-ready: rebind the provider.
**Promoted (P5·M3)** to `lib/shared/widgets/`: `application_status_chip.dart` (`StatusChip`),
`status_timeline.dart`, `application_status_style.dart` (label/color/icon) — shared by the seeker
Applications Center **and** the employer Applicants Management (the only cross-surface link).

**User Profile & Settings** `lib/features/profile/`
`domain/`: `experience_level.dart`, `profile_failure.dart`.
`application/`: `profile_edit_controller.dart`, `profile_photo_controller.dart`,
`change_password_controller.dart`, `profile_completion_provider.dart`
(`currentUserProfileProvider` + `profileCompletionProvider`).
`presentation/`: `profile_screen.dart` (enhanced), `edit_profile_screen.dart`,
`change_password_screen.dart`, `profile_l10n.dart`, `widgets/{completion_indicator,chip_input}.dart`.
**Shared profile foundation** `lib/shared/models/user_profile.dart` (`UserProfile` +
`ProfileField`) · `lib/core/services/user_profile/` (`user_profile_repository.dart` interface +
providers, `firestore_user_profile_repository.dart`, `in_memory_user_profile_repository.dart`,
`profile_image_storage.dart`). **Notifications** `lib/features/settings/domain/notification_preferences.dart`
+ `application/{notification_preferences_store,notifications_controller}.dart`.
Auth extension: `changePassword`/`updateProfile` on the `AuthRepository` (§7.9). `storage.rules`.

**AI CV Builder** `lib/features/cv_builder/`
`domain/`: `cv_data.dart` (`CvData` + nested + `fromProfile`), `cv_template.dart`
(`CvTemplateId` + `cvTemplateCatalog`), `cv_pdf_generator.dart` (`CvPdfGenerator` seam +
`CvLabels`), `cv_enhancement_repository.dart`, `cv_builder_exception.dart`.
`data/`: `cv_enhancement_repository_impl.dart` (+ provider, prompt), `pdf/pdf_cv_generator.dart`
(+ `cvPdfGeneratorProvider`), `pdf/cv_fonts.dart` (PdfGoogleFonts + fallback),
`templates/{pdf_template,ats_template}.dart`.
`application/`: `cv_builder_controller.dart`, `cv_draft_store.dart`.
`presentation/`: `cv_builder_screen.dart`, `cv_preview_screen.dart` (`printing` `PdfPreview`),
`cv_l10n.dart`, `widgets/{cv_template_picker,entry_editors}.dart`.
Deps: **`pdf` + `printing`** (added P4·M1; build-verified). Shared `ChipInput` now in
`lib/shared/widgets/`. **`CvDraftStore` now in `lib/core/services/cv_store/`** (P4·M2).

**AI Interview Prep** `lib/features/interview_prep/`
`domain/`: `interview_models.dart` (`InterviewSession`/`Question`/`Answer`/`AnswerFeedback`/
`InterviewScores`/`InterviewSummary` + enums; report-ready), `interview_context.dart`,
`interview_repository.dart` (interface), `interview_exception.dart`.
`data/`: `interview_repository_impl.dart` (+ `interviewRepositoryProvider`, prompts).
`application/`: `interview_controller.dart` (phased + context assembly).
`presentation/`: `interview_prep_screen.dart`, `interview_history_screen.dart`,
`interview_session_detail_screen.dart`, `interview_l10n.dart`, `widgets/score_display.dart`.
**History seam** `lib/core/services/interview_store/` (`interview_history_repository.dart`
interface, `in_memory_interview_history_repository.dart` = impl + `interviewHistoryRepositoryProvider`
+ `interviewSessionsProvider`). Firestore-ready: rebind the provider.

**AI Recommendations / For You** `lib/features/recommendations/`
`domain/`: `recommendation_models.dart` (`Recommendations` + 6 section models + enums;
report-ready), `recommendation_context.dart` (primitives bundle + `AvailableJob` + `signature`),
`recommendations_repository.dart` (interface), `recommendations_exception.dart`.
`data/`: `recommendations_repository_impl.dart` (+ `recommendationsRepositoryProvider`, holistic
prompt, job-id filtering).
`application/`: `recommendations_controller.dart` (phased + context assembly + refresh guard).
`presentation/`: `recommendations_screen.dart`, `recommendations_l10n.dart`,
`widgets/recommendation_sections.dart`.
**Cache seam** `lib/core/services/recommendations_store/` (`recommendations_store.dart` interface,
`in_memory_recommendations_store.dart` = impl + `recommendationsStoreProvider` +
`latestRecommendationsProvider`). Firestore-ready: rebind the provider.

**Employer feature** `lib/features/employer/` — one feature spanning Dashboard (M1) + Jobs (M2) + Applicants (M3).
`domain/`: **M1** `industry.dart` (14), `company_size.dart` (6), `company_verification_status.dart`,
`company_stats.dart`, `company_failure.dart`; **M2** `job_status.dart` (+ `allowedNext`), `employment_type.dart`,
`job_experience.dart`, `salary_period.dart`, `job_validation.dart`; **M3** `applicant_status_flow.dart` (pure
`ApplicationStatus.allowedNext`/`isTerminal`).
`application/`: **M1** `company_providers.dart` (`currentCompanyProvider`/`companyCompletionProvider`/
`companyStatsProvider` — stats now derive from jobs + applicants), `company_edit_controller.dart`,
`company_logo_controller.dart`; **M2** `employer_jobs_providers.dart` (filter/sort/`visibleEmployerJobsProvider`/
`filteredEmployerJobsProvider`/`employerJobByIdProvider`/`employerJobsStatsProvider`), `employer_jobs_controller.dart`
(optimistic lifecycle), `job_editor_controller.dart` (autoDispose.family, auto-save); **M3**
`employer_applicants_providers.dart` (filter/sort/`visibleApplicantsProvider`/`filteredApplicantsProvider`/
`groupedApplicantsProvider`/`applicantsForJobProvider`/`applicantByIdProvider`/`employerApplicantsStatsProvider`),
`employer_applicants_controller.dart` (optimistic status + activity), `employer_notes_controller.dart`
(optimistic notes + `visibleNotesProvider`).
`presentation/`: **M1** `employer_home_screen.dart` (Applicants tile now live), `company_profile_screen.dart`,
`edit_company_screen.dart`, `company_l10n.dart`; **M2** `employer_jobs_screen.dart`, `job_editor_screen.dart`,
`job_preview_screen.dart`, `employer_job_detail_screen.dart` (Applicants-N entry), `employer_jobs_l10n.dart`,
`job_actions.dart`, `job_action_handler.dart`, `widgets/{job_status_chip,employer_job_tile}.dart`; **M3**
`employer_applicants_screen.dart` (grouped inbox / per-job via `jobId`), `employer_applicant_detail_screen.dart`,
`applicant_actions.dart`, `applicant_action_handler.dart`, `employer_applicants_l10n.dart`, `widgets/{applicant_avatar,
employer_applicant_tile,applicant_group_header,match_score_badge,resume_summary_card,interview_readiness_card,
application_note_tile,note_editor_sheet}.dart`; **M4** `employer_analytics_screen.dart`, `analytics_l10n.dart`,
`widgets/analytics_widgets.dart` (plain-Flutter charts). **M4 domain** `domain/analytics/{employer_analytics,
analytics_calculator,recruiter_insights,recruiter_insights_context,recruiter_insights_repository,
recruiter_insights_exception}.dart`; **M4 data** `data/recruiter_insights_repository_impl.dart`; **M4 application**
`application/{employer_analytics_providers,recruiter_insights_controller}.dart`.
**Shared models** `lib/shared/models/`: `company.dart` (`Company`+`CompanyStrength`+`CompanyField`),
`job_posting.dart` (`JobPosting`+`SalaryRange`+`JobMetrics`+`JobStatusChange`, `toJob()`), + the applications models
above. **Shared widget** `lib/shared/widgets/job_detail_view.dart` (employer preview == seeker view).
**Core services** `lib/core/services/`: `company/` (`CompanyRepository` + `companyProvider` + logo seam),
`jobs/{employer_jobs_repository,firestore_…,in_memory_…}.dart` (`employerJobsRepositoryProvider`/`employerJobsProvider`,
query by `ownerUid`), `applications/{employer_applicants_repository,firestore_…,in_memory_…}.dart`
(`employerApplicantsRepositoryProvider`/`employerApplicantsProvider`, query by `ownerUid`),
`notes/{employer_notes_repository,firestore_…,in_memory_…}.dart` (owner-private `applicationNotes`),
`activity/{employer_activity_repository,firestore_…,in_memory_…}.dart` (audit-log foundation),
`recruiter_insights_store/{recruiter_insights_store,in_memory_…}.dart` (**M4** latest-only insights cache seam,
in-memory → Firestore later).
Role branch in `splash`/`auth_navigation`/`user_type_selection`; role-aware `settings_screen` account card;
logout clears `userType`. `firestore.rules` (deployed): `companies/{companyId}`, `jobs/{jobId}`, `applications/{id}`,
`applicationNotes/{id}`, `employerActivity/{id}` + `storage.rules`.

**Production Firebase infrastructure (P6·M1)** — five vendor-neutral core services, each `interface + firebase_*
impl + noop/in_memory + provider`:
`lib/core/services/cloud_storage/` (`storage_service.dart` = `StorageService`+`StorageMetadata`+`StorageUploadProgress`,
`firebase_storage_service.dart` = `storageServiceProvider`, `in_memory_storage_service.dart`, `storage_paths.dart`) ·
`lib/core/services/messaging/` (`notification_service.dart` = `NotificationService`+`PushMessage`+`NotificationPermission`,
`firebase_notification_service.dart` (+ bg handler + `notificationServiceProvider`), `noop_notification_service.dart`,
`push_token_registrar.dart`, `push_preferences.dart` = `PushPreferences`+`PushCategory`+repo) ·
`lib/core/services/analytics/` (`analytics_service.dart`, `firebase_analytics_service.dart` = `analyticsServiceProvider`,
`noop_analytics_service.dart`, `analytics_events.dart` = `AnalyticsEvents`/`AnalyticsParams`, `analytics_route_observer.dart`,
`analytics_consent.dart` = `analyticsConsentControllerProvider`) ·
`lib/core/services/crashlytics/` (`crash_reporter.dart`, `firebase_crash_reporter.dart` = `crashReporterProvider`,
`noop_crash_reporter.dart`) ·
`lib/core/services/performance/` (`performance_monitor.dart` = `PerformanceMonitor`/`PerfTrace`,
`firebase_performance_monitor.dart` = `performanceMonitorProvider`, `noop_performance_monitor.dart`).
Media seams `user_profile/profile_image_storage.dart` + `company/company_logo_storage.dart` now delegate to
`StorageService` (upload+progress+delete). Bootstrap in `main.dart` (error handlers + consent + user context +
`AppRouter.create({observers})`); `app.dart` takes the built `router`.

**Firebase** `lib/core/services/firebase/{firebase_service,firebase_options}.dart` ·
`firebase.json` · `firestore.rules` · `firestore.indexes.json` · `storage.rules`
(authored; deploy once the default bucket is provisioned). Deps: `firebase_analytics`/`crashlytics`/`performance`
(added P6·M1; **Crashlytics/Performance Gradle plugins deferred — AGP 9**).

**Auth** `lib/features/auth/` (`domain/auth_repository.dart` interface,
`data/firebase_auth_repository.dart`, `application/auth_providers.dart`,
`presentation/` screens, `auth_navigation.dart` `goAfterAuth`).

**Navigation** `lib/core/navigation/{app_router,route_names}.dart`.
**l10n** `lib/core/localization/l10n/app_{en,ar}.arb` (+ generated).
**Tests** `test/` — **438 pass** (`support/fake_auth.dart`, `render_all_locales_test.dart` locale sweep,
`resume_*`/`job_*`/`applications_*`/`saved_jobs_*`/`career_coach_*`/`cv_*`/`interview_*`/`recommendation*`/`company_*`
tests; **employer jobs** `employer_jobs_{repository,controller,providers,screens}_test` + `job_{posting_model,validation,
editor_controller,detail_view}_test`; **employer applicants (P5·M3)** `application_model_test` (extended),
`applicant_snapshot_test`, `application_note_test`, `applicant_status_flow_test`, `employer_applicants_{repository,
controller,providers,screens}_test`, `employer_notes_{repository,controller}_test`; **employer analytics (P5·M4)**
`analytics_calculator_test`, `employer_analytics_providers_test`, `recruiter_insights_{repository,controller,store}_test`,
`employer_analytics_screen_test`; **production infra (P6·M1)** `storage_service_test`, `push_preferences_test`,
`notification_service_test`, `analytics_events_test`, `analytics_route_observer_test`, `analytics_consent_test`,
`telemetry_noop_test` + extended `profile_photo_controller_test`/`company_logo_controller_test` for progress+remove).
Widget hosts wrap in the real `AppTheme.light(locale)`; controller tests assert optimistic rollback via throwing fakes,
the analytics calculator is exhaustively unit-tested (pure, injectable clock), and telemetry uses Noop/in-memory fakes.

---

## 12.5 Routes & provider/repository reference (quick map)

**All routes** (`route_names.dart`; `push*` = forward, `go*` = reset):
| Name | Path | Screen |
|---|---|---|
| `splash` | `/` | Splash |
| `language` | `/language` | Language picker |
| `country` | `/country` | Country picker |
| `onboarding` | `/onboarding` | Onboarding (`?replay=true`) |
| `welcome` | `/welcome` | Welcome / auth entry |
| `emailAuth` / `phoneAuth` / `otp` | `/auth/email` · `/auth/phone` · `/auth/otp` | Auth |
| `userType` | `/user-type` | Job Seeker / Employer |
| `home` | `/home` | Home dashboard |
| `settings` / `profile` | `/settings` · `/settings/profile` | Settings · Profile |
| `resumeAnalyzer` | `/resume-analyzer` | AI Resume Analyzer (P2·M1) |
| `jobMatching` | `/job-matching` | AI Job Matching (P2·M2) |
| `careerCoach` | `/career-coach` | AI Career Coach (P2·M3); optional `extra` = seed prompt |
| `jobs` / `jobDetail` | `/jobs` · `/jobs/:id` | Jobs Platform (P3·M1) |
| `applications` / `applicationDetail` | `/applications` · `/applications/:id` | Applications Center (P3·M2) |
| `editProfile` | `/settings/profile/edit` | Edit Profile (P3·M3) |
| `changePassword` | `/settings/change-password` | Change Password (P3·M3) |
| `cvBuilder` / `cvPreview` | `/cv-builder` · `/cv-builder/preview` | AI CV Builder (P4·M1) |
| `interviewPrep` | `/interview-prep` | AI Interview Prep (P4·M2); optional `extra` = `Job` |
| `interviewHistory` / `interviewSessionDetail` | `/interview-prep/history` · `…/history/:id` | Interview history + detail |
| `recommendations` | `/recommendations` | AI Recommendations / For You (P4·M3) |
| `employerHome` | `/employer` | Employer Home dashboard (P5·M1; role-routed) |
| `companyProfile` / `editCompany` | `/employer/company` · `/employer/company/edit` | Company Profile · Edit Company (P5·M1) |
| `employerJobs` | `/employer/jobs` | My Jobs list (P5·M2) |
| `createJob` / `jobPreview` | `/employer/jobs/new` · `/employer/jobs/preview` | Create job · Preview (P5·M2; `jobPreview` `extra` = `JobPosting`; static before `:id`) |
| `employerJobDetail` / `editJob` | `/employer/jobs/:id` · `/employer/jobs/:id/edit` | Job detail · Edit (P5·M2) |
| `employerJobApplicants` | `/employer/jobs/:id/applicants` | One job's applicants (P5·M3) |
| `employerApplicants` / `employerApplicantDetail` | `/employer/applicants` · `/employer/applicants/:appId` | Applicants inbox (grouped) · Applicant detail (P5·M3) |
| `employerAnalytics` | `/employer/analytics` | Employer Analytics dashboard + AI Recruiter Insights (P5·M4) |

**Core services & swap-point providers** (`lib/core/services/…`; each is the single binding
to rebind for a real backend — in-memory/local today):
| Provider | Interface / type | Backed by / swap to |
|---|---|---|
| `aiServiceProvider` | `AiService` | `FirebaseAiService` (Gemini) → Vertex/other |
| `resumeAnalysisStoreProvider` · `lastResumeAnalysisProvider` | `ResumeAnalysisStore` | in-memory → Firestore/local |
| `chatHistoryStoreProvider` | `ChatHistoryStore` | in-memory → Firestore/local |
| `jobsRepositoryProvider` | `JobsRepository` (`fetchJobs`/`fetchJobById`/`searchJobs`) | `SeedJobsRepository` (asset) → real jobs API |
| `savedJobsStoreProvider` · `savedJobsProvider` | `SavedJobsStore` | in-memory → Firestore/local |
| `applicationsRepositoryProvider` · `applicationsProvider` (Stream) · `appliedJobIdsProvider` | `ApplicationsRepository` (`watchApplications`/`apply`/`updateStatus`/`withdraw`/`findByJobId`) | `InMemoryApplicationsRepository` → Firestore `users/{uid}/applications` |
| `storageServiceProvider` (P6·M1) | `StorageService` (`upload({metadata,onProgress})`/`delete`/`downloadUrl`) | `FirebaseStorageService` ↔ `InMemoryStorageService` (tests) — **default bucket not provisioned yet (§5)** |
| `userProfileRepositoryProvider` · `userProfileProvider` (Stream) | `UserProfileRepository` (`watchProfile`/`fetchProfile`/`saveProfile`/`ensureProfile`/`setUserType`/`setPhotoUrl`) | `FirestoreUserProfileRepository` (live) ↔ in-memory (tests) |
| `profileImageStorageProvider` | `ProfileImageStorage` (upload+progress+`deleteProfilePhoto`) | `FirebaseProfileImageStorage` → `StorageService` |
| `notificationPreferencesStoreProvider` | `NotificationPreferencesStore` | local storage → remote/FCM later |
| `cvPdfGeneratorProvider` | `CvPdfGenerator` | `PdfCvGenerator` (`pdf`/`printing`) → Syncfusion fallback |
| `cvEnhancementRepositoryProvider` | `CvEnhancementRepository` | `AiService.generateJson` (Gemini) |
| `cvDraftStoreProvider` | `CvDraftStore` (now in `core/services/cv_store`) | in-memory → Firestore/local |
| `interviewRepositoryProvider` | `InterviewRepository` (generate/evaluate/summarize/streamDebrief) | `AiService` (Gemini) |
| `interviewHistoryRepositoryProvider` · `interviewSessionsProvider` (Stream) | `InterviewHistoryRepository` (`watchSessions`/`saveSession`/`findById`/`delete`) | in-memory → Firestore `users/{uid}/interviews` |
| `recommendationsRepositoryProvider` | `RecommendationsRepository` (`generate`) | `AiService.generateJson` (Gemini) |
| `recommendationsStoreProvider` · `latestRecommendationsProvider` (Stream) | `RecommendationsStore` (`watchLatest`/`read`/`save`/`clear`) | in-memory (latest-only) → Firestore `users/{uid}/recommendations/latest` |
| `companyRepositoryProvider` · `companyProvider` (Stream) | `CompanyRepository` (`watchCompany`/`fetchCompany`/`saveCompany`/`ensureCompany`/`setLogoUrl`) | `FirestoreCompanyRepository` (live, `companies/{companyId}`) ↔ in-memory (tests) |
| `companyLogoStorageProvider` | `CompanyLogoStorage` (upload+progress+`deleteCompanyLogo`) | `FirebaseCompanyLogoStorage` → `StorageService` (`companies/{id}/logo.jpg`; **bucket unprovisioned**) |
| `employerJobsRepositoryProvider` · `employerJobsProvider` (Stream) | `EmployerJobsRepository` (`watchJobs`/`fetchJob`/`createJob`/`updateJob`) | `FirestoreEmployerJobsRepository` (live, `jobs/{jobId}`, query by `ownerUid`) ↔ in-memory (tests) |
| `employerApplicantsRepositoryProvider` · `employerApplicantsProvider` (Stream) | `EmployerApplicantsRepository` (`watchApplicants(ownerUid)`/`fetchApplicant`/`updateApplication`) | `FirestoreEmployerApplicantsRepository` (live, `applications`, query by `ownerUid`) ↔ in-memory (tests) |
| `employerNotesRepositoryProvider` · `notesForApplicationProvider(id)` (Stream) | `EmployerNotesRepository` (`watchNotes`/`addNote`/`updateNote`/`deleteNote`) | `FirestoreEmployerNotesRepository` (live, owner-private `applicationNotes`) ↔ in-memory (tests) |
| `employerActivityRepositoryProvider` · `employerActivityProvider` (Stream) | `EmployerActivityRepository` (`log`/`watchActivity`) | `FirestoreEmployerActivityRepository` (live, owner-private `employerActivity`; audit foundation) ↔ in-memory (tests) |
| `recruiterInsightsStoreProvider` · `latestRecruiterInsightsProvider` (Stream) | `RecruiterInsightsStore` (`watchLatest`/`read`/`save`/`clear`) | in-memory (latest-only) → Firestore `companies/{companyId}/insights/latest` (P5·M4) |
| `recruiterInsightsRepositoryProvider` | `RecruiterInsightsRepository` (`generate`) | `AiService.generateJson` (Gemini) — reuses the Recommendations pattern (P5·M4) |
| `employerAnalyticsProvider` · `analyticsClockProvider` | `EmployerAnalytics` (computed) | pure `AnalyticsCalculator` over the employer jobs/applicants/activity streams (P5·M4) |
| `notificationServiceProvider` (P6·M1) | `NotificationService` (permission/token/`onTokenRefresh`/`onMessage`/`onMessageOpened`) | `FirebaseNotificationService` (ready) ↔ `NoopNotificationService` |
| `pushTokenRegistrarProvider` (P6·M1) | `PushTokenRegistrar` (`register`/`unregister`) | `NoopPushTokenRegistrar` → Firestore `users/{uid}/fcmTokens` later (no UI yet) |
| `pushPreferencesRepositoryProvider` (P6·M1) | `PushPreferencesRepository` (`watch`/`read`/`save`) | `InMemoryPushPreferencesRepository` → Firestore `users/{uid}` later (no UI yet) |
| `analyticsServiceProvider` (P6·M1) | `AnalyticsService` (`logScreenView`/`logEvent`/`setUserId`/`setUserProperty`/`setEnabled`) | `FirebaseAnalyticsService` (ready) ↔ `NoopAnalyticsService` |
| `analyticsConsentControllerProvider` (P6·M1) | `bool` (persisted consent) | applied via `AnalyticsService.setEnabled` at bootstrap — feature code never branches |
| `crashReporterProvider` (P6·M1) | `CrashReporter` (`recordError`/`recordFlutterError`/`log`/`setUserIdentifier`/`setCustomKey`/`setEnabled`) | `FirebaseCrashReporter` (ready) ↔ `NoopCrashReporter` |
| `performanceMonitorProvider` (P6·M1) | `PerformanceMonitor` (`newTrace`/`setEnabled`) → `PerfTrace` | `FirebasePerformanceMonitor` (ready) ↔ `NoopPerformanceMonitor` |

**Feature controllers / providers** (per feature `application/`): `authStateProvider` +
`authRepositoryProvider` (auth) · `localeControllerProvider` · `themeControllerProvider` ·
`userTypeControllerProvider` · `notificationsControllerProvider` ·
`resumeAnalyzerControllerProvider` · `jobMatchingControllerProvider` +
`jobMatchingRepositoryProvider` · `careerCoachControllerProvider` +
`careerCoachRepositoryProvider` · `jobsBrowseControllerProvider` ·
`jobDetailControllerProvider(id)` · `applicationsFilterProvider` +
`filteredApplicationsProvider` + `applicationStatsProvider` + `applicationByIdProvider(id)` +
`savedJobsListProvider` · `profileEditControllerProvider` · `profilePhotoControllerProvider` ·
`changePasswordControllerProvider` · `currentUserProfileProvider` + `profileCompletionProvider` ·
`cvBuilderControllerProvider` · `interviewControllerProvider` · `recommendationsControllerProvider`.
**Employer (P5):** `companyEditControllerProvider` · `companyLogoControllerProvider` · `currentCompanyProvider` +
`companyCompletionProvider` + `companyStatsProvider` (M1) · `employerJobsFilterProvider` +
`visibleEmployerJobsProvider`/`filteredEmployerJobsProvider`/`employerJobByIdProvider(id)`/`employerJobsStatsProvider` +
`employerJobsControllerProvider` + `jobEditorControllerProvider(jobId?)` (M2) · `employerApplicantsFilterProvider` +
`visibleApplicantsProvider`/`filteredApplicantsProvider`/`groupedApplicantsProvider`/`applicantsForJobProvider(jobId)`/
`applicantByIdProvider(id)`/`employerApplicantsStatsProvider` + `employerApplicantsControllerProvider` +
`employerNotesControllerProvider` + `visibleNotesProvider(id)` (M3).

**Integration map (who reads what — all via core providers + navigation, no feature→feature
imports among the product features):** Job Matching reads the resume via
`lastResumeAnalysisProvider`; Jobs detail computes a per-job match via
`JobMatchingRepository.matchJob` and deep-links the coach via `careerCoach` `extra`; Career
Coach personalizes from `lastResumeAnalysisProvider`; Applications' mock Apply writes the
shared `ApplicationsRepository`, the "applied" badge derives via `appliedJobIdsProvider`,
and it links to `/jobs/:id` (matching) + `/career-coach` (interview prep).

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

**Phase 2 COMPLETE (verified live EN+AR).** **Phase 3 (M1–M3), Phase 4 (M1–M3), Phase 5 · M1–M4, and Phase 6 · M1
are COMPLETE** (through `3f1ff4a`; P6·M1 = feat `2e4c706` + this docs commit — see §6, §7.7–§7.17).
`flutter analyze` clean, **438 tests pass**, repo clean (only `.claude/settings.local.json`
intentionally uncommitted). Firebase AI Logic enabled + provisioned; Analytics/Crashlytics/Performance SDKs
initialize on device; the `companies`/`jobs`/`applications`/`applicationNotes`/`employerActivity` Firestore rules
are deployed (**P6·M1 added no new rules**). ⚠️ **Cloud Storage default bucket is still unprovisioned** (§5) —
live media upload deferred.
**The AI toolkit + the entire employer side are complete, and the app now has a production Firebase
infrastructure layer (Storage/Notifications/Analytics/Crashlytics/Performance).** Nothing is in progress —
candidate next: **provision the Storage bucket** (unblocks live photo/logo upload + resume-file view); add the
Crashlytics/Performance **Gradle plugins** once AGP-9-compatible; a **notification-settings UI** (wiring the
`PushPreferences` + `AnalyticsConsent` seams); close the **seeker→employer loop**; **AI Company Strength**.

**P6 · M1 (Production Ready — Firebase & Backend)** — five vendor-neutral core services, each **interface + single
Firebase impl + Noop/in-memory + swap-point provider** (the `AiService` pattern), all **best-effort + non-blocking**:
**Storage** (`StorageService` progress/delete/metadata; media seams rebased; photo/logo progress UI + Remove),
**Notifications** (`NotificationService` + `FirebaseNotificationService` replacing `MessagingService`; token registrar
seam; `PushPreferences` foundation), **Analytics** (`AnalyticsService` + vendor-neutral route observer + event catalog
+ persisted consent lever), **Crashlytics** (`CrashReporter` + global error handlers + uid/account_type context),
**Performance** (`PerformanceMonitor`/`PerfTrace`). Deps added + build-verified; Crashlytics/Perf **Gradle plugins
deferred** (AGP 9). Live-verified EN + AR on device (FCM token, named `screen_view`s, `setUserId`, `account_type`
property, custom events, Crashlytics init). Device fix: router now sets `CustomTransitionPage.name` so screen_views
carry names. Live Storage upload deferred (bucket). (§7.17)

**P5 · M4 (Employer Analytics)** — a read-only hiring dashboard (KPI overview, application status funnel,
top jobs, time-to-hire, applicant-quality distribution, applications trend) plus an on-demand **AI Recruiter
Insights** card (strengths/bottlenecks/suggested actions). All computed live by a **pure `AnalyticsCalculator`**
over the employer's jobs/applicants/activity streams (no new data sources / collections / rules). The AI layer
**reuses the Recommendations architecture** (primitive context + signature → `AiService.generateJson` →
defensive parse → latest-only `RecruiterInsightsStore` seam + refresh guard); the card is on-demand (idle →
"Generate insights"), not auto-called. Plain-Flutter charts (no new deps). **Zero product-feature-to-feature
deps.** Live-verified EN + AR on `employer01@cb.app` (real Firestore + real Gemini). One device-only fix:
`JobPerformance.status` made nullable so application-only jobs show no misleading "Published" chip. **AI Company
Strength deferred.** (§7.16)

**P5 · M3 (Employer Applicants Management)** — employers review + manage applicants for every published
job over the **same shared applications foundation** the seeker Applications Center uses. The
privacy-wall insight (rules keep each user's profile/resume/interview private) drove a **denormalized
`ApplicantSnapshot`** captured at apply time — the employer never reads an applicant's private docs.
Grouped-by-job inbox (stats/search/status-filter/sort) → detail (AI match, resume analysis, resume-file
graceful-degrade, skills, links, interview readiness, timeline, **private notes**) → status pipeline
(Move to Review/Interview/Accept/Reject, **appends** history) + note CRUD, all optimistic with rollback.
Extended shared `Application` (dual-keyed `applicantUid`/`ownerUid` + `source`); separate
`EmployerApplicantsRepository` + owner-private `EmployerNotesRepository` + an `EmployerActivityRepository`
audit foundation (recorded, no UI). Promoted `StatusChip`/`StatusTimeline` → `shared/widgets`. **Zero
product-feature-to-feature deps.** Live-verified EN + AR on `employer01` with real Firestore (seeded
applicants — see `scratchpad/seed_applicants.py`). **No device bugs — the 3 M2 lessons were pre-applied.**
**Scope note:** the seeker apply isn't Firestore-backed yet (applicants seeded for verification); resume-file
view is stubbed until Storage; the activity log has no UI; interview history is a lightweight snapshot (§7.15).

**P5 · M2 (Employer Job Management)** — full job lifecycle: My Jobs (search/status-filter/sort) →
create/edit (debounced auto-save + two-tier validation + unsaved guard) → preview (shared `JobDetailView`,
exactly as a seeker sees it) → publish-with-confirmation → archive-with-reason/close/reopen/duplicate/
soft-delete, all optimistic with rollback. A `JobPosting` superset `toJob()`-projects to the seeker `Job`;
a separate write-path `EmployerJobsRepository` (`jobs/{jobId}`, query by `ownerUid`). **Zero deps.**
Live-verified EN + AR. Three device-only bugs found + fixed and turned into reusable lessons: query by the
rule's field, wrap themed full-width buttons (test with real `AppTheme`), own dialog controllers in a
`StatefulWidget` (§7.14).

**P5 · M1 (Employer Dashboard — Company Foundation)** — the first employer-side milestone.
**Role-based landing** (employers → `/employer` Employer Home; job seekers → `/home`; branch on
`UserType` in splash/goAfterAuth/user-type-select; logout clears the role). A shared `Company` model
+ core `CompanyRepository` (`companies/{companyId}` == ownerUid) + `CompanyLogoStorage` seam. New
`lib/features/employer/`: Employer Home (quick stats, completion, company CTA, "Soon" tools), Company
Profile, Edit Company (all info fields + social links + logo); Settings is shared + role-aware.
Forward-ready: `verificationStatus`, `companySlug`, social links, embedded `CompanyStrength` (future
AI score). **Zero product-feature-to-feature deps.** Live-verified EN + AR. **Note:** logout now clears
`userType`; a Firestore snapshot listener that hits a permission error terminates (restart to re-subscribe
after a rules change); Storage bucket still unprovisioned (logo upload degrades).

**P4 · M3 (AI Recommendations / For You)** — one holistic `generateJson` pass over
profile/resume/CV/applications/interviews → recommended jobs (confidence + reason), skills,
certifications, courses, an action-oriented roadmap (This week/Next month/Next 3 months/6–12
months), and next best actions (priority + estimated time + in-app deep links). Recommended jobs
are chosen by id from the **shared** jobs universe (excludes applied) and deep-link to `/jobs/:id`.
Provider-agnostic (`AiService`); Firestore-ready `RecommendationsStore` (latest-only) with a
**refresh guard** (signature incl. language → "up to date" skips the AI call). **Zero
feature-to-feature deps.** Live-verified EN + AR with real Gemini.

**P4 · M2 (AI Interview Prep)** runs HR/Technical/Behavioral interviews: `generateJson` for
questions + per-answer evaluation (5-dim scores + feedback), `streamText` for the final debrief
+ scorecard + **improvement plan**. Reuses profile/resume/CV/job via **core** providers only;
history behind a **Firestore-ready** `InterviewHistoryRepository` seam (rebind for
`users/{uid}/interviews`). `InterviewSession` is **report-ready** for a future Interview Report
PDF. **Zero feature-to-feature deps.** Live-verified EN + AR with real Gemini. Also promoted
`CvDraftStore` → `core/services/cv_store` so all reusable stores live in core.

**P4 · M1 (AI CV Builder)** — a WYSIWYG PDF builder (`pdf` + `printing`) behind a `CvPdfGenerator`
swap seam, template registry (ATS live; others "coming soon"). Follow-up: Arabic-PDF Latin bidi
reversal (§7.10); Firebase Storage still unprovisioned from M3 (blocks profile-photo upload only).

**Live-verify caveat (older P3 · M1 + M2):** the Jobs *detail*, the Applications *hub/detail*,
and the apply flow are **test-verified but not cleanly captured live** (the documented
Home-CTA-input-drop + job-detail-surface-freeze quirk, §10; env, not app). Re-verify on a
fresh `-gpu host` emulator — `flutter run --route=/jobs` / `--route=/applications` (with
`MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL="*"`) sidesteps the flaky Home app-bar.

**Next:** nothing is in progress — present a plan for any new milestone (§8 lists
candidates) and **wait for the user's approval before coding**. Keep the conventions in §13;
run with `--no-enable-impeller` and `-gpu host`; the test account session is persisted so
the app opens to Home. (Persisted app language is currently **English** after P4·M2 verification.)
