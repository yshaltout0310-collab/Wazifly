# Wazifly — Technical Audit

**Scope:** the full application source on branch `feature/wazifly-rebrand`, audited
against the working tree — not against prior documentation, which is itself one of
the findings.
**Date:** 2026-09-12 · **Toolchain:** Flutter 3.44.4 (stable), Dart 3.12.2
**Auditor's stance:** every claim below is backed by a command that was run or a
file and line that was read. Where a previous document and the code disagree, the
code wins.

---

## 1. Executive summary

Wazifly is a **large, genuinely well-engineered Flutter codebase** — 352 Dart
files / ~58,500 lines under `lib/`, 127 test files, 696 passing tests, zero
analyzer issues, zero `TODO`/`FIXME` markers, and complete English/Arabic
localization parity. The architectural discipline is real and consistent: every
platform capability sits behind a vendor-neutral interface with a working no-op
fallback, so the app degrades instead of crashing when a backend is missing.

The headline risk is **not** code quality. It is that **the two halves of the
marketplace are not connected to each other**. Job seekers browse a bundled JSON
catalogue and their applications live in RAM; employers publish jobs to Firestore
and read applicants from Firestore. Each side works convincingly on its own, and
neither can see the other. §4.3–§4.4 set this out precisely.

Two web-target defects were found **and fixed during this audit** (§4.1, §4.2);
the web build now compiles and boots, which is what makes the Replit deployment
possible at all.

| Dimension | Assessment |
| --- | --- |
| Architecture & layering | **Strong** — consistent, documented, enforced by the dependency direction |
| Code quality & hygiene | **Strong** — analyzer clean, no dead markers, no secrets, small files |
| Test suite | **Good** — 696 tests, 67.0% line coverage, weakest on newest screens |
| Localization & RTL | **Strong** — 1041/1041 key parity, no hardcoded user-facing strings found |
| Security (rules, secrets, permissions) | **Good, with one latent gap** — §4.5 |
| End-to-end product completeness | **Incomplete** — §4.3, §4.4 |
| Documentation accuracy | **Good** — `SOURCE_CODE_GUIDE.md` is excellent; the release docs had drifted (§4.8) and are now corrected |
| Web / Replit readiness | **Ready** as of this audit (was blocked) |

---

## 2. Evidence baseline

Every command below was run on the audited tree.

| Check | Command | Result |
| --- | --- | --- |
| Static analysis | `flutter analyze` | **No issues found** (24.3 s) |
| Test suite | `flutter test` | **696 passed**, 0 failed |
| Line coverage | `flutter test --coverage` | **67.0%** (12,193 / 18,212 lines, excluding generated localization; 65.4% including it) |
| Web compile | `flutter build web --release` | ✅ green *after* §4.1 — previously **failed** |
| Web runtime | bundle served and opened in a browser | ✅ boots; `[FirebaseService] Initialized: careerbridge-97-f58c9` |
| Secret scan | `grep -rnE "(sk-\|AIza\|secret\|password\s*=)" lib/` | Only `firebase_options.dart` (public client config by design) |
| Debt markers | `grep -rnE "TODO\|FIXME\|HACK\|XXX" lib/` | **0** |
| l10n parity | ARB key diff, EN ↔ AR | **1041 / 1041**, 0 missing either way |
| Hardcoded UI strings | `grep -rnE "Text\(\s*'[A-Z][a-zA-Z ]{3,}" lib/` | **0** matches (heuristic, not exhaustive) |
| Orphaned l10n keys | ARB keys cross-referenced against `lib/` + `test/` | **38** unused (§4.9) |
| Source size | `find lib -name '*.dart'` | 352 files, 58,543 lines |

**Coverage by area** (line coverage, largest areas first):

| Area | Coverage | Area | Coverage |
| --- | --- | --- | --- |
| `shared/models` | 85.9% | `features/jobs` | 51.2% |
| `shared/widgets` | 84.5% | `features/internships` | 35.9% |
| `features/home` | 88.3% | `features/learning` | 26.1% |
| `features/career_coach` | 79.7% | `features/cv_repository` | **20.3%** |
| `features/employer` | 68.0% | `core/services` | 53.4% |

---

## 3. Architecture assessment

### 3.1 What is done well

