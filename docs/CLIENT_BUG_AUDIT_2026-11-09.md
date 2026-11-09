# Wazifly — Client Bug Audit (18 reported issues)

**Date:** 2026-11-09
**Scope:** Audit was read-only. Fixes are landing in the phases listed in §5.
**Rules / App Check / AI / auth configuration / deployment:** untouched throughout.

---

## 0. Implementation status

| Phase | State | Notes |
|---|---|---|
| **1 — Make failure visible (RC-A)** | ✅ **DONE** | See below. |
| **2 — Make publishing work (RC-B)** | ✅ **DONE** | Closes 6, 11. See below. |
| **3 — Make published jobs findable (RC-C)** | ✅ **DONE** | Closes 9. See below. |
| **4 — Auth correctness (RC-F/M/G)** | ✅ **DONE** | Closes 12, 13, 14. See below. |
| **5 — Web load performance (RC-D)** | ✅ **DONE** | Closes 2; 1 improved, one decision open. See below. |
| **6 — Registration & company profile (RC-E)** | ✅ **DONE** | Closes 3; 17 improved, remainder below. |
| **7 — Discoverability & dashboard (RC-K/J)** | ✅ **DONE** | Closes 8, 15. See below. |
| 8 — Multi-account hygiene (RC-H) | ⬜ Not started | |
| 9 — Email deliverability (RC-I) | ⬜ Not started | Owner/Console-side; no code |

### Phase 1 — what landed

**New seam:** `lib/core/services/firebase/firestore_stream.dart` — a
`Stream<T>.logAndForwardErrors(tag, {onError})` extension that keeps the log and
the security-audit hook but **re-emits the error downstream** via an explicit
`StreamTransformer` sink.

**All 9 repositories converted** off `.handleError` (jobs, applications,
employer applicants, company, CVs, notes, activity, learning, user profile).
`.handleError` no longer appears anywhere in `lib/`.

**Error states added** to the screens that had none — `employer_jobs_screen`,
`employer_applicants_screen`, `employer_analytics_screen`, `cv_library_screen` —
each `StatusView.error` + Retry (`ref.invalidate`), guarded so a cached or
optimistic list is never replaced by a state screen. `applications_screen`
already had an error branch that was **unreachable dead code**; it now works,
and its message was corrected from `jobsLoadError` ("Couldn't load jobs") to the
new generic `commonLoadError`.

**One new l10n key:** `commonLoadError` (EN + AR), regenerated.

**Validation:** `flutter analyze` clean · **753 tests pass** (744 baseline + 9
new) · zero regressions. New tests: `test/firestore_stream_test.dart` (forwards
the error, preserves the stack trace, fires the audit hook, passes data through,
survives a non-terminal error, **plus a source guard that fails if any `lib/`
file reintroduces `.handleError`**) and `test/stream_error_states_test.dart`
(Manage Jobs and Applicants render a retryable error and **no** spinner; a
healthy empty stream still shows the empty state).

**Not verified live:** the Firestore-emulator denial sweep described in §5 was
not run, and no web build was deployed. The behaviour is proven by the widget
tests above, which assert the same contract deterministically.

**Expected side effect:** pre-existing backend failures that used to hang
silently will now surface as visible errors. That is the intent, but it may
produce a second, smaller round of findings.

### Phase 2 — what landed

**The editor's Publish now publishes.** `job_editor_screen._onPublish` validates,
saves the edits, confirms in place, then calls `EmployerJobsController.publish`.
It previously saved a *draft* and navigated to Preview. An already-published
posting has no legal transition to `published`, so for that case saving the
edits *is* the publish and it says so.

**`JobAction.publish` is separated from `JobAction.preview`.** The two shared one
`switch` case that only navigated. Publish now confirms and transitions in
place; Preview remains its own action and only previews.

**Publishing is gated on `JobValidator.forPublish`.** The list and detail menus
reach the publish action without passing through the editor, so making it work
directly would otherwise have allowed one-tap publishing of a posting with no
description, skills, experience, employment type or location. An incomplete
draft now gets `jobErrFixFields` and is routed to the editor. The Preview
screen's CTA is gated the same way — `JobPosting.isPublishable` only checks
status, so on its own it offered to publish empty drafts.

