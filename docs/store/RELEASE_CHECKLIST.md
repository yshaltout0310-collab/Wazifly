# Career Bridge — Master Release Checklist (Google Play)

> The single, ordered, tickable checklist for taking Career Bridge from the
> current committed state to a **published** Google Play app. It threads together
> every manual step across the codebase, Firebase Console, legal hosting, and Play
> Console. Deep mechanics are **linked, not duplicated**:
> [`../RELEASE.md`](../RELEASE.md) (build/sign), [`DATA_SAFETY.md`](DATA_SAFETY.md),
> [`PLAY_CONSOLE.md`](PLAY_CONSOLE.md), [`STORE_LISTING.md`](STORE_LISTING.md),
> [`STORE_ASSETS.md`](STORE_ASSETS.md), [`../QA_CHECKLIST.md`](../QA_CHECKLIST.md).
>
> Work top-to-bottom. Do not skip a section.

---

## A. Code & build readiness

- ☐ `flutter analyze` → **No issues found!**
- ☐ `flutter test` → all pass (current baseline: **466**).
- ☐ Confirm `pubspec.yaml` `version:` is correct for this release
  (first release `1.0.0+1`; every later upload needs a higher `+buildCode`).
- ☐ `flutter build appbundle --release --dart-define=APP_VERSION=<v> --dart-define=BUILD_NUMBER=<n>`
  → `.aab` builds under R8 ([`../RELEASE.md`](../RELEASE.md) §5–§6).
- ☐ (Optional QA) `flutter build apk --release` + install-smoke on a device.
- ☐ `--dart-define` `APP_VERSION`/`BUILD_NUMBER` match `pubspec.yaml`
  (so `BuildInfo`/crash reports match the store build).

## B. Signing (one-time per release identity)

- ☐ Upload keystore created with `keytool` and stored **outside** the repo
  ([`../RELEASE.md`](../RELEASE.md) §3.1).
- ☐ `android/key.properties` filled with real values (gitignored — never commit).
- ☐ Store & key passwords saved in a password manager.
- ☐ Release build is signed with the **release** config (not the debug fallback).
- ☐ Enroll in **Play App Signing** on first upload.

## C. Branding & assets

- ☐ Launcher/adaptive icons + native splash verified in sync
  ([`../RELEASE.md`](../RELEASE.md) §4; regenerating yields zero diff).
- ☐ 512×512 store icon exported ([`STORE_ASSETS.md`](STORE_ASSETS.md) §1).
- ☐ 1024×500 feature graphic (EN, + AR if using the Arabic listing) (§2).
- ☐ 6–8 phone screenshots in the recommended order (§3), captured on the release
  build (`-gpu host`, `--no-enable-impeller`).
- ☐ (Optional) tablet screenshots / promo video.

## D. Legal & privacy (must be public URLs)

- ☐ Fill in `⟨FILL-IN⟩`s in [`../legal/PRIVACY_POLICY.md`](../legal/PRIVACY_POLICY.md)
  (entity name, contact email, effective date).
- ☐ Fill in `⟨FILL-IN⟩`s in [`../legal/TERMS_OF_SERVICE.md`](../legal/TERMS_OF_SERVICE.md)
  (entity, jurisdiction, contact, effective date).
- ☐ **(Recommended) Legal review** of both documents by qualified counsel.
- ☐ **Host** the Privacy Policy at a public, reachable URL.
- ☐ (Recommended) Host the Terms of Service at a public URL.
- ☐ AI-transparency wording is consistent across Privacy Policy, Terms, and both
  store listings.

## E. Firebase Console (production hardening — see [`../RELEASE.md`](../RELEASE.md) §7)

These degrade gracefully if skipped, but a production release should complete them:

- ☐ **App Check:** enable `firebaseappcheck.googleapis.com`, register **Play
  Integrity** for the release app (SHA-256), allow-list debug tokens as needed,
  then **enforce** only after real traffic validates ([`../RELEASE.md`](../RELEASE.md) §7.1).
- ☐ **Cloud Storage bucket:** Console → Storage → Get Started (may need Blaze),
  then `firebase deploy --only storage` to push the hardened `storage.rules`
  (§7.2). *(Until done, photo/logo/résumé uploads degrade to a localized error.)*
- ☐ **Firestore rules** current/deployed (§7.3).
- ☐ (Optional) Crashlytics/Performance Gradle plugins once AGP-9-compatible (§7.4).
- ☐ **AI Logic (Gemini)** provisioned and live (§7.5).
- ☐ (If phone auth used in prod) SMS region policy / test number (§7.6).

## F. Play Console — store presence

- ☐ Create the app with package `com.careerbridge.careerbridge` (first time).
- ☐ Main store listing (EN) from [`STORE_LISTING.md`](STORE_LISTING.md) §1.
- ☐ (Optional) Arabic translation from §2 (native-speaker reviewed).
- ☐ App icon, feature graphic, screenshots uploaded.
- ☐ Category = **Business**; tags set; contact email + website + privacy URL set.

## G. Play Console — app content declarations

- ☐ **Content rating** questionnaire submitted ([`PLAY_CONSOLE.md`](PLAY_CONSOLE.md) §1).
- ☐ **Target audience** = 18+ (§2).
- ☐ **Data safety** form completed ([`DATA_SAFETY.md`](DATA_SAFETY.md)).
- ☐ **Ads** = No; **IAP** = No (§4).
- ☐ **App access** — test logins + reviewer instructions provided (§5).
- ☐ **AD_ID** — verify merged manifest; declare "advertising ID not used" (§7).
- ☐ Government/financial/health/news declarations = No (§7).

## H. Pre-submission QA

- ☐ Run [`../QA_CHECKLIST.md`](../QA_CHECKLIST.md) end-to-end on a **release build**,
  **EN + AR**, **light + dark**.
- ☐ (Recommended before launch) a full **TalkBack** accessibility pass
  (documented follow-up in HANDOFF §7.19/§7.20).
- ☐ Cold-launch, offline behavior, and core seeker + employer flows verified.

## I. Release & rollout

- ☐ Upload the `.aab` to **Internal testing**; smoke-test.
- ☐ Promote to **Closed testing**; meet the tester count/duration policy
  ([`PLAY_CONSOLE.md`](PLAY_CONSOLE.md) §6).
- ☐ Create the **Production** release; **staged rollout** (10% → 50% → 100%).
- ☐ Monitor Crashlytics + Play vitals during rollout.

## J. Rollback readiness (know before you need it)

- ☐ Familiar with rollback options ([`../RELEASE.md`](../RELEASE.md) §12): halt
  staged rollout; promote previous known-good `.aab`; turn App Check enforcement
  **off** if it locks out clients; re-deploy prior `firestore.rules`/`storage.rules`.

---

## Sign-off

- Release version: __________ (`versionName+versionCode`)
- Built & signed by: __________  Date: __________
- All sections A–I complete: ☐
- Blocking issues: __________
- Non-blocking limitations documented in HANDOFF §7.19/§7.20 / RELEASE.md.
