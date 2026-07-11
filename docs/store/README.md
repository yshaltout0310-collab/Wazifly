# Career Bridge — Google Play Submission Kit

> **Purpose:** everything needed to submit Career Bridge to Google Play, in one
> place. This folder holds the store listing, asset specs, Data Safety mapping,
> Play Console answers, and the master release checklist. Legal documents that
> must be **publicly hosted** live in [`../legal/`](../legal).
>
> This kit is **preparation only** — no app is published by reading it. It is the
> Phase 7 · Milestone 1 (Deployment Preparation) deliverable. Build/sign/publish
> mechanics live in [`../RELEASE.md`](../RELEASE.md); pre-release QA lives in
> [`../QA_CHECKLIST.md`](../QA_CHECKLIST.md). Those are **cross-linked, not
> duplicated**, so there is a single source of truth for each concern.

---

## Documents in this kit

| Document | Purpose |
| --- | --- |
| [`STORE_LISTING.md`](STORE_LISTING.md) | App name, short & full description (**English + Arabic**), category, contact, website, AI-transparency notice. |
| [`STORE_ASSETS.md`](STORE_ASSETS.md) | App icon, feature graphic, screenshots (with recommended order), promo assets — **specifications only, no art generated**. |
| [`DATA_SAFETY.md`](DATA_SAFETY.md) | The Play **Data Safety** form answered field-by-field, mapped to the app's real data flows. |
| [`PLAY_CONSOLE.md`](PLAY_CONSOLE.md) | Content rating, target audience, permissions review, ads/monetization, app access (test logins), testing-track requirements. |
| [`RELEASE_CHECKLIST.md`](RELEASE_CHECKLIST.md) | The master, ordered, tickable pre-publish checklist covering every manual step. |
| [`../legal/PRIVACY_POLICY.md`](../legal/PRIVACY_POLICY.md) | Privacy Policy — must be hosted at a public URL before submission. |
| [`../legal/TERMS_OF_SERVICE.md`](../legal/TERMS_OF_SERVICE.md) | Terms of Service — recommended to host alongside the policy. |

---

## Submission order (high level)

1. **Finish the fill-ins** in the tracker below.
2. **Host** the Privacy Policy (and Terms) at public URLs — Play requires a
   reachable privacy-policy URL.
3. **Build** the signed release `.aab` per [`../RELEASE.md`](../RELEASE.md) §3–§6.
4. **Complete the Play Console** sections using `PLAY_CONSOLE.md` + `DATA_SAFETY.md`.
5. **Upload** the listing text/assets using `STORE_LISTING.md` + `STORE_ASSETS.md`.
6. **Run the master checklist** ([`RELEASE_CHECKLIST.md`](RELEASE_CHECKLIST.md)) end-to-end.
7. **Release to a testing track first** (Internal → Closed), then Production.

---

## Fill-in tracker

Every value the developer must supply before submission is written in the docs as
a `⟨FILL-IN: …⟩` marker. Nothing ships blank. Track completion here:

| # | Value | Used in | Status |
| --- | --- | --- | --- |
| 1 | Support / contact email | Store listing, Privacy Policy, Terms, Data Safety, Play contact | ☐ |
| 2 | Developer / legal entity name | Privacy Policy, Terms | ☐ |
| 3 | Governing-law jurisdiction (country/state) | Terms | ☐ |
| 4 | Hosted **Privacy Policy URL** | Store listing, Play "Privacy policy" field, Data Safety | ☐ |
| 5 | Hosted **Terms of Service URL** (optional but recommended) | Store listing, Terms link | ☐ |
| 6 | **Website URL** (may reuse the hosted policy/landing page) | Store listing contact | ☐ |
| 7 | Effective date confirmed on legal docs | Privacy Policy, Terms | ☐ |
| 8 | Upload keystore created + `android/key.properties` filled | Signing (RELEASE.md §3) | ☐ |
| 9 | Play test-login credentials confirmed working | Play Console → App access | ☐ |
| 10 | (Optional) Arabic store-listing review by a native speaker | Store listing (AR) | ☐ |

> Reviewer note for legal docs: the Privacy Policy and Terms are **thorough
> templates grounded in the app's real data flows**, not legal advice. Have them
> reviewed by qualified counsel before publishing.

---

## Product facts (authoritative — mirror, don't re-derive)

| Item | Value |
| --- | --- |
| App name | Career Bridge |
| Package / `applicationId` | `com.careerbridge.careerbridge` |
| Play category | Business |
| Target audience | 18 and over |
| Monetization | Free · **no ads** · no in-app purchases / subscriptions |
| First version | `1.0.0` (build code `1`) — `pubspec.yaml` `version: 1.0.0+1` |
| `minSdk` | 23 |
| Permissions | `INTERNET`, `POST_NOTIFICATIONS`, `USE_BIOMETRIC` (all normal; advertising-ID `AD_ID` explicitly removed) |
| Firebase project | `careerbridge-97-f58c9` (number `894890748117`) |
| Languages | English (LTR) + Arabic (full RTL) |
| Brand colors | Emerald `#0E9F6E` (icon), `#0B7D57` (splash), dark `#101413` |

See [`../RELEASE.md`](../RELEASE.md) §0 for the build-side copy of these facts.
