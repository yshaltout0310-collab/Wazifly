# Career Bridge — Google Play Data Safety

> The **Data Safety** section (Play Console → App content → Data safety) answered
> field-by-field from the app's **actual** data flows — Firebase Auth, Firestore,
> Storage, Analytics, Crashlytics, Performance, Firebase AI Logic (Gemini), and
> Cloud Messaging. Transcribe these answers into the Console form. Accuracy
> matters: Play cross-checks declared vs. observed behavior.
>
> **Golden rule:** the app must not collect/share anything not declared here, and
> everything declared must be true. If a future change adds a data type, update
> this doc **and** the Console form.

---

## 1. Overview answers

| Question | Answer |
| --- | --- |
| Does your app collect or share any of the required user data types? | **Yes** |
| Is all of the user data collected by your app encrypted in transit? | **Yes** (Firebase uses TLS/HTTPS end-to-end) |
| Do you provide a way for users to request that their data be deleted? | **Yes** — account/data deletion on request via the support email; see Privacy Policy → "Your rights". |
| Is your app's data collection independently verified against a security standard? | **No** (leave unchecked unless a formal audit is completed) |

## 2. Data types — collected & shared

"Collected" = sent off the device. "Shared" = transferred to a third party. Here,
Google Firebase / Google Cloud act as our **processor/backend**, not as an
independent recipient selling data — but Play still treats sending data to
Firebase/Gemini as **collection**. Declare **collected = Yes**; **shared = No**
for all of the below (no data is sold or handed to independent third parties for
their own use).

| Data type | Collected | Purpose(s) | Required/Optional | Source in app |
| --- | --- | --- | --- | --- |
| **Name** | Yes | Account management, App functionality | Optional | Auth display name / profile |
| **Email address** | Yes | Account management, App functionality | Required (email sign-in) | Firebase Auth |
| **Phone number** | Yes | Account management (phone sign-in) | Optional | Firebase Auth (phone provider) |
| **User IDs** | Yes | Account management, App functionality, Analytics | Required | Firebase Auth UID; Firestore docs |
| **Photos** | Yes | App functionality (profile photo, company logo) | Optional | Firebase Storage |
| **Résumé / CV & career content** *(map to "App activity → Other user-generated content")* | Yes | App functionality (résumé analysis, CV building, matching, coaching) | Optional | Firestore + Storage + sent to Gemini |
| **App interactions / in-app activity** | Yes | Analytics, App functionality | Optional (consent-gated) | Firebase Analytics (screen views, events) |
| **Crash logs** | Yes | Diagnostics (App functionality / stability) | Optional | Firebase Crashlytics |
| **Diagnostics / performance data** | Yes | Diagnostics | Optional | Firebase Performance |

### Notes per type
- **Résumé & profile text → AI:** résumé text and profile fields are transmitted
  to **Google's Gemini model via Firebase AI Logic** to generate analysis,
  matches, coaching, CV content, interview feedback, and recommendations. This is
  disclosed in the Privacy Policy and the store-listing AI notice. Declare it
  under user-generated content for App functionality.
- **Analytics is consent-gated:** the app ships an analytics **consent lever**;
  when a user declines, analytics events are suppressed. Declare Analytics as a
  purpose but note it is optional/consent-based (Play allows "optional").
- **No location, no contacts, no financial data, no health data, no messages
  (SMS/call logs)** are collected. Do **not** declare those.

## 3. Data types — NOT collected (declare "No")

- Precise or approximate **location**
- **Financial info** (no payments/billing in v1.0 — free, ad-free, no IAP)
- **Health & fitness**
- **Contacts** / **Calendar** / **SMS or call logs**
- **Web browsing history**
- **Installed apps** / device or other IDs for advertising (**no ad SDK**)
- **Audio**, **music files**, other files/docs beyond the résumé PDF the user
  explicitly selects

## 4. Security practices (declare)

- ☑ **Data is encrypted in transit** (Firebase TLS).
- ☑ **Users can request data deletion** (support email → account & data deletion;
  documented in the Privacy Policy).
- ☑ **Committed to Play Families Policy:** N/A here — target audience is **18+**
  (see [`PLAY_CONSOLE.md`](PLAY_CONSOLE.md)); the app is not directed at children.
- **App Check** attests requests come from a genuine app instance (integrity),
  currently monitoring-only until enforced (see [`../RELEASE.md`](../RELEASE.md) §7.1).

## 5. Third-party / processor disclosure

The app's backend is **Google Firebase / Google Cloud** (project
`careerbridge-97-f58c9`):
- Firebase **Authentication** (identity), **Cloud Firestore** (profiles, jobs,
  applications, companies), **Cloud Storage** (résumés, photos, logos),
  **Analytics** (consent-gated usage), **Crashlytics** (crash reports),
  **Performance Monitoring** (diagnostics), **Cloud Messaging** (push token),
  **App Check** (integrity), and **Firebase AI Logic / Gemini** (AI features).

These are **service providers processing data on our behalf**, governed by
Google's terms — not independent third parties receiving data for their own
purposes. Hence **"shared" = No** while **"collected" = Yes**. The Privacy Policy
names each processor and links to Google's privacy documentation.

## 6. Ads & monetization (Data Safety-adjacent)

- **No ads, no ad SDK, no advertising IDs.** Declare **no** data collected/shared
  for advertising or marketing.
- **No in-app purchases / subscriptions** in v1.0. If premium features are added
  later, this form and the Privacy Policy must be revisited **before** shipping
  them — and Career Bridge will **remain ad-free** regardless
  (see [`STORE_LISTING.md`](STORE_LISTING.md) §4).

---

### Keep-in-sync reminder
This form must stay consistent with:
[`../legal/PRIVACY_POLICY.md`](../legal/PRIVACY_POLICY.md) (the human-readable
version of these flows) and the app's actual behavior. Update all three together.