**Dependency inversion is applied consistently, not decoratively.** Every
external capability — AI, PDF extraction, OCR, storage, analytics, crash
reporting, performance, App Check, connectivity, biometrics, secure storage,
notifications — is an `abstract interface class` in `lib/core/services/<area>/`
with a concrete implementation and a no-op sibling, selected by a single Riverpod
`Provider`. Swapping a vendor is a one-line rebind. This is the single best
property of the codebase and it holds everywhere it is claimed to.

**Failure is designed for.** `main.dart` treats all telemetry as best-effort;
`FirebaseService.initialize()` swallows initialization failure; App Check is
activated *after* `runApp` and deliberately not awaited. The audit confirmed this
empirically: on the web target, Crashlytics, FCM and App Check all fail, all log,
and the app runs normally.

**Feature-first layering with a real boundary.** `domain/` holds contracts and
immutable models with no Flutter or Firebase imports; `data/` holds
implementations; `application/` holds Riverpod `StateNotifier` controllers;
`presentation/` holds widgets that own no business logic. Spot checks across the
résumé analyzer, CV repository, employer and jobs features found no violations.

**Localization is structural, not retrofitted.** 1041 keys, complete parity, RTL
handled per-locale, brand rendered as "وظيفة فلاي" inside Arabic prose while the
wordmark stays Latin. A `render_all_locales_test.dart` renders screens in both
locales.

**Security rules are thoughtfully written.** `firestore.rules` goes beyond
ownership to assert a data contract — identity fields immutable on update, free
text size-capped — and the comments explain *why* each rule is shaped the way it
is, including a note about a past over-strict rule that wedged a live listener.
`storage.rules` explicitly refuses a `users/**` catch-all because Storage grants
on *any* matching rule, which would bypass the content-type caps. That is a
subtlety most codebases get wrong.

### 3.2 Weaknesses

- **Coverage is thinnest exactly where the newest code is.** `features/cv_repository`
  is at 20.3%; `employer_interview_screen.dart` (215 lines) and
  `employer_candidates_screen.dart` (184 lines) are effectively untested (0.5%).
  These are the most recently added, least exercised screens.
- **A few screens are large.** `employer_analytics_screen.dart` (874 lines),
  `interview_prep_screen.dart` (758), `job_editor_screen.dart` (726). Not
  defective, but they concentrate change risk.
- **The `emerald*` colour aliases outlive their meaning.** `AppColors` defines
  `emerald = royalBlue`, `mint = skyBlue`, `deepSea = navy` to avoid churn across
  ~130 call sites during the rebrand. It works, but every future reader now has
  to learn that "emerald" means blue.

---

## 4. Findings

Ranked by impact. Severity is about consequence, not effort.

### 4.1 — `flutter build web` failed to compile · **High** · ✅ **Fixed in this audit**

Six 64-bit integer literals could not be represented in JavaScript:

```
lib/core/services/cv_repository/cv_document.dart:191,193,464,466
lib/shared/models/learning_profile.dart:209,211
    Error: The integer literal 0xcbf29ce484222325 can't be represented exactly in JavaScript.
```

Both files carried a private copy of a 64-bit FNV-1a hash used for CV import
de-duplication and learning-interest ids. The failure was invisible to every
existing gate, because `flutter analyze` and `flutter test` both run on the VM,
where 64-bit integers are fine — only the web compiler rejects them.

**Fixed** by extracting one shared implementation,
[`lib/core/utils/stable_hash.dart`](../lib/core/utils/stable_hash.dart), built
from two independently seeded 32-bit FNV-1a lanes (the second consuming the input
in reverse). Every intermediate stays inside JavaScript's exact-integer range,
and the digest keeps its original 16-hex-character width and ~64-bit collision
resistance. The duplicate copies are gone.

`test/stable_hash_test.dart` was added: it asserts the digest contract and
**scans `lib/` for any reintroduced web-unsafe literal**, so this class of defect
cannot come back silently.

*Known consequence:* digests differ from the previous implementation. A
`contentHash` already stored in Firestore will not match a freshly computed one,
so a CV imported before this change may not be detected as a duplicate if
re-imported. The cost is one missed duplicate prompt; no data is lost.

### 4.2 — The biometric launch gate could strand a returning web user on the splash · **High** · ✅ **Fixed in this audit**

**Scope, stated precisely:** this affects a **returning, signed-in,
email-verified** user on the web only. A first-time web visitor is unaffected —
`_bootstrap()` in `splash_screen.dart` routes to Language before the biometric
gate is reached, which is why the browser run in §2 booted normally.

