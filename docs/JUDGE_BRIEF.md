# Wazifly — Technical Judge Brief

> Preparation for a **technical** evaluation: what to show, in what order, what
> to claim, what to concede, and how to answer the questions a competent reviewer
> will actually ask.
>
> The governing rule: **a judge trusts a team that knows its own weaknesses.**
> Every limitation in §5 is one you should raise yourself, before you are asked.
> Everything here is checked against the source — see
> [`TECHNICAL_AUDIT.md`](TECHNICAL_AUDIT.md).

---

## 1. The pitch, in 60 seconds

> Wazifly is an AI-powered job platform built in Flutter, serving job seekers and
> employers from one codebase, fully bilingual in English and Arabic with
> right-to-left support, on Android, iOS and the web.
>
> The AI is Google Gemini, reached through Firebase AI Logic — which means **no
> API key ever ships in the app**; requests are authenticated by the Firebase app
> itself. That one decision drives the résumé analyzer, job matching, the career
> coach, CV enhancement, interview prep and recommendations.
>
> The engineering point I'd make is this: **every external dependency in the app
> sits behind an interface with a working fallback.** Firebase, Gemini, PDF
> extraction, OCR, biometrics, analytics, crash reporting — each is one Riverpod
> provider away from being swapped, and each degrades instead of crashing when
> it's unavailable. That's why the same source runs on the web today, with
> biometrics and Crashlytics simply absent, and nothing else changed.

---

## 2. Numbers to have ready

| | |
| --- | --- |
| Source | **352** Dart files, **~58,500** lines under `lib/` |
| Tests | **696** passing, **127** test files, **67.0%** line coverage |
| Static analysis | `flutter analyze` — **no issues**, with `dead_code` promoted to an error |
| Localization | **1041** keys, **100%** English ↔ Arabic parity, RTL throughout |
| Debt markers | **0** `TODO` / `FIXME` / `HACK` in `lib/` |
| Android permissions | **3** — `INTERNET`, `POST_NOTIFICATIONS`, `USE_BIOMETRIC`; advertising ID explicitly stripped |
| Firestore collections | **8**, all under default-deny rules with identity-field immutability and size caps |
| Targets | Android (R8 release + AAB), iOS, **web** |

---

## 3. The ten-minute code tour

Open these, in this order. Each one makes a point; do not narrate the whole tree.

| # | File | The point to make |
| --- | --- | --- |
| 1 | `lib/core/services/ai/ai_service.dart` | "Six AI features, one interface, four methods. Nothing in the feature code knows the vendor's name." |
| 2 | `lib/core/services/ai/firebase_ai_service.dart` | "Model `gemini-2.5-flash`, JSON-constrained responses, no key. `firebase_ai` is imported by exactly two files — this one and the OCR implementation below — and both sit behind an interface." |
| 3 | `lib/main.dart` | "Every telemetry call is best-effort. App Check is activated *after* `runApp` and deliberately not awaited — attestation must never delay the first frame." |
| 4 | `lib/features/resume_analyzer/data/resume_analyzer_repository_impl.dart` | "Layout-aware PDF extraction, then a prompt that detects the career field **first** and only evaluates within it, against an explicit 0–100 rubric with date validation." |
| 5 | `lib/features/resume_analyzer/data/gemini_pdf_ocr.dart` | "Scanned CV with no text layer? We rasterize on-device and send one multimodal request to the model we already depend on. No extra OCR plugin, no model download." |
| 6 | `firestore.rules` | "Not just ownership — identity fields are immutable on update and free text is size-capped. The comments record *why* each rule is shaped that way, including a rule that once wedged a live listener." |
| 7 | `storage.rules` (the `users/**` comment) | "Storage grants on *any* matching rule, so a catch-all would silently bypass the content-type and size caps above it. That's why there isn't one." |
| 8 | `lib/core/utils/stable_hash.dart` + `test/stable_hash_test.dart` | "Web compiles to JavaScript, which can't represent 64-bit integers — and neither `analyze` nor `test` catches that, because both run on the VM. So the guard is a test that scans the source." |

---

## 4. Live demo script

**Before you start:** launch once and leave it on the target screen. A cold start
plus a Gemini round-trip is the slowest thing in the demo.

| Step | Show | Say |
| --- | --- | --- |
| 1 | Language screen → pick **العربية** | "Localization isn't a translation file bolted on — the whole layout mirrors." |
| 2 | Any populated screen in Arabic | "Right-to-left, Arabic numerals, Cairo font — and the font is bundled, not fetched, so a cold offline launch still renders correctly." |
| 3 | Switch back to English in Settings | "Language and theme are persisted controllers; the change is live, no restart." |
| 4 | **Résumé Analyzer** → upload a real PDF CV | The centerpiece. While it runs, explain the pipeline: layout-aware extraction → field detection → rubric-calibrated scoring. |
| 5 | The analysis result | "Career field, ATS score, strengths, weaknesses, missing skills — and the missing skills are constrained to the detected field, so a computer-science CV is never told to learn accounting." |
| 6 | **CV Builder** → generate a PDF | "Generated entirely in Dart — which is why the templates are unit-testable — and bidi-aware, so an Arabic CV lays out correctly." |
| 7 | **Interview Prep** or **Career Coach** | For the coach, point at the streaming reply: "multi-turn history through the same `AiService` seam." |
| 8 | Switch to the **employer** side | "Same codebase, role-aware. Company profile, job posting, applicant review with private notes, hiring analytics." |
| 9 | *(Optional)* the **web** build in a browser | "Same source, no branch, no fork. Biometrics and Crashlytics have no web implementation, so they disable themselves — everything else is identical." |

