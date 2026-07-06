# Career Bridge — Session Handoff

> Living handoff doc so a fresh Claude session can continue immediately.
> Last updated: **Phase 5 · Milestone 4 (Employer Analytics) — COMPLETE** (see §7.16) — live-verified EN + AR on `employer01@cb.app` (real Firestore + real Gemini insights).
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
feature/resume-analyzer  *  (HEAD)   docs: HANDOFF for Phase 5 Milestone 4  <-- current HEAD (this docs commit)
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

## 8. Next steps

**Phase 2 COMPLETE.** **Phase 3 · M1 (Jobs Platform) `6a6a72c`, M2 (Applications Center)
`b7e4b53`, and M3 (User Profile & Settings) `071902c` COMPLETE. Phase 4 · M1 (CV Builder)
`b237481`, M2 (Interview Prep) `fc35db4`, M3 (Recommendations / For You) `c1d044b` COMPLETE —
the AI toolkit is complete; no "Soon" cards remain. Phase 5 · M1 (Company Foundation) `baf5801`,
M2 (Job Management) `1ecba6f`, M3 (Applicants Management) `8d241a6`, M4 (Employer Analytics) COMPLETE — the
entire employer side (Company / Jobs / Applicants / Analytics) is done.** Nothing is in progress. **Candidate
next milestones:** close the seeker→employer loop (Firestore-back the seeker `ApplicationsRepository` + surface
real published jobs + assemble `ApplicantSnapshot` at apply time); an **AI Company Strength** score
(`Company.strength` is shaped for it); an employer **activity/audit UI** (`employerActivityProvider` foundation);
Firestore-back the `RecruiterInsightsStore`. (See the Phase 5 roadmap + §7.16 follow-ups.)

**Open items for the next session:**

1. **Provision Firebase Storage (unblocks profile-photo upload):** Console → Storage →
   **Get Started** (creates the default bucket; may need Blaze), then deploy the already-authored
   `storage.rules` (`firebase deploy --only storage`). Until then the photo upload degrades to a
   localized error (§7.9); everything else in M3 works on live Firestore + Auth.

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

See §8 for candidate future work.

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

**No functional app bugs open.** `flutter analyze` clean; **412 tests pass** (as of P5·M4).
One known cosmetic limitation: pure-Latin runs can render reversed in the Arabic CV PDF
(pdf-package bidi; §7.10) — Arabic content is correct. See §7.15 "Notes" for the M3 scope
limitations and §7.16 "Notes" for M4 (job view analytics N/A until view instrumentation;
insights store in-memory; AI Company Strength deferred).

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

**Firebase** `lib/core/services/firebase/{firebase_service,firebase_options}.dart` ·
`firebase.json` · `firestore.rules` · `firestore.indexes.json`.

**Auth** `lib/features/auth/` (`domain/auth_repository.dart` interface,
`data/firebase_auth_repository.dart`, `application/auth_providers.dart`,
`presentation/` screens, `auth_navigation.dart` `goAfterAuth`).