For a session that gets past onboarding, sign-in and the verification gate,
`_bootstrap()` awaits `biometricSettingsControllerProvider.ensureLoaded()` →
`BiometricService.capability()`. The production binding was unconditionally
`LocalAuthBiometricService`, and **`local_auth` declares no web implementation**
(verified in the package's own `pubspec.yaml`: `android`, `ios`, `macos`,
`windows` only). A method-channel call with no registered implementation raises
`MissingPluginException`, which is **not** a `PlatformException` — and
`capability()` caught only `PlatformException`. The error would therefore escape,
the splash's `await` would never complete, and the app would never navigate.

*Evidence status:* the missing web implementation and the too-narrow `catch` are
**verified by reading the source**; the resulting hang is **reasoned, not
observed** — reproducing it needs a verified account signed in on the web build,
which was outside this audit's scope. The fix is worth having regardless: a
launch-path probe that can throw is a defect on any platform.

**Fixed** two ways, matching the codebase's own conventions:

- `biometric_providers.dart` now binds `NoopBiometricService` when `kIsWeb`,
  mirroring the existing `connectivityServiceProvider`. The feature simply never
  appears on web, which is the correct behaviour.
- `LocalAuthBiometricService.capability()` / `.authenticate()` now catch *any*
  exception rather than only `PlatformException`. This call sits in the launch
  path; it must never throw, on any platform.

Verified after the change: the bundle boots and walks through Language → Country
→ Onboarding → Welcome with branding and both locales intact. The signed-in
re-entry path remains unverified on web (see the evidence note above).

### 4.3 — Job seekers and employers cannot see each other's jobs · **High** · Open

The seeker-side job catalogue is a **bundled JSON asset**, not Firestore:

```dart
// lib/core/services/jobs/seed_jobs_repository.dart:106
final jobsRepositoryProvider = ... SeedJobsRepository()   // assets/data/seed_jobs.json (18 jobs)
```

Browse, search, job detail, AI job matching, recommendations and internships all
read through that provider. Meanwhile the employer's create/edit/publish flow
writes to Firestore via `FirestoreEmployerJobsRepository`
(`lib/core/services/jobs/employer_jobs_repository.dart:33`), governed by the
`jobs/{jobId}` rules.

**Consequence:** a job an employer publishes is visible only on that employer's
own dashboard. No seeker can ever find it. The 18 seeded jobs a seeker sees
belong to no employer account.

This is a defensible *demo* architecture — seeded content guarantees a populated,
bilingual, offline-capable experience — and the code documents it as a seam
("to plug in a live jobs API later, write another `JobsRepository` and rebind").
It is **not** a production marketplace, and any claim that it is would be wrong.

### 4.4 — Job applications never leave the device · **High** · Open

```dart
// lib/core/services/applications/in_memory_applications_repository.dart:83
final applicationsRepositoryProvider = ... InMemoryApplicationsRepository()
```