**If a Gemini call fails live:** say so plainly, and turn it into the point you
wanted to make anyway — *"that's the `AiException` path: every AI failure maps to
a stable, localized error code rather than an exception reaching the UI"* — then
show a previously completed result. Do not retry twice in front of a judge.

---

## 5. Limitations — raise these yourself

State these before a judge finds them. Each is paired with the answer that makes
it a considered decision rather than an oversight.

**1. The seeker's job catalogue is a bundled dataset, not live data.**

> "The 18 jobs a seeker browses come from a bundled JSON file, not Firestore. That
> was a deliberate demo choice — it guarantees a populated, bilingual, offline-capable
> experience with no seeding step. It sits behind the same `JobsRepository`
> interface the real backend would implement, so it's a provider rebind, not a
> rewrite. Today it means a job an employer publishes is visible on that
> employer's dashboard only."

**2. Submitted applications are session-scoped.**

> "The seeker's applications repository is in-memory, so they don't survive a
> restart and don't reach the employer's applicant list. The employer side already
> reads Firestore; the interface, the model and the security rules all exist. What's
> missing is the Firestore implementation on the seeker side — and I'd tighten the
> `applications` create rule in the same change, because it currently doesn't bind
> an application to the real job owner. That's the top item on the roadmap and I
> can tell you exactly what it touches."

**3. Release builds are debug-signed.**

> "Signing is wired and reads an optional `key.properties`; the real upload keystore
> hasn't been created yet. That's a release-ownership step, not an engineering one."

**4. Cloud Storage rules are written but not deployed** — the default bucket isn't
provisioned yet. Firestore rules *are* deployed.

**5. App Check runs unenforced.** It activates on device and degrades gracefully;
enforcement hasn't been switched on. On the web there's no attestation provider
registered at all — so enabling enforcement and registering a web reCAPTCHA
provider have to happen as one change or the web build loses backend access.

**6. Accessibility has not had a full screen-reader sweep.** Semantics, tooltips
and live regions are in place; a complete TalkBack pass has not been done. The
home AI-toolkit grid also overflows at text scale ≥ 1.8.

**7. Coverage is uneven.** 67% overall, but the newest employer screens
(Interview, Candidates) are close to untested. Say the number; don't round it up.

---

## 6. Anticipated questions

**"Where's the API key? How are you calling Gemini without one?"**
> Through Firebase AI Logic. The client authenticates as the Firebase app, so
> there's no key in the bundle to extract — which is the whole reason for that
> choice. The vendor SDK is imported by exactly two files, both implementations
> behind interfaces (`AiService` and `ResumeOcr`); no feature code touches it. With
> App Check enforced, the backend can additionally reject requests from tampered
> clients.

**"How do you stop someone reading another user's data?"**
> Firestore rules, default-deny with no fall-through match. Ownership is checked
> per collection, identity fields like `ownerUid` and `applicantUid` are immutable
> on update, and free-text fields are size-capped so a tampered client can't bloat
> a document. There's one gap I'd fix before shipping the applications flow — the
> create rule doesn't yet verify that `ownerUid` matches the referenced job's real
> owner. It isn't reachable today because nothing writes to that collection from
> the client.

**"Why Riverpod over BLoC or Provider?"**
> Compile-safe dependency injection without a `BuildContext`, which is what makes
> the service seams testable — a test overrides one provider and gets a fake. The
> bootstrap in `main.dart` and the widget tree share a single `ProviderContainer`,
> so telemetry and the UI resolve the same instances.

**"What happens with no network?"**
> Firestore's offline persistence is on with a bounded 40 MB cache, fonts are
> bundled rather than fetched, and there's an advisory offline banner that never
> gates a feature. AI features need the network and fail with a localized error
> code.

**"How does the same code run on web if it uses biometrics and Crashlytics?"**
> Because neither is imported by feature code. `biometricServiceProvider` binds a
> no-op when `kIsWeb`, `connectivityServiceProvider` does the same, and the
> Firebase telemetry services are best-effort — they log and continue. That's the
> interface-plus-fallback pattern paying off at a platform boundary rather than a
> vendor one.

**"How do you know the Arabic is right and not machine-dumped?"**
> 1041 keys with exact parity, and the eight strings that are identical between
> locales are the ones that should be — the brand mark, "LinkedIn", "GitHub", the
> ATS acronym, and the language endonyms. Screens are rendered in both locales in
> the test suite, and RTL bugs found in review — PDF bidi, a radar chart with
> hardcoded LTR labels — were fixed rather than worked around.

**"What's your test strategy? 67% isn't high."**
> It isn't, and the gaps are specific rather than uniform: models and shared
> widgets are in the mid-80s, the newest employer screens are close to zero.
> Beyond unit and widget tests there are regression guards for things a human
> reviewer would miss — the Android permission surface, font bundling, and a scan
> for integer literals that would break the web build.

**"Is this production-ready?"**
> The engineering is: release builds, deployed rules, telemetry, store and legal
> paperwork prepared. What's not production-ready is the marketplace loop — jobs
> and applications aren't wired end-to-end yet — plus four external steps: a real
> keystore, the Storage bucket, App Check enforcement, and hosting the legal
> documents. I'd rather state that than claim otherwise.

---

## 7. Things not to say

- Don't call it a live two-sided marketplace. It isn't yet (§5.1, §5.2).
- Don't quote a test count or coverage figure you haven't just re-run.
- Don't describe the seeded jobs as "sample data from the database".
- Don't claim an accessibility standard has been met; describe what was done.
- Don't promise a timeline for the Firestore applications work on the spot —
  describe the change and what it touches.