**Navigation** `lib/core/navigation/{app_router,route_names}.dart`.
**l10n** `lib/core/localization/l10n/app_{en,ar}.arb` (+ generated).
**Tests** `test/` — **412 pass** (`support/fake_auth.dart`, `render_all_locales_test.dart` locale sweep,
`resume_*`/`job_*`/`applications_*`/`saved_jobs_*`/`career_coach_*`/`cv_*`/`interview_*`/`recommendation*`/`company_*`
tests; **employer jobs** `employer_jobs_{repository,controller,providers,screens}_test` + `job_{posting_model,validation,
editor_controller,detail_view}_test`; **employer applicants (P5·M3)** `application_model_test` (extended),
`applicant_snapshot_test`, `application_note_test`, `applicant_status_flow_test`, `employer_applicants_{repository,
controller,providers,screens}_test`, `employer_notes_{repository,controller}_test`; **employer analytics (P5·M4)**
`analytics_calculator_test`, `employer_analytics_providers_test`, `recruiter_insights_{repository,controller,store}_test`,
`employer_analytics_screen_test`). Widget hosts wrap in the real `AppTheme.light(locale)`; controller tests assert
optimistic rollback via throwing fakes, and the analytics calculator is exhaustively unit-tested (pure, injectable clock).

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
| `cloudStorageServiceProvider` | `CloudStorageService` | Firebase Storage (`users/{uid}/…`) — ready; **bucket not provisioned yet (§7.9)** |
| `userProfileRepositoryProvider` · `userProfileProvider` (Stream) | `UserProfileRepository` (`watchProfile`/`fetchProfile`/`saveProfile`/`ensureProfile`/`setUserType`/`setPhotoUrl`) | `FirestoreUserProfileRepository` (live) ↔ in-memory (tests) |
| `profileImageStorageProvider` | `ProfileImageStorage` | `FirebaseProfileImageStorage` → `CloudStorageService` |
| `notificationPreferencesStoreProvider` | `NotificationPreferencesStore` | local storage → remote/FCM later |
| `cvPdfGeneratorProvider` | `CvPdfGenerator` | `PdfCvGenerator` (`pdf`/`printing`) → Syncfusion fallback |
| `cvEnhancementRepositoryProvider` | `CvEnhancementRepository` | `AiService.generateJson` (Gemini) |
| `cvDraftStoreProvider` | `CvDraftStore` (now in `core/services/cv_store`) | in-memory → Firestore/local |
| `interviewRepositoryProvider` | `InterviewRepository` (generate/evaluate/summarize/streamDebrief) | `AiService` (Gemini) |
| `interviewHistoryRepositoryProvider` · `interviewSessionsProvider` (Stream) | `InterviewHistoryRepository` (`watchSessions`/`saveSession`/`findById`/`delete`) | in-memory → Firestore `users/{uid}/interviews` |
| `recommendationsRepositoryProvider` | `RecommendationsRepository` (`generate`) | `AiService.generateJson` (Gemini) |
| `recommendationsStoreProvider` · `latestRecommendationsProvider` (Stream) | `RecommendationsStore` (`watchLatest`/`read`/`save`/`clear`) | in-memory (latest-only) → Firestore `users/{uid}/recommendations/latest` |
| `companyRepositoryProvider` · `companyProvider` (Stream) | `CompanyRepository` (`watchCompany`/`fetchCompany`/`saveCompany`/`ensureCompany`/`setLogoUrl`) | `FirestoreCompanyRepository` (live, `companies/{companyId}`) ↔ in-memory (tests) |
| `companyLogoStorageProvider` | `CompanyLogoStorage` | `FirebaseCompanyLogoStorage` → `CloudStorageService` (`companies/{id}/logo.jpg`; **bucket unprovisioned**) |
| `employerJobsRepositoryProvider` · `employerJobsProvider` (Stream) | `EmployerJobsRepository` (`watchJobs`/`fetchJob`/`createJob`/`updateJob`) | `FirestoreEmployerJobsRepository` (live, `jobs/{jobId}`, query by `ownerUid`) ↔ in-memory (tests) |
| `employerApplicantsRepositoryProvider` · `employerApplicantsProvider` (Stream) | `EmployerApplicantsRepository` (`watchApplicants(ownerUid)`/`fetchApplicant`/`updateApplication`) | `FirestoreEmployerApplicantsRepository` (live, `applications`, query by `ownerUid`) ↔ in-memory (tests) |
| `employerNotesRepositoryProvider` · `notesForApplicationProvider(id)` (Stream) | `EmployerNotesRepository` (`watchNotes`/`addNote`/`updateNote`/`deleteNote`) | `FirestoreEmployerNotesRepository` (live, owner-private `applicationNotes`) ↔ in-memory (tests) |
| `employerActivityRepositoryProvider` · `employerActivityProvider` (Stream) | `EmployerActivityRepository` (`log`/`watchActivity`) | `FirestoreEmployerActivityRepository` (live, owner-private `employerActivity`; audit foundation) ↔ in-memory (tests) |
| `recruiterInsightsStoreProvider` · `latestRecruiterInsightsProvider` (Stream) | `RecruiterInsightsStore` (`watchLatest`/`read`/`save`/`clear`) | in-memory (latest-only) → Firestore `companies/{companyId}/insights/latest` (P5·M4) |
| `recruiterInsightsRepositoryProvider` | `RecruiterInsightsRepository` (`generate`) | `AiService.generateJson` (Gemini) — reuses the Recommendations pattern (P5·M4) |
| `employerAnalyticsProvider` · `analyticsClockProvider` | `EmployerAnalytics` (computed) | pure `AnalyticsCalculator` over the employer jobs/applicants/activity streams (P5·M4) |

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

**Phase 2 COMPLETE (verified live EN+AR).** **Phase 3 (M1–M3), Phase 4 (M1–M3), and Phase 5 · M1–M4
are COMPLETE** (M1–M3 committed through `d0810d5`; M4 committed this session — see §6, §7.7–§7.16).
`flutter analyze` clean, **412 tests pass**, repo clean (only `.claude/settings.local.json`
intentionally uncommitted). Firebase AI Logic is enabled + provisioned (§5); the
`companies`/`jobs`/`applications`/`applicationNotes`/`employerActivity` Firestore rules are deployed
(M4 added **no** new rules).
**The AI toolkit is complete AND the entire employer side is complete (Company Foundation + Job
Management + Applicants Management + Analytics).** Nothing is in progress — candidate next milestones:
close the seeker→employer loop (Firestore-back the seeker apply + real published jobs), **AI Company
Strength** (`Company.strength` is shaped for it), an employer activity/audit UI, and Firestore-backing
the `RecruiterInsightsStore`.

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