Applying to a job appends an `Application` to a `List` in memory with an id like
`app_0` and an empty `ownerUid` (`Application.create`'s default). The employer
side reads Firestore (`employer_applicants_repository.dart:32` →
`FirestoreEmployerApplicantsRepository`, query `where('ownerUid', ==, me)`).

**Consequences, all three of which a reviewer will hit within a minute:**

1. A seeker's applications **disappear on app restart**.
2. An application **never reaches the employer** — the two repositories share an
   interface and a model, but not a store.
3. The employer's Applicants dashboard and the hiring-funnel Analytics built on
   it are **empty in practice**, because nothing writes to `applications/`.

The shape of the fix is already in place — the interface, the model, the rules,
and the employer's Firestore reader all exist. What is missing is a
`FirestoreApplicationsRepository` on the seeker side, plus resolving §4.5 first.

### 4.5 — The `applications` create rule does not bind an application to the real job owner · **Medium** · Open (latent)

```
// firestore.rules:107
match /applications/{applicationId} {
  allow create: if signedIn() &&
                   request.resource.data.applicantUid == request.auth.uid;
```

`create` validates only that applicants cannot impersonate each other. It does
**not** check that `ownerUid` and `companyId` match the owner of the referenced
job, does not validate `status`, and applies none of the `capped()` size limits
used on every other collection — so the client-supplied `applicantSnapshot` (the
denormalized name/headline the employer's list renders) is entirely
applicant-controlled.

Any authenticated user could therefore insert arbitrary documents into any
employer's applicant pipeline, with unbounded free text.

**Why this is "latent" rather than live:** nothing currently writes to this
collection from the client (§4.4), so there is no exploit path today. It becomes
live the moment §4.4 is fixed. **Fix §4.5 as part of §4.4, not after it** —
`create` should `get()` the referenced job and require `ownerUid` to equal that
job's `ownerUid`, pin `status` to the initial value, and cap the snapshot fields.

### 4.6 — `README.md` was stale **locally only** · **Low** · ✅ Resolved

*Corrected after the initial audit pass.* The audit was run against the local
working tree, where `README.md` still described **"Phase 1 (Foundation)"** with
*"No job features and no authentication logic yet — by design"*, a
`MockAuthRepository` that "simulates sign-in", sign-in via **Google and
phone+OTP** (both removed), `auth/` as "placeholder only", a roadmap listing
already-shipped work as future, and a `flutter create --org com.careerbridge .`
instruction that would overwrite a configured Android runner.

**None of that was the state of record.** The repository owner had already
rewritten `README.md` directly on GitHub (commit `f420b79`, 2026-07-30), and that
version is accurate — the local branch had simply not fetched it. Raising this as
a Medium finding was an error of method: the local tree was treated as the whole
truth without checking the remote.

**Resolution:** the owner's README is the base. Four additive sections were
merged into it — project status (§4.3/§4.4 disclosure), the quality-gate table,
the web build plus the Replit pointer, and a documentation index. One stray
line left over from the old roadmap was removed. No authored content was
replaced.

*Method note for future audits: fetch and diff against the remote before judging
a document stale.*

### 4.7 — `SOURCE_CODE_GUIDE.md` §19 claims a file that a clone will not have · **Medium** · Open

> "**`android/app/google-services.json`** — included so the Android build works
> out of the box."

The file exists on the developer's disk but is **gitignored and untracked**
(`.gitignore`: `**/android/app/google-services.json`; `git ls-files` returns
nothing). The claim is true of a hand-assembled source archive and false of a
`git clone` — so anyone cloning the repository and running `flutter build apk`
gets a Google-Services Gradle failure with no explanation.

The guide should state that the file must be supplied (from the Firebase console
or the archive) before an Android build, and that only the **web** target works
from a clean clone. This does not affect the Replit deployment, which is web.

### 4.8 — Documentation drift in the release docs · **Low** · Open

- `docs/PRODUCTION_READINESS.md` reports **574 tests**; the suite is now **696**.
  Its §2 "verification evidence" table is therefore stale as a sign-off artifact.
- `docs/QA_CHECKLIST.md` §2 still instructs the tester to verify an **"emerald
  mark"** and the splash colour **`#0B7D57`**. The Wazifly brand on this branch
  is navy `#0B1D3A` with royal blue `#1677FF` (`AppColors`, `pubspec.yaml`,
  `web/manifest.json` all agree). A tester following the checklist literally
  would file a false bug.

### 4.9 — 38 orphaned localization keys · **Low** · Open

38 keys are defined in both ARB files and referenced nowhere in `lib/` or
`test/` — 76 dead string entries. Several are fossils of removed features:
`continueWithPhone`, `phoneAuthTitle`, `phoneAuthSubtitle`,
`authPlaceholderTitle`, `authPlaceholderBody`, `loadingSigningIn`,
`loadingSendingCode`, `loadingCreatingAccount`. Others
(`noteAddedMsg`, `noteDeletedMsg`, `cvExportPdf`, `analyticsRefresh`) suggest
strings written ahead of, or after, the UI that used them.

Harmless at runtime; they inflate the translation surface and mislead anyone
estimating localization effort.

### 4.10 — `--wasm` builds are blocked by a dependency · **Informational**

The web build's dry run reports `flutter_secure_storage_web` using `dart:html`,
`dart:js_util` and `package:js`, none of which are WebAssembly-compatible. This
affects **only** `flutter build web --wasm`; the JavaScript build used for the
Replit deployment is unaffected. `build_web.sh` passes `--no-wasm-dry-run` to
keep the advisory out of build output.

### 4.11 — App Check has no web attestation provider · **Low** (becomes High if enforcement is enabled)

On web, `AppCheckService.activate()` fails (observed:
`[AppCheck] activate failed: TypeError…`) because no reCAPTCHA provider is
registered for the web app. Today this is harmless — enforcement is off and the
failure is caught. If App Check enforcement is ever switched on, **the web
deployment loses Firestore, Storage and AI access entirely.** Enabling
enforcement and registering a web provider must be treated as one change. Carried
into `docs/REPLIT_DEPLOYMENT.md` §5.3.

### 4.12 — Carried-forward known issues (previously recorded, re-confirmed as still open)

- **Release builds are debug-signed** unless `android/key.properties` exists. The
  fallback is deliberate and documented, but the real upload keystore has still
  not been created.
- **Cloud Storage bucket is not provisioned**, so `storage.rules` remain authored
  but undeployed.
- **Home AI-toolkit grid overflows at text scale ≥ 1.8.**
- **Email-verification happy path has never been exercised with a real mailbox** —
  the accounts used in testing are `@cb.app`, which has no inbox.

---

## 5. Security review

| Area | Finding |
| --- | --- |
| Hardcoded secrets | **None.** Only `firebase_options.dart`, whose contents are public client identifiers present in any shipped artifact. Access is protected by rules + App Check, not by hiding the config. |
| Secret hygiene | `google-services.json`, `GoogleService-Info.plist`, `.env*`, `*.jks`, `key.properties` all gitignored and untracked. |
| Android permissions | Exactly three — `INTERNET`, `POST_NOTIFICATIONS`, `USE_BIOMETRIC` — and the advertising ID that `firebase_analytics` would merge in is explicitly stripped. Guarded by `test/android_manifest_test.dart`. |
| Firestore rules | Ownership + identity-field immutability + size caps across 8 collections; default-deny with no fall-through. **One gap: §4.5.** |
| Storage rules | Content-type and size enforced per path; the dangerous `users/**` catch-all is deliberately absent. Not yet deployed (no bucket). |
| Credential storage | `flutter_secure_storage` holds only a biometric preference and a trusted-device marker — never passwords or tokens. Verified by reading `SecureKeys` usage. |
| AI data flow | Résumé text is sent to Gemini through Firebase AI Logic. No API key in the client. Disclosed in the store listing and privacy documents. |
| Audit trail | `SecurityAuditLog` records permission-denied events; `employerActivity` rules are append-only (no update/delete), so the trail cannot be rewritten. |

---

## 6. Work performed during this audit

Code changes were limited to what was required to make the web/Replit target
viable, plus the regression guard for it. No feature behaviour was altered on
Android or iOS.

| Change | Files |
| --- | --- |
| Shared web-safe content hash; removed two duplicated 64-bit implementations | `lib/core/utils/stable_hash.dart` (new), `lib/core/services/cv_repository/cv_document.dart`, `lib/shared/models/learning_profile.dart` |
| Web-safe biometric binding + non-throwing capability probe | `lib/core/services/biometric/biometric_providers.dart`, `lib/core/services/biometric/local_auth_biometric_service.dart` |
| Regression guard for both the digest contract and web-unsafe literals | `test/stable_hash_test.dart` (new) |
| Replit configuration and build/serve scripts | `.replit`, `replit.nix`, `tool/replit/*.sh` |
| Documentation | `README.md` (owner's version kept, four sections added), `SOURCE_CODE_GUIDE.md` (corrected + web section), `docs/TECHNICAL_AUDIT.md`, `docs/JUDGE_BRIEF.md`, `docs/REPLIT_DEPLOYMENT.md` |

Post-change verification: `flutter analyze` clean · **696 tests pass** ·
`flutter build web --release` succeeds · bundle boots in a browser.

---

## 7. Recommendations, in priority order

1. **Decide and state what Wazifly is.** Either wire the marketplace end-to-end
   (§4.3, §4.4, §4.5) or describe the seeded catalogue as an intentional demo
   dataset everywhere the product is presented. The current mismatch between what
   the code does and what the documentation implies is the largest single risk in
   a technical review.
2. **If wiring it up:** implement `FirestoreApplicationsRepository`, rebind
   `applicationsRepositoryProvider`, and **tighten the `applications` create rule
   in the same change** (§4.5). Then make `jobsRepositoryProvider` read published
   Firestore jobs, with the seed asset as a fallback for an empty database.
3. **Fix the remaining documentation claim a reviewer would trip over** — the
   `google-services.json` statement in `SOURCE_CODE_GUIDE.md` §19 (§4.7).
4. **Raise coverage on the newest employer screens** (§3.2); they are the least
   tested and the most recently changed.
5. **Refresh the stale release docs** (§4.8) so the sign-off artifacts match the
   shipped tree.
6. **Before enabling App Check enforcement**, register a web reCAPTCHA provider
   (§4.11).
7. **Housekeeping:** delete the 38 orphaned l10n keys (§4.9).
