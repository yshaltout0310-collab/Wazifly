# Wazifly — Play Console Declarations

> Prepared answers for the Play Console → **App content** and setup sections:
> content rating, target audience, permissions, ads/monetization, app access
> (test logins), and testing-track requirements. Pair with
> [`DATA_SAFETY.md`](DATA_SAFETY.md) (Data Safety form) and
> [`STORE_LISTING.md`](STORE_LISTING.md) (listing text).

---

## 1. Content rating (IARC questionnaire)

Answer the IARC questionnaire truthfully; expected result: **Everyone / PEGI 3**.

| Questionnaire area | Answer |
| --- | --- |
| App category (for rating) | Reference/News/Educational → **Utility / Productivity / Business** (non-game) |
| Violence | None |
| Sexuality / nudity | None |
| Profanity / crude humor | None |
| Controlled substances (drugs/alcohol/tobacco) | None |
| Gambling (real or simulated) | None |
| User-to-user communication / user-generated content | **Yes** — users create profiles/CVs; employers and seekers exchange applications; the Career Coach is AI chat. (Declare UGC; there is no open public social feed.) |
| Shares user location | No |
| Digital purchases | No (free, no IAP) |

- **Result:** expected **Everyone** (Play) / **PEGI 3** — confirm after
  submitting the questionnaire.
- Note the **AI-generated content** disclosure: coaching/analysis is AI-produced
  and clearly framed as assistance, not advice (see AI transparency notice).

## 2. Target audience & content

- **Target age group:** **18 and over.**
- **Appeals to children:** **No** — the app is not designed for or directed at
  children; store presentation (icon, graphics, description) is professional and
  adult-oriented.
- **Consequence:** the app is **out of scope of the Play Families Policy**; no
  child-directed data-handling obligations apply. Keep marketing assets free of
  child-appealing elements to stay consistent with the 18+ declaration.

## 3. Permissions review

The app requests only three Android permissions (see
`android/app/src/main/AndroidManifest.xml`):

| Permission | Why it's needed | Sensitive? |
| --- | --- | --- |
| `android.permission.INTERNET` | All Firebase/Gemini network calls. | No (normal) |
| `android.permission.POST_NOTIFICATIONS` | Firebase Cloud Messaging push notifications (Android 13+ runtime prompt). | No (normal, but runtime-requested) |
| `android.permission.USE_BIOMETRIC` | Optional biometric / device-credential unlock for the app-launch login gate (`local_auth`). Normal permission — **no runtime prompt**; feature degrades gracefully when no biometric is enrolled. | No (normal) |

- **No dangerous/sensitive permissions** (no location, camera, contacts,
  storage-broad, SMS, phone, `QUERY_ALL_PACKAGES`, accessibility, etc.).
  `USE_BIOMETRIC` is a **normal** (install-time) permission, not a dangerous one —
  it authenticates against the device's own biometric hardware and **never reads
  or transmits biometric data** (see [`DATA_SAFETY.md`](DATA_SAFETY.md) §3).
- Therefore **no Play "Sensitive app permissions" / Permissions Declaration
  form** is triggered.
- The `<queries>` `PROCESS_TEXT` entry is the Flutter-engine default (package
  visibility for text processing) — not a permission, no declaration needed.
- **Notifications:** the app requests `POST_NOTIFICATIONS` at runtime; ensure the
  request has clear in-context rationale (already handled by the notification
  flow). No prominent-disclosure form required.

## 4. Ads & monetization

- **Contains ads:** **No.** There is **no ad SDK** in `pubspec.yaml` and no ad
  code anywhere in the app.
- **Monetization (v1.0):** the app is **completely free** — **no** Google Play
  Billing, **no** subscriptions, **no** in-app purchases.
- **Commitment:** Wazifly is an **ad-free platform**. Any future optional
  premium features or subscriptions will **never introduce advertisements** into
  the app.
- **Before any paid feature ships:** re-review and update all Play declarations
  (this doc, Data Safety, content rating financial questions), the legal
  documents, and satisfy Google Play Billing requirements. Until then, declare
  **no ads / no IAP**.

## 5. App access (reviewer instructions)

The app is **login-gated** — Play reviewers cannot evaluate it without working
credentials. Provide these under **App access → All or some functionality is
restricted**:

- **Instructions:** "Sign in on the Welcome screen with the email/password test
  account below, then choose a role (Job Seeker or Employer) to reach the main
  experience."
- **Job Seeker test login:** `appreg030157@cb.app` / `⟨FILL-IN: current password
  — Test123456 per HANDOFF §5, confirm still valid⟩`
- **Employer test login:** `employer01@cb.app` / `⟨FILL-IN: employer test
  password⟩` — reaches the employer dashboard/analytics.
- **Phone sign-in caveat:** phone-OTP delivery is region-restricted in the
  current Firebase config (see HANDOFF §5). Instruct reviewers to use the
  **email** logins, not phone. Alternatively, add a Firebase **test phone
  number** before submission.
- **Google Sign-In:** works, but email login is simplest for reviewers.

> Confirm both test accounts still exist and passwords are valid immediately
> before submission (tracker item #9). Do **not** commit real passwords to the
> repo — fill them into the Console directly.

## 6. Testing-track requirements

Google requires (especially for newer/personal developer accounts) a period of
**closed testing before production**. Plan the rollout as:

1. **Internal testing** — upload the signed `.aab`; add yourself + a few testers;
   smoke-test install/launch/core flows on real devices.
2. **Closed testing** — invite the required number of testers and run for the
   required duration (check the current Play policy — commonly ~12–20 testers for
   ~14 days for new personal accounts). Gather feedback.
3. **Open testing** *(optional)* — broader beta if desired.
4. **Production** — staged rollout (e.g. 10% → 50% → 100%) once testing criteria
   are met.

- Each track needs a **higher `versionCode`** than the last (see versioning in
  [`../RELEASE.md`](../RELEASE.md) §5).
- **Play App Signing:** enroll on first upload (Play holds the app signing key;
  you upload with the upload key) — protects against a lost upload key.

## 7. Other declarations (mostly N/A)

| Declaration | Answer |
| --- | --- |
| Government app | No |
| Financial features / financial-services app | No |
| Health app / health-content | No |
| News app | No |
| COVID-19 / contact-tracing | No |
| Data safety | **Completed** — see [`DATA_SAFETY.md`](DATA_SAFETY.md) |
| Privacy policy | **Required** — host `../legal/PRIVACY_POLICY.md` and enter the URL |
| Advertising ID permission (`AD_ID`) | **Not used.** `firebase_analytics` merges `com.google.android.gms.permission.AD_ID`; the app **removes it** in the manifest (`tools:node="remove"`), so the shipped artifact carries no advertising ID. Declare **"advertising ID not used."** |

> **AD_ID note (resolved in Phase 7 · Milestone 5):** verification of the merged
> **release** manifest confirmed that `firebase_analytics` pulls in
> `com.google.android.gms.permission.AD_ID` by default. Because Wazifly uses
> **no advertising ID**, the source manifest now explicitly strips it:
> ```xml
> <uses-permission android:name="com.google.android.gms.permission.AD_ID"
>     tools:node="remove"/>
> ```
> (`android/app/src/main/AndroidManifest.xml`, guarded by
> `test/android_manifest_test.dart`). In the Play Console, declare that the app
> **does not use the advertising ID** — now provably true at the artifact level.
> Re-verify the merged manifest after any Firebase dependency bump.