**`_transition` no longer fails silently.** `if (!canTransitionTo) return;` is
replaced by a new `JobsActionFailure.staleStatus` ("This job's status has
changed. Refresh and try again."), so a posting that moved under the UI reports
instead of presenting a dead button. New l10n key `jobErrStaleStatus` (EN + AR).

**Validation:** `flutter analyze` clean · **758 tests pass** (+5 new) · zero
regressions. `test/job_publish_action_test.dart` asserts: the editor's Publish
leaves the posting `published` and never routes through Preview; the menu action
publishes directly; an incomplete draft stays a draft and lands in the editor;
Preview still only previews; and an illegal transition sets `staleStatus`.

**Scope note — what Phase 2 does *not* finish.** Issue 9 is only half-closed:
postings now reach `status: "published"`, but Browse still hides them behind the
default Qatar location filter (RC-C → Phase 3). Issue 15 likewise: the Active
Jobs / Applications / Interviews / Hires counts become real, but the four cards
are still non-interactive (RC-J → Phase 7).

**Not verified live:** no device or web run. Covered by the widget tests above.

### Phase 3 — what landed

**Browse now opens with no location filter** (`jobs_browse_controller._load`).
It previously defaulted the filter to `CountriesData.defaultCountry` ("Qatar").

The owner decided this after the following measurement, which is worth keeping:
the Qatar default was **not** a harmless home-market convenience. Because the
match is a case-insensitive *substring* test against the job's `location`
string, and remote jobs bypass it, the default hid:

* **5 of the 18 bundled demo jobs** — Android Developer (Riyadh), Junior Flutter
  Developer (Amman), iOS Developer (Dubai), UX Design Intern (Dubai), Marketing
  Intern (Riyadh); every non-remote role outside Qatar, two of them internships.
* **Every real posting outside Qatar**, and also any posting whose location
  simply omits the word — a job located `"Doha"` does not contain `"Qatar"`.

Nothing in the UI indicated a filter was on, and `clearFilters` re-applied it,
so a seeker could not have escaped it even deliberately.

**`clearFilters()` now clears the country.** It used to re-apply the Qatar
default, making the one filter the seeker never set also the one the "Clear
filters" button could not clear.

**The filter badge now counts the country.** `jobs_screen`'s
`activeFilterCount` summed employment types, seniorities and remote-only but
omitted `location`, so while the hidden default was active the badge read zero.

**Dropped a redundant fetch.** `_load` called `fetchJobs()` and then
`searchJobs()`, which is `applyJobQuery(await fetchJobs(), query)` — two full
catalogue reads on every Browse open. It now filters the list it already has.

**Deliberately unchanged:** the Qatar market context the AI features pass into
their prompts (Career Coach, Interview Prep, Job Matching, job detail). That is
prompt context, not a filter that hides data, and it is a separate concern from
this issue.

**Validation:** `flutter analyze` clean · **759 tests pass** · zero regressions.
Three tests in `test/jobs_browse_controller_test.dart` asserted the old default
and were **rewritten, not deleted** — they now assert that Browse opens
unfiltered, that it ignores the persisted onboarding country, and that
`clearFilters` clears the country. A fourth was added for the reported symptom
directly: a job outside Qatar is findable by text search on first load, with no
filter touched.

**Not verified live:** no device or web run.

### Phase 4 — what landed

**Issue 12 — sign-in no longer applies a creation-time rule.** One validator
served both modes in `email_auth_screen`, returning `passwordTooShort` for any
password under six characters. Because `_submit` runs
`_formKey.currentState!.validate()` before anything else, a *wrong* password
shorter than six was rejected locally: the user was told it was too short and
the credentials check never ran. Sign-in now only requires a non-empty value;
the strength rule applies to sign-**up** only.

**Issue 13 — the requirements are stated up front.** New
`lib/core/utils/password_policy.dart` is the single definition of the rules
(**minimum 8 characters, a letter, a number**), and a new
`PasswordRequirements` widget renders a live checklist *from that same object*,
so what the user is shown cannot drift from what is enforced. It appears on
sign-up and on Change password, never on sign-in.

> ⚠️ **This changes what passwords are accepted.** The previous rule was six
> characters with no composition requirement, hard-coded separately in
> `email_auth_screen` and `ChangePasswordController`. Eight-plus-letter-plus-digit
> is a deliberate strengthening, not a like-for-like port: a platform holding
> CVs and contact details should not accept a six-character password. It affects
> **new sign-ups and voluntary password changes only** — existing users are
> unaffected when signing in, since sign-in no longer checks composition at all.
> It is a one-line change in `PasswordPolicy` if you want it looser.
>
> **The policy of record is: minimum 8 characters, at least one letter, at least
> one number.** No Firebase Console setting was changed as part of this phase —
> backend policy alignment (Authentication → Settings → Password policy) is
> tracked separately by the owner. Until then the client is the stricter of the
> two, which is safe: where the two disagree Firebase still has the last word,
> rejecting with `weak-password`, which already maps to a localized message.
>
> The rules are **Unicode-aware** (`\p{L}` / `\p{Nd}`): an Arabic password
> written in Arabic letters and Arabic-Indic digits satisfies "a letter" and "a
> number", which `[A-Za-z]` / `\d` would have silently rejected in an app that
> ships Arabic. Length counts code points, not UTF-16 units.

Stale copy stating "6 characters" was corrected in EN and AR
(`changePasswordTooShort`, `errWeakPassword`).

**Issue 14 — sign-in costs one profile read instead of three.** `goAfterAuth`
awaited `ensureProfile` (a `get`, then a `set`) and then
`_resolveUserType(trustCache: false)`, whose `fetchProfile` issued a **third**
round trip to re-read the document it had just written — all sequential, all
before the first navigation. `ensureProfile` now returns the profile it already
read (its contract documents that this is the pre-write state, which is exactly
what the caller needs, since the role is never written there), and
`goAfterAuth` takes the role from that. `_resolveUserType` had only one caller
and one argument value left, so its `trustCache` parameter was removed rather
than left as dead configuration.

**Validation:** `flutter analyze` clean · **772 tests pass** (+13 new) · zero
regressions, no existing test needed changing. New: `password_policy_test.dart`
(rules, display order, Unicode, code-point length), `email_auth_validation_test.dart`
(a short wrong password **reaches** the backend and reports bad credentials; no
checklist on sign-in; sign-up states the rules before any typing and blocks a
weak password without calling the backend; a compliant one goes through), and
`auth_navigation_round_trips_test.dart` (seeker and employer sign-in each read
the profile exactly once and `fetchProfile` is never called; a new account still
reaches role selection; a stale cached role never overrides the stored one).
The round-trip counts are asserted because the cost is invisible in behaviour —
the old code navigated to the same place, just later.

**Not verified live:** no device or web run.

### Phase 5 — what landed

**The first frame is no longer hostage to a browser prompt.** `main` awaits
`FirebaseService.initialize()` before `runApp`, and that awaited
`FirebaseNotificationService.initialize()`, which awaits `requestPermission()`.
On web that is the browser's own notification prompt, and it **does not resolve
until the visitor answers it** — so anyone who ignored the prompt never got a
first frame at all, just a blank page, for as long as the tab stayed open.
Messaging now starts after `runApp`, un-awaited, and
`notificationServiceProvider` returns the no-op implementation on web (browser
push needs a `firebase-messaging-sw.js` and a VAPID key, neither of which this
app ships, so the real one could only fail). Mirrors `biometricServiceProvider`.

**`web/index.html` paints something immediately.** It had an empty `<body>`, so
until Flutter's first frame the page was blank white for the entire
multi-megabyte download — indistinguishable from a broken site, and the single
largest contributor to "takes too long to load". There is now an inline
gradient placeholder (matching `SplashScreen`) with a spinner, removed on
`flutter-first-frame`. Inline only — no extra request. Costs ~2 KB.

**The splash no longer adds 2.4 s on web.** `AppDurations.splash` is 600 ms on
web and unchanged at 2,400 ms on native, where the splash is the first thing
that happens rather than an addition to a download already endured.

**Issue 2 — the country list.** `country_selection_screen` staggered 71 rows by
`25 * index`, so the last row only began appearing at **1,750 ms**, and because
the list builds lazily, scrolling re-triggered ever-longer delays and rows
showed up blank. The stagger is now capped at index 8 (200 ms). "Country
selection is slow" was an animation schedule, not a slow load — there is no
network call in that screen at all; `CountriesData.all` is a `const` list.

#### Measured, from a real release build

| | |
|---|---|
| Visitor-fetched payload | **~13.4 MB** — `main.dart.js` 6.17 MB + `canvaskit/chromium/canvaskit.wasm` 5.63 MB + Inter 856 KB + Cairo 586 KB |
| Shipped to the host | **46 MB** |

Phase 5 changes *time to usable*, not bytes: the payload is essentially
unchanged. Two findings about the bytes:

* **`--no-web-resources-cdn` was removed** — see "CanvasKit moved to gstatic"
  below, including a correction to what this was first predicted to save.
* **Both fonts are always fetched** (1.44 MB) even in English. `AppTypography`
  already selects by locale; CanvasKit preloads everything in
  `FontManifest.json` regardless. Avoiding it means removing Cairo from
  `pubspec` and loading it at runtime via `FontLoader`. **Deliberately not
  done**: 586 KB against the risk of breaking Arabic rendering is a bad trade.

#### CanvasKit moved to gstatic (`--no-web-resources-cdn` removed)

`tool/replit/build_web.sh` no longer passes the flag, so CanvasKit is fetched
from `https://www.gstatic.com/flutter-canvaskit/<engineRevision>/chromium/`
(Flutter's default) instead of from our own host.

**Verified in a real browser** against a local release build:

| | |
|---|---|
| CanvasKit source | `www.gstatic.com/flutter-canvaskit/a10d8ac…/chromium/canvaskit.{wasm,js}` |
| Fetched from our origin | **none** — zero `canvaskit` requests to the app's host |
| Bytes from our origin | **7,723 KB**, down from ~13,261 KB |
| Console errors | **none** |
| Rendering | English and Arabic both correct; RTL mirrored (title, back arrow, list rows, flags); Cairo glyphs correct |

> ⚠️ **Correction — two earlier claims in this document were wrong.**
>
> 1. "**~28 MB of the 46 MB is downloaded by nobody** … dropping the flag would
>    remove it." **Wrong.** Measured both ways, `build/web` is **45.7 MB in 44
>    files either way**: Flutter 3.44 copies the CanvasKit artifacts into the
>    build output regardless. The flag only sets `useLocalCanvasKit: true` in
>    `flutter_bootstrap.js`'s `buildConfig`, which changes the **runtime URL**,
>    not what is copied. **Deployment size is unchanged.**
> 2. "**a ~42% cut**" to the visitor payload. **Overstated.** A cold visitor
>    still downloads roughly the same total (~13.4 MB); 5.63 MB of it simply
>    comes from gstatic rather than from the Replit static host.
>
> The real, measured benefit is narrower than first described: **our origin
> serves 7.5 MB instead of 13.3 MB**, and the CanvasKit half comes from a CDN
> that is faster than the static host and shared by every Flutter web app on
> the same engine revision, so it is often already in the visitor's HTTP cache.
>
> The trade the original flag existed to avoid is now live: on a network that
> blocks or throttles `gstatic.com`, the app will not render at all.
> **Rollback is one line** — re-add `--no-web-resources-cdn \` to the
> `flutter build web` invocation in `tool/replit/build_web.sh`, or revert that
> commit. Nothing else depends on the choice.

Two incidental findings from the same run, both pre-existing:

* CanvasKit fetches fallback fonts from `fonts.gstatic.com` at runtime (Roboto
  62 KB, Noto Sans Arabic 65 KB) regardless of
  `GoogleFonts.config.allowRuntimeFetching = false`, which governs the
  `google_fonts` package, not the engine.
* `firebase_crashlytics` logs `MissingPluginException` on web (it has no web
  implementation). Harmless — every call is best-effort and already caught.

#### ⚠️ Correction to §1.4 of this audit

§1.4 recorded "**Service workers registered: `[]` — none**" and §3 proposed
re-enabling the Flutter service worker. The observation was right; the proposed
fix is **not possible**. The deployed `flutter_service_worker.js` is 815 bytes
and calls `self.registration.unregister()` on activate: Flutter 3.44 has
deprecated and neutered its service worker, and the generated
`flutter_bootstrap.js` says so in a comment. There is no app-level caching to
re-enable.

Repeat-visit caching therefore depends entirely on **HTTP cache headers from
the static host**. That is an ops item on the Replit deployment, not a code
change, and it is the single biggest remaining lever on repeat loads.

**Validation:** `flutter analyze` clean · **778 tests pass** (+6) ·
`flutter build web --release` succeeds and the placeholder is present in the
built `index.html`. New `test/web_startup_test.dart` guards the parts a widget
test cannot reach: tests run on the VM where `kIsWeb` is false, and "the first
frame never arrives because a permission prompt is being awaited" only exists in
a browser. It asserts `FirebaseService` no longer references messaging, the
provider no-ops on web, the placeholder exists / is removed on first frame /
needs no request of its own, and that the **native** splash duration is
unchanged.

#### Phase 5 — still unverified, must be checked on the deployment

A local release build **cannot** exercise these, so they are explicitly open:

| Item | Why it could not be verified here |
|---|---|
| App Check | Needs the real `RECAPTCHA_SITE_KEY`, which is a Replit secret and never committed. The local build used a placeholder, so the client is unattested by construction. |
| AI features | Denied while unattested — App Check enforcement is required for Firebase AI Logic. Nothing about the AI path was changed in this phase. |
| Firebase Auth, Firestore | Need real credentials. None are available here, and the assistant must not create accounts or enter passwords. |
| First-paint timing | Needs the bundle on the real host; the built-in browser cannot open a server started locally, and localhost timings would not represent Replit static anyway. |

What *was* verified in a real browser: CanvasKit's source and the absence of any
local CanvasKit request, bytes served from our own origin, English and Arabic
rendering with RTL, the capped country-list stagger (rows at index ~30–40 fully
visible within 1 s of scrolling), removal of the first-paint placeholder once
Flutter paints, and a clean console.

### Phase 6 — what landed

**Sign-up collects a full name and a phone number.** It asked for email and
password only, which is issue 3 — and the cause of most of issue 17.

Two things found while tracing shaped the design:

* **Sign-up never created a profile at all.** `_submit` calls
  `registerWithEmail` and routes straight to the verify-email gate; it never
  reaches `goAfterAuth`, so `ensureProfile` only ran on the first *sign-in
  after verification*. The collected details would have had nowhere to live in
  between — and the user may verify on a different device. They are therefore
  persisted at registration.
* **`UserProfile` had no phone field**, yet `ensureProfile` has been writing
  `phoneNumber` to Firestore all along (from Auth). It was write-only: stored,
  never parsed back. The field now exists, so an existing user with a linked
  phone gains it with no migration.

**Where each value goes, and why.**

| Value | Destination |
|---|---|
| Full name | Firebase Auth `displayName`, set **before** the returned `AppUser` is built, then `users/{uid}.displayName` via `ensureProfile` |
| Phone | `users/{uid}.phoneNumber` only, via a new focused `setPhoneNumber` setter |

Setting the Auth display name at creation is what makes the Company Profile fix
work: both `ensureProfile` and `ensureCompany` seed from `user.displayName`, so
populating it once fixes the downstream emptiness rather than patching each
consumer. The phone is deliberately **not** promoted to Auth's own
`phoneNumber`, which Firebase reserves for a number verified by SMS and linked
to the account — conflating the two would make an unverified number look
verified. The setter mirrors the existing `setUserType` / `setPhotoUrl` seams.

**The 120-character name cap matches `firestore.rules`.** The `users/{uid}` rule
asserts `capped('displayName', 120)`, and `saveProfile`/`ensureProfile` swallow
write failures — so a longer name would be rejected by the backend and lost
silently. The validator now agrees with the rule. **The rule itself was not
touched.**

**`DialCodeBox` extracted** from `phone_verification_screen` into
`features/auth/presentation/widgets/` rather than duplicated, so sign-up and
phone verification share one control — including its RTL handling (`+974` is
forced LTR so the leading `+` is not reordered in Arabic), which is exactly what
a copy loses.

**New rules live in `core/utils/contact_details.dart`** (`FullNamePolicy`,
`PhonePolicy`), pure and unit-tested, for the same reason as `PasswordPolicy`:
the rules are enforced in a form and must not drift from what is validated.
Phone validation is deliberately lenient — 6–14 national digits, stored as
E.164 with the selected country's dial code. A stricter per-country rule would
reject legitimate foreign numbers, a worse failure than accepting an unusual
one, and nothing here proves ownership.

**Existing users are unaffected.** Sign-in still shows two fields and applies no
new rules (asserted by a test). Completion percentages are unchanged:
`phoneNumber` is deliberately **excluded** from `missingFields`/`completion`,
because adding an eleventh tracked field would move every existing user's
percentage — a separate decision from collecting the number.

**Google sign-in:** there is none to break. It was removed in an earlier
milestone — `AuthMethod` is `{email, phone}` and `lib/features/auth/` contains
no Google references. Verified, not assumed.

**Open decision:** phone is **required**. Making it optional is a two-line
change (`_validatePhone` returns null when empty; `PhonePolicy.compose` already
returns null for unusable input, so persistence needs no change).

**Issue 17 — improved, not fully closed.** The company name now populates,
because `ensureCompany` finally has a `displayName` to seed from. Still
outstanding from the original proposal: an explicit "complete your company
profile" empty state with a CTA to Edit Company, and letting `ensureCompany`
surface its failures instead of swallowing them.

**Validation:** `flutter analyze` clean · **791 tests pass** (+13) · rules, App
Check, AI configuration and `.replit` untouched. New
`test/registration_profile_test.dart` covers successful registration (name to
Auth *and* profile, phone stored as `+97450123456`), name normalization, missing
name, a name with no letters, missing phone, too-short and too-long phone,
sign-in showing neither new field, `ensureCompany` seeding the company name, and
the two policies directly. Four Phase 4 tests were updated — the screen now
depends on `localStorageProvider` and the profile repository, and sign-up has
four fields — asserting the same things through the new form.

**Not verified live:** no device or web run.

### Phase 7 — what landed

**Issue 15 — the dashboard cards act.** `_StatTile` was a plain `Container`:
no `InkWell`, no `onTap`, no gesture handling of any kind, sitting beside cards
that *were* tappable — which is why they read as broken rather than as labels.
Each now opens the list it counts, pre-filtered:

| Card | Opens |
|---|---|
| Active jobs | My Jobs, filtered to `published` |
| Applications | Applicants, no status filter |
| Interviews | Applicants, filtered to the `interview` stage |
| Hires | Applicants, filtered to `accepted` |

Both filter controllers gained `showOnly(Set<…>)`. `clear()` + `toggleStatus()`
would have worked but reads as a toggle and depends on current state; `showOnly`
states the intended result, is idempotent, and also clears a stale search so a
list opened from the dashboard is never silently narrowed by a previous query.

> **Known, deliberate difference on Interviews.** The *count* is a funnel
> metric — applicants who ever reached the interview stage, including those
> since hired — while the *list* shows who is at that stage now, so the list can
> be shorter than the number. The funnel count is the right dashboard metric
> (otherwise Interviews could read lower than Hires), and "who is interviewing
> now" is the right list to act on. The missing people appear under Hires.
> Flagged rather than silently reconciled: changing either side is a product
> decision.

**Issue 8 — CV upload is discoverable.** Uploading already worked, via
`file_selector` in three places, but every surface was named after the AI
feature that used it ("Resume Analyzer", "CV Builder", "My CVs"), so the
capability read as absent. Home now carries an **"Upload your CV"** action named
for the task, and the CV library's empty state leads with **Import CV** (Create
stays one tap away, and the FAB still offers both). No new picker code — the
existing import path is reused.

**Stat tiles are now keyed** (`employerStat_<id>`). Their labels are not unique
on that screen — an AI tool card is also called "Interviews" — so the keys make
the four individually addressable for tests and for any future deep link.

**Validation:** `flutter analyze` clean · **799 tests pass** (+8) ·
`test/dashboard_and_upload_test.dart` asserts each card's destination *and* the
resulting filter, that all four are tappable, that `showOnly` replaces rather
than toggles and drops a stale search, and that Home's upload entry exists and
routes to the CV library.

#### Incidental finding, ruled out

A `RenderFlex overflowed by 4.7 pixels` appeared in the Home AI-toolkit grid
while writing these tests. **Probed with and without this phase's change at the
same surface size: zero overflows either way.** It was an artifact of the test
harness (`MaterialApp.router` + `pumpAndSettle`), not a regression and not a
live defect — the existing Home render test uses an 800-wide surface, which this
test now matches. The separately-known overflow at font scale ≥ 1.8 is
unaffected and still open.

**Not verified live:** no device or web run.

---

## 1. Repository state

### 1.1 Local

| | |
|---|---|
| Path | `C:\project\CareerBridge` |
| Branch | `feature/wazifly-rebrand` |
| Commit | `40cae57e206bbd08c8017d40ea84fd99f25473e1` (`40cae57`) |
| Subject | *fix(ai): attest Firebase AI Logic requests with App Check* |
| Date | 2026-11-03 23:28:28 +0300 |
| Working tree | Clean except one untracked file: `WAZIFLY_DEBUG_HANDOFF.md` |
| Sync | **In sync** with `origin/feature/wazifly-rebrand` |

### 1.2 GitHub (`github.com/yshaltout0310-collab/Wazifly`)

After `git fetch --all --prune`:

| Ref | Commit | Relationship to local |
|---|---|---|
| `origin/feature/wazifly-rebrand` | `40cae57` | **Identical to local HEAD** (default branch; `origin/HEAD` → this) |
| `origin/main` | `e5ecf38` | Stale (pre-rebrand) |
| `origin/replit-backup-2026-11-03` | `11a1f97` | **Diverged** — see below |

`origin/feature/resume-analyzer` was deleted upstream and pruned during this audit.

### 1.3 Replit source vs. local — they are **not** identical

Merge base is `68ddc90`. The two lines diverged there:

* Local has **1** commit the Replit branch lacks: `40cae57`.
* The Replit branch has **8** commits local lacks: `11a1f97`, `b748e66`, `79e82fd`, `1bc9828`, `f9c9478`, `80ca9f3`, `f8b8afe`, `fd3dbd3`.

**The divergence is confined to the AI / App Check / web-bootstrap layer.** The full changed-file list (40 files) covers only:

* `lib/core/services/ai/**`, `lib/core/services/app_check/**`, `lib/core/services/firebase/firebase_service.dart`, `lib/core/services/service_diagnostics.dart`
* `lib/features/resume_analyzer/**`, `lib/features/splash/presentation/splash_screen.dart`, `lib/features/language_selection/.../language_tile.dart`
* `lib/main.dart`, localization `.arb` + generated files
* `docs/**`, `README.md`, `replit.md`, `.replit`, `.agents/memory/**`, `tool/replit/**`, `test/**`

> **Critical for this audit:** **not one** file under `lib/features/auth/`, `lib/features/employer/`, `lib/features/jobs/`, `lib/features/applications/`, `lib/core/services/jobs/`, `lib/core/services/applications/`, or `lib/core/services/company/` differs between local HEAD and the deployed Replit source. Neither do `firestore.rules`, `storage.rules`, or `firestore.indexes.json`.
>
> **Therefore every finding below applies equally to the deployed build.** The only area where "which tree is it?" matters is AI/App Check — and that area is explicitly out of scope for changes.

⚠️ **Do not merge the two branches casually.** `40cae57` (local) and `11a1f97` (Replit) are *two different solutions to the same App Check attestation problem* — local routes through `firebase_ai_client.attestedGoogleAi()`, Replit through `ai_request_guard.dart` + `service_diagnostics.dart`. Merging them blindly is the single most likely way to regress working AI.

### 1.4 What is verifiable about the deployed app

Observed live at `https://wazifly.replit.app` (read-only page load + browser performance API; no sign-in, no writes):

| Observation | Value | Meaning |
|---|---|---|
| Total first-load transfer | **13,861 KB (13.9 MB)** | Measured, not estimated |
| `main.dart.js` | 6,184 KB / 1,941 ms | Release Dart bundle |
| `canvaskit/chromium/canvaskit.wasm` | 5,626 KB / 1,566 ms | Served **from own origin** → confirms `--no-web-resources-cdn` is live |
| `assets/fonts/Inter.ttf` | 856 KB | Loaded unconditionally |
| `assets/fonts/Cairo.ttf` | 586 KB | Loaded unconditionally, **even in English** |
| `recaptcha__en.js` (gstatic) | 351 KB | **App Check reCAPTCHA Enterprise is live and loading** |
| Service workers registered | **`[]` — none** | No `flutter_service_worker.js`, no `firebase-messaging-sw.js` |
| `domContentLoaded` / `loadEvent` | 1,188 ms / 2,223 ms | On a fast desktop link; then Flutter boots on top |
| DOM text content | **empty** | CanvasKit renders to `<canvas>`; also means no SEO and no screen-reader tree |
| Landing route | `#/language` | Onboarding gate, as designed |

Not verifiable without Console/credential access (and deliberately not attempted): whether the deployed `firestore.rules` match the repo copy, actual Firestore/App Check enforcement state, and Auth email-template configuration.

---

## 2. Root-cause groups

Twelve distinct causes explain all 18 reports. Several reports share one cause.

| ID | Root cause | Reports |
|---|---|---|
| **RC-A** | Firestore streams swallow errors → `StreamProvider` stuck in `AsyncLoading` forever | 7, 10, 11, 16, 17 |
| **RC-B** | "Publish" never publishes — postings stay `draft` | 6, 9, 11, 15 |
| **RC-C** | Hidden default location filter (`Qatar`) hides real postings | 9 |
| **RC-D** | 13.9 MB web payload + startup blocked on Firebase/FCM + 2.4 s splash | 1, 2, 14 |
| **RC-E** | Registration collects only email + password | 3, 17 |
| **RC-F** | Sign-in form applies a *creation-time* password rule | 12 |
| **RC-G** | Three sequential Firestore round-trips after every sign-in | 14 |
| **RC-H** | Device-global role cache + per-origin Auth session on a shared web origin | 16, 18 |
| **RC-I** | Default Firebase email sender/template (Console-side) | 4, 5 |
| **RC-J** | Dashboard stat cards are non-interactive by design | 15 |
| **RC-K** | CV upload exists but is not discoverable as "upload a CV" | 8 |
| **RC-L** | 71-item staggered list animation (25 ms × index) | 2 |
| **RC-M** | No password-requirement affordance | 13 |

### RC-A in detail — the single highest-value defect

Nine Firestore repositories end their `.snapshots()` pipeline with:

```dart
.handleError((Object e) {
  debugPrint('[...] failed: $e');
});
```

Dart's `Stream.handleError`, called with a handler and no `test`, **consumes the error and does not forward it**. A Firestore `snapshots()` stream *terminates* on error. So the mapped stream closes having emitted **no value and no error** — and a Riverpod `StreamProvider` that has received neither stays `AsyncLoading` **permanently**.

Affected (all 9 share the pattern):
`firestore_employer_jobs_repository.dart` · `firestore_employer_applicants_repository.dart` · `firestore_applications_repository.dart` · `firestore_company_repository.dart` · `firestore_cv_repository.dart` · `firestore_employer_notes_repository.dart` · `firestore_employer_activity_repository.dart` · `firestore_learning_profile_repository.dart` · `firestore_user_profile_repository.dart`

The consuming screens then have no way to recover:

* [`employer_jobs_screen.dart:77`](../lib/features/employer/presentation/employer_jobs_screen.dart) — `async.isLoading && !anyJobs ? CircularProgressIndicator() : …`. **No `hasError` branch exists.**
* [`employer_applicants_screen.dart:107`](../lib/features/employer/presentation/employer_applicants_screen.dart) — same shape, same gap.
* [`applications_screen.dart:97-100`](../lib/features/applications/presentation/applications_screen.dart) — *does* have `if (async.hasError && total == 0)`, but it is **unreachable dead code**, because the repository already ate the error.

Any backend hiccup — a rules denial, an App Check rejection, an offline cold cache, or Firestore web persistence failing in a second browser tab — therefore presents to the user as a spinner that never ends, and produces no user-visible diagnostic. This is why issues 7, 10 and 11 all read as "loads indefinitely".

### RC-B in detail — why nothing ever gets published

Two independent code paths both labelled "Publish", neither of which publishes:

1. [`job_editor_screen.dart:244`](../lib/features/employer/presentation/job_editor_screen.dart) — `_onPublish()` validates, calls `saveDraft()` (persisting `status: draft`), then `context.pushNamed(RouteNames.jobPreview, …)`. The button carries `l10n.jobPublish` and `Icons.publish_rounded`.
2. [`job_action_handler.dart`](../lib/features/employer/presentation/job_action_handler.dart) — `case JobAction.publish:` **falls through** to `case JobAction.preview:` and only navigates:
   ```dart
   case JobAction.preview:
   case JobAction.publish:
     // Publishing is confirmed on the preview screen (how seekers see it).
     context.pushNamed(RouteNames.jobPreview, extra: job);
   ```

The *only* place that actually transitions status is `job_preview_screen._confirmAndPublish` → `EmployerJobsController.publish()`. An employer who taps "Publish" and does not then scroll to the Preview screen's bottom bar **and** confirm the dialog ends up with a **draft**.

This is exactly the client's issue 6 — and it cascades:

* Issue 11 / 7 ("no published jobs in Manage Jobs") — because they are drafts.
* Issue 9 ("seekers can't find them") — `FirestoreJobsRepository` queries `where('status', == 'published')` only.
* Issue 15 ("Active Jobs card shows nothing") — `companyStatsProvider` counts `status == JobStatus.published`.

Note also `EmployerJobsController._transition` opens with `if (!job.status.canTransitionTo(next)) return;` — a **silent no-op**. An already-published or archived job tapped via "Publish" returns with no feedback at all.

### RC-C in detail — the invisible Qatar filter

[`jobs_browse_controller.dart:84`](../lib/features/jobs/application/jobs_browse_controller.dart):

```dart
final query = _withLocation(state.query, CountriesData.defaultCountry.name); // "Qatar"
```

`applyJobQuery` then drops any job that is **not remote** and whose `location` string does not contain `"qatar"` (case-insensitive substring). `JobPosting.toJob()` passes the employer's typed `location` through verbatim.

So a real posting located `"Doha"`, `"Cairo"`, `"Dubai"`, or left blank is **silently filtered out of Browse and search**, with no visible filter chip explaining why.

Worse, `clearFilters()` (lines 115-119) **re-applies** the Qatar default:

```dart
void clearFilters() {
  // Keep the text; drop the other filters but restore the Qatar default.
  _apply(_withLocation(JobQuery(text: state.query.text), CountriesData.defaultCountry.name));
}
```

The user *can* escape it via the filter sheet's "All countries" dropdown item, but "Clear filters" will not do it.

---

## 3. Issue-by-issue table

Severity: **S1** blocks a core flow · **S2** major degradation · **S3** quality/UX · **S4** cosmetic.
Type: **Defect** (broken) · **Missing** (never built) · **Design** (works as coded, contradicts expectation) · **Infra** (Console/hosting, not code).

| # | Feature / screen | Key files | Root cause — confirmed vs. hypothesis | Sev | Type | Proposed fix | Depends on | How to test |
|---|---|---|---|---|---|---|---|---|
| 1 | Web first load | `tool/replit/build_web.sh`, `web/index.html`, `lib/main.dart`, `firebase_notification_service.dart`, `app_dimensions.dart:36` | **CONFIRMED (measured live).** 13.9 MB payload: `main.dart.js` 6.2 MB + bundled `canvaskit.wasm` 5.6 MB (`--no-web-resources-cdn`) + Inter 856 KB + Cairo 586 KB. **No service worker** → zero repeat-visit caching. `web/index.html` has no loading indicator → blank white page throughout. `main.dart` `await`s `FirebaseService.initialize()` **before `runApp`**, which `await`s `FirebaseNotificationService.initialize()` → `requestPermission()` (shows the browser notification prompt and blocks until answered) and `getToken()` (fails: no `firebase-messaging-sw.js`). Then `SplashScreen` adds a hard `AppDurations.splash = 2400 ms`. | S1 | Defect + Infra | (a) Add an inline HTML/CSS loader to `web/index.html`. (b) Skip FCM entirely on web (`kIsWeb` guard) or move it after `runApp` un-awaited. (c) Drop `--no-web-resources-cdn` **or** keep it and accept the 5.6 MB — measure both. (d) Re-enable the Flutter service worker. (e) Load Cairo only for `ar`. (f) Cut the splash delay to ~600 ms on web. | None — do first | DevTools Network, cold cache + "Disable cache": record total KB and first-contentful-paint before/after. Re-measure with `performance.getEntriesByType('resource')`. Repeat on a throttled "Fast 3G" profile. |
| 2 | Country selection | `country_selection_screen.dart:127`, `countries_data.dart` | **CONFIRMED.** 71 `CountryModel` entries in a `ListView.separated`, each wrapped in `.animate(delay: (25 * index).ms, …)`. The 71st item begins animating at **1,750 ms**; because the list builds lazily, scrolling re-triggers ever-longer delays, so rows render blank/faded. Compounded by RC-D (the whole app is still warming up). No network call is involved — the list is a `const`. | S2 | Defect | Cap the stagger (`delay: (25 * min(index, 8)).ms`) or drop the per-row animation for this list. | #1 helps perceptually | Open Language → Country on the deployed build; the full list should be legible immediately. Scroll to Zimbabwe — no blank rows. |
| 3 | Registration | `email_auth_screen.dart`, `firebase_auth_repository.dart:registerWithEmail`, `firestore_user_profile_repository.dart:ensureProfile` | **CONFIRMED — missing functionality (RC-E).** The form has exactly two fields: email and password. `ensureProfile` consequently writes `displayName: null`, and `ensureCompany` seeds the company `name` from that same null. Phone capture exists but only as post-hoc *linking* (`phone_verification_screen.dart`), never at sign-up. | S2 | Missing | Add full name (required) and phone (optional) to the sign-up form; pass through `updateProfile(displayName:)` + `ensureProfile`. Decide with the client whether role selection should move into registration too. | Feeds #17, improves #9 | Register a new account; confirm `users/{uid}.displayName` is populated in Firestore and the name renders on Home and Company Profile. |
| 4 | Verification email latency | `firebase_auth_repository.dart:sendEmailVerification` | **HYPOTHESIS (Console-side, RC-I).** Code calls `sendEmailVerification()` with **no `ActionCodeSettings`** — so Firebase's default transport and template are used. Latency is Firebase-side and not controllable from the client. | S2 | Infra | Configure a custom SMTP sender + custom action-code domain in Firebase Console → Authentication → Templates. Add an explicit "check your spam folder" line to `EmailVerificationScreen`. | #5 (same fix) | Register with a real mailbox (Gmail + Outlook); record send→receive time before and after the Console change. |
| 5 | Verification email in Spam | same as #4 | **HYPOTHESIS (Console-side, RC-I).** Default sender is `noreply@careerbridge-97-f58c9.firebaseapp.com` with no SPF/DKIM/DMARC alignment to a Wazifly-owned domain — the standard reason Firebase auth mail is filtered. | S2 | Infra | Verify a sending domain, publish SPF + DKIM + DMARC, set the custom sender and custom action URL in Console. | #4 | Send to Gmail/Outlook/Yahoo; check it lands in Inbox. Score the message with `mail-tester.com`. |
| 6 | Employer → Publish Job | `job_editor_screen.dart:244`, `job_action_handler.dart`, `job_preview_screen.dart`, `employer_jobs_controller.dart:_transition` | **CONFIRMED (RC-B).** Neither "Publish" affordance publishes. The editor's Publish saves a **draft** then navigates to Preview; `JobAction.publish` falls through to `JobAction.preview` and only navigates. Status changes solely in `job_preview_screen._confirmAndPublish`. Separately, `_transition` silently returns when the transition is illegal, producing a dead button with no message. | **S1** | Defect (Design gone wrong) | Make "Publish" publish: confirm in place (dialog), then `controller.publish()`. Keep Preview as its own clearly-labelled secondary action. Give `_transition` an explicit failure path instead of a silent `return`. | **Fix first** — gates #9, #11, #15 | As an employer: create a job, fill required fields, tap Publish, confirm. Verify the Firestore doc shows `status: "published"` **without** visiting Preview. Then check Manage Jobs and seeker Browse. |
| 7 | Manage Jobs — infinite load, no jobs | `firestore_employer_jobs_repository.dart:57`, `employer_jobs_screen.dart:77`, `employer_jobs_repository.dart:employerJobsProvider` | **CONFIRMED — two stacked causes.** *Infinite load* = RC-A: `watchJobs` ends in `.handleError(…)`, so a failed read closes the stream with no emission and `employerJobsProvider` stays `AsyncLoading`; the screen's only branch is `async.isLoading && !anyJobs`, with no error state. *No published jobs* = RC-B (they are drafts). | **S1** | Defect | RC-A: replace `.handleError` with error **transformation** (emit `[]` or forward the error) so the provider resolves; add a `hasError` branch with a Retry to the screen. RC-B: fix #6. | #6 | Sign in as an employer with no jobs → expect an empty state, not a spinner. Then temporarily deny the `jobs` read in the Firestore emulator → expect a visible error + Retry, not a spinner. |
| 8 | No clear CV upload option | `home_screen.dart:51-86`, `cv_actions_controller.dart:130`, `job_matching_controller.dart:112`, `resume_analyzer_screen.dart` | **CONFIRMED — discoverability, not absence (RC-K).** Upload *does* work, via `file_selector` (`openFile`), in three places. But no surface is named "Upload CV": the Home toolkit offers "Resume Analyzer", "CV Builder", "My CVs". The upload is buried behind AI feature names. (`file_picker` was deliberately removed — do not reintroduce it; `file_selector` is the sanctioned picker.) | S2 | Missing (IA) | Add a primary "Upload your CV" action on Home and in the My CVs empty state, routing to the existing import in `cv_actions_controller`. Label by user intent, not by AI feature. | None | New seeker on Home: an obvious "Upload CV" path must exist. Upload a PDF; confirm it appears in My CVs and is selectable when applying. |
| 9 | Published jobs not findable by seekers | `jobs_browse_controller.dart:84,115-119`, `job_query_filter.dart`, `firestore_jobs_repository.dart:64`, `composite_jobs_repository.dart` | **CONFIRMED — two stacked causes.** (a) RC-B: postings are still `draft`, and the seeker query is `where('status','==','published')` — so they are never fetched. (b) RC-C: even once published, the Browse controller silently defaults `location` to `"Qatar"`; `applyJobQuery` drops non-remote jobs whose `location` lacks that substring, and `clearFilters()` restores the default. Also: `Job.company` comes from `JobPosting.companyName`, which is blank when the company has no name (#3/#17) — so company-name search misses too. | **S1** | Defect | Fix #6. Then: make the default location filter **visible** as a removable chip, make `clearFilters()` actually clear it, and consider defaulting to "All countries" for a global product. | #6, then #3 | Publish a job located `"Doha"` (no "Qatar"). As a seeker, Browse and search by title — it must appear. Repeat with location `"Cairo"` and a remote job. |
| 10 | Applications page — infinite load | `firestore_applications_repository.dart:111`, `applications_screen.dart:97-100`, `firestore_employer_applicants_repository.dart:52`, `employer_applicants_screen.dart:107` | **CONFIRMED (RC-A), both sides.** Seeker: `watchApplications` ends in `.handleError`, so `applications_screen`'s *existing* `hasError` branch is **unreachable dead code** and the spinner at line 97 never clears. Employer: identical pattern at `employer_applicants_screen.dart:107`, which has no error branch at all. | **S1** | Defect | Same as #7: stop swallowing errors in the repositories; ensure every list screen has loading / empty / error states (the shared `StatusView` already exists for this). | Shares fix with #7 | Sign in with no applications → empty state, not a spinner. Deny the `applications` read in the emulator → visible error + Retry. Verify on both seeker and employer screens. |
| 11 | Employer jobs missing after publishing | same as #6 + #7 | **CONFIRMED — duplicate of #6 + #7**, not an independent bug. Jobs are saved (`createJob`/`saveDraft` do persist) but as `draft`; and any read failure shows as a permanent spinner. | **S1** | Defect | Covered by #6 and #7. | #6, #7 | Covered by #6's and #7's tests. |
| 12 | Wrong password → length message | `email_auth_screen.dart:51-55` | **CONFIRMED (RC-F).** `_validatePassword` is wired to the password field in **both** modes and returns `l10n.passwordTooShort` ("Password must be at least 6 characters") whenever `value.length < 6`. `_submit` runs `_formKey.currentState!.validate()` **before** any network call, so a wrong password shorter than 6 characters never reaches Firebase and the user is told it is too short. (The error *mapping* is correct — `invalid-credential` → `errInvalidCredentials` = "Incorrect email or password." — it just is not reached.) | S2 | Defect | Split the validators: sign-**in** validates non-empty only; sign-**up** keeps the strength rule. | None — small, safe | Sign in with an existing account and the password `"123"` → expect "Incorrect email or password.", not a length warning. Confirm sign-**up** still rejects short passwords. |
| 13 | No password requirements shown | `email_auth_screen.dart:51-55` | **CONFIRMED — missing (RC-M).** The only rule is `length < 6`; there is no helper text, no requirement checklist, no strength meter, and Firebase's own password policy is never surfaced. | S3 | Missing | Show the requirements under the field in sign-up mode with live tick-off; align the rule with whatever Firebase password policy you enable. | #12 (same file — do together) | On sign-up, requirements are visible before typing and update as you type. |
| 14 | Repeated login attempts slow | `auth_navigation.dart:goAfterAuth`, `firestore_user_profile_repository.dart`, `email_auth_screen.dart:_submit` | **CONFIRMED (RC-G) + contributing hypothesis.** Confirmed: after the auth call, `goAfterAuth` performs **three sequential awaited Firestore round-trips** before navigating — `ensureProfile` does `doc.get()` then `doc.set()`, then `_resolveUserType(trustCache: false)` does `fetchProfile` → `doc.get()` **re-reading the document it just wrote**. `maybeOfferBiometricEnrollment` is awaited before that. Hypothesis: repeated *failed* attempts additionally hit Firebase's `too-many-requests` throttle (already mapped to `errTooManyRequests`), and RC-D keeps the tab busy. | S2 | Defect | Have `ensureProfile` return the profile it just wrote so `fetchProfile` is not needed; parallelise what remains; navigate optimistically and reconcile the role in the background. | #1 | Time sign-in → home on the deployed build (DevTools Performance). Expect one round-trip's latency, not three. Attempt 5 wrong passwords then a correct one; confirm the throttle message is explicit. |
| 15 | Dashboard cards have no action | `employer_home_screen.dart:228-300` | **CONFIRMED (RC-J).** `_StatTile` is a bare `Container` — no `InkWell`, no `onTap`, no `GestureDetector`. The four cards are display-only by construction. (The *other* dashboard cards at lines 90/97/104 *are* tappable, which is why these read as broken.) Their values also read 0 because of RC-B. | S3 | Design / Missing | Wrap `_StatTile` in `InkWell` and route: Active Jobs → Manage Jobs (published filter); Applications → Applicants; Interviews → Applicants filtered `interview`; Hires → Applicants filtered `accepted`. The filter providers already accept exactly these. | #6 (so numbers are non-zero) | Tap each of the four cards; each lands on the correct pre-filtered list. |
| 16 | Two accounts → session confusion | `storage_keys.dart:10`, `user_type_controller.dart`, `auth_navigation.dart:goToRoleHome`, `firebase_service.dart:_configureFirestore` | **HYPOTHESIS, strongly supported (RC-H).** Three mechanisms, all inherent to web: (a) Firebase Auth web persistence is **per-origin**, shared by every tab of `wazifly.replit.app` — a second sign-in overwrites the first and `authStateChanges` fires in **both** tabs, so tab 1 silently switches account. (b) `StorageKeys.userType = 'pref_user_type'` is a **single device-global key** in `localStorage`; `goToRoleHome(trustCache: true)` trusts it, so the role cache can belong to the other account. (c) `Settings(persistenceEnabled: true)` without multi-tab sync makes Firestore persistence fail in the second tab → the read error is then swallowed by RC-A → permanent spinner. | S2 | Defect | Key the role cache by uid (`pref_user_type_<uid>`). Clear per-user caches on `signOut` and on uid change. Fix RC-A so a persistence failure surfaces instead of hanging. Document that one browser profile holds one session (that is the platform contract). | #7/#10 (RC-A) | Open two tabs, sign in as employer then as seeker. Tab 1 must either reflect the switch coherently or show a clear "signed in elsewhere" state — never a wrong role and never a dead spinner. |
| 17 | Company Profile does not open / shows nothing | `company_profile_screen.dart:27-47`, `company_providers.dart:currentCompanyProvider`, `firestore_company_repository.dart:ensureCompany` | **CONFIRMED — "shows nothing", not "does not open" (RC-E).** The screen *does* render: `currentCompanyProvider` falls back to `Company.empty(user.uid)`, so `_EmptyState` appears only when signed **out**. But every detail row is `if (company.X != null)` and the document is nearly empty, because `ensureCompany` seeds `name` from `user.displayName` — which is **always null** (issue #3) — leaving only a fallback company name and `contactEmail`. `ensureCompany` also swallows its own failures (`catch` → `debugPrint`), so a first-write failure is invisible. | S2 | Defect + Missing | Fix #3 so a name exists. Add an explicit "Complete your company profile" empty state with a direct CTA to Edit Company. Let `ensureCompany` surface failures. | #3 | Register a fresh employer → Company Profile shows either real data or a clear "complete your profile" prompt with a working CTA. Confirm `companies/{uid}` exists in Firestore. |
| 18 | No account switching | `settings` feature, `auth_navigation.dart` | **CONFIRMED — missing (RC-H).** There is sign-out but no multi-account concept anywhere: no account list, no switcher, no per-account cache namespacing. | S3 | Missing | Short term: a clear "Sign out and switch account" item that clears every per-user cache. Long term: a real account switcher — only worth it after the uid-keying in #16. | #16 | Switch accounts via the new control; no state from the previous account survives (role, CVs, applications, company). |

---

## 4. Hypotheses tested and **ruled out**

Recording these so nobody spends time on them.

| Candidate | Verdict | Evidence |
|---|---|---|
| Missing Firestore composite indexes cause the infinite loading (`firestore.indexes.json` is `{"indexes": [], "fieldOverrides": []}`) | **RULED OUT** | Every Firestore query in `lib/` was enumerated. All are single equality filters with `.limit()` and **no `orderBy`** — sorting runs in Dart by deliberate design. The only two-clause query (`firestore_employer_notes_repository.dart:32-33`) is equality + equality, which Firestore serves by merging single-field indexes. **No composite index is needed; the empty file is correct.** |
| Firestore security rules deny the list queries | **RULED OUT as the cause of 7/9/10/11** | The queries are written to match the rules exactly: the employer lists `jobs` by `ownerUid == uid` (matching the rule's owner clause) and seekers list by `status == 'published'` (matching the published clause); `applications` is listed by `applicantUid` / `ownerUid`, both allowed. `companies` read is `signedIn()`. The rules are *tolerant* by design. RC-A makes any denial *look* like this, which is why it was worth checking. |
| App Check / reCAPTCHA is broken on web and blocking Firestore | **RULED OUT** | Verified live: `recaptcha__en.js` (351 KB) loads from gstatic on the deployed site, and the client confirms Career Coach answers through Firebase AI Logic. App Check is working. **Not to be touched.** |
| Local / GitHub / Replit code differences explain the reported bugs | **RULED OUT** | `git diff --name-only HEAD origin/replit-backup-2026-11-03` touches only AI, App Check, localization, splash, docs and test files. **No** auth, jobs, applications, company or employer source file differs. Every finding above is present in the deployed build. |
| Jobs are not being written to Firestore at all | **RULED OUT** | `createJob` / `updateJob` persist correctly and **rethrow** on failure so the optimistic controller rolls back. The problem is the `status` value they persist (RC-B), not the write. |

---

## 5. Proposed implementation plan

Small, independently testable phases. **Phase 0 and 1 alone close five S1 reports.** Nothing below touches App Check, AI, Firestore rules, or authentication configuration.

### Phase 0 — Safety net (no behaviour change)
1. Branch from `40cae57`; do not merge `replit-backup-2026-11-03`.
2. Baseline: `flutter analyze` + `flutter test` (expect clean / all passing), and record the 13.9 MB web metric as the "before" number.
3. Agree on which tree deploys to Replit, and resolve the AI divergence **separately** from this work.

**Verify:** analyze clean, tests green, baseline recorded.

### Phase 1 — Make failure visible (RC-A) — *do this first*
Replace error-swallowing with error **propagation** in the 9 repositories, and give every list screen loading / empty / error states (`StatusView` already exists).

**Why first:** it is the lens for everything else. Until a denial shows as an error instead of a spinner, every later fix is verified blind. Low risk, mechanical, covered by tests.
**Closes:** 7 (loading half), 10, and the spinner in 11/16/17.
**Verify:** with the Firestore emulator denying each collection in turn, every affected screen shows an error + Retry. No screen can reach a permanent spinner.

### Phase 2 — Make publishing work (RC-B)
Publish directly from the editor and from `JobAction.publish` (confirm in place); keep Preview as a distinct action; give `_transition` a real failure path.

**Closes:** 6, 11; unblocks 9 and 15.
**Verify:** publish without opening Preview → `status: "published"` in Firestore → job visible in Manage Jobs *and* in seeker Browse.

### Phase 3 — Make published jobs findable (RC-C)
Surface the location filter as a removable chip, make `clearFilters()` clear it, and decide the global default with the client.

**Closes:** 9.
**Verify:** a job located `"Doha"` is found by a seeker with default filters.

### Phase 4 — Auth correctness (RC-F, RC-M, RC-G)
Split the sign-in vs. sign-up password validators (#12); add the requirements affordance (#13); collapse the post-sign-in round-trips (#14).

**Closes:** 12, 13, 14 (code half).
**Verify:** wrong short password → "Incorrect email or password."; sign-up still enforces strength; sign-in → home measurably faster.

### Phase 5 — Web load performance (RC-D)
Loader in `index.html`; `kIsWeb` guard on FCM; re-enable the service worker; locale-gate Cairo; reduce the splash delay; measure `--no-web-resources-cdn` both ways. Cap the country-list stagger (#2).

**Closes:** 1, 2.
**Verify:** before/after total KB and first-contentful-paint, cold cache and on throttled 3G. No visual or RTL regression in EN **and** AR.

### Phase 6 — Registration & company profile (RC-E)
Add name + optional phone to sign-up; propagate to `displayName`, `users/{uid}` and `companies/{uid}`; add the company-profile completion CTA; let `ensureCompany` surface failures.

**Closes:** 3, 17.
**Verify:** a fresh employer sees their own name and a working completion path.

### Phase 7 — Discoverability & dashboard (RC-K, RC-J)
Add the "Upload your CV" entry point (#8, reusing `file_selector`); make the four stat cards tappable into pre-filtered lists (#15).

**Closes:** 8, 15.
**Verify:** upload reachable in one tap from Home; each card routes correctly.

### Phase 8 — Multi-account hygiene (RC-H)
Key per-user caches by uid; clear them on sign-out and uid change; add "Sign out and switch account"; document the one-session-per-browser-profile contract.

**Closes:** 16, 18.
**Verify:** two-tab test leaks no state and produces no wrong role.

### Phase 9 — Email deliverability (RC-I) — *client/Console, not code*
Verify a sending domain; publish SPF + DKIM + DMARC; set the custom sender and action URL in Firebase Console; add spam-folder guidance to the verification screen.

**Closes:** 4, 5.
**Verify:** inbox delivery on Gmail/Outlook/Yahoo; `mail-tester.com` score.

### Why this order

* Phase 1 before everything: it is the only way to see what is actually failing.
* Phase 2 before 3 and 7: there is nothing to find or count until jobs can be published.
* Phase 6 before the cosmetic parts of 17: the company profile is empty because registration is.
* Phase 9 is parallel and owner-side — it needs no code and can start immediately.
* Phases 4, 5 and 8 are independent of 2/3 and can be parallelised if more than one person works on this.

---

## 6. Risk register

| Risk | Mitigation |
|---|---|
| Regressing AI / App Check | No phase touches `lib/core/services/ai/**`, `lib/core/services/app_check/**`, or the reCAPTCHA key. Verify with the existing `AI_SELFTEST` probe after each deploy. |
| Merging the two divergent AI solutions | Resolve the `40cae57` vs `11a1f97` divergence as its own task, with its own verification, before or after — never inside a bug-fix phase. |
| Phase 1 surfacing errors users never saw | That is the intent, but it will make pre-existing backend problems newly visible. Expect a second, smaller round of findings and budget for it. |
| Changing the Browse default (Phase 3) alters what every seeker sees | Confirm the intended default with the client before changing it; it is a product decision, not a bug. |
| Dropping `--no-web-resources-cdn` reintroduces a gstatic dependency | Measure both; if gstatic is blocked for the client's users, keep the bundle and recover the time via the service worker instead. |
| Firestore rules | Not modified in any phase. If a phase appears to need a rules change, stop and escalate. |
