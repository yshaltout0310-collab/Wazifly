# Career Bridge — Production QA Checklist

> Run before every release, on a **release build** where possible. Cover **both
> languages (English LTR + Arabic RTL)** and **both themes (light + dark)** — the
> app's standing verification discipline. Tick every box or file a blocker.

Legend: ☐ = to verify · target device: a healthy emulator/phone, API ≥ 31 for the
Android-12 splash path.

---

## 1. Build & launch
- ☐ `flutter analyze` clean; `flutter test` all pass.
- ☐ Release APK **and** AAB build (R8 succeeds).
- ☐ App installs and cold-launches without a crash.
- ☐ App Check active (logcat: `DefaultTokenRefresher`); with enforcement off, a
  placeholder-token fallback keeps the app usable.
- ☐ No debug-only artifacts (debug banner off — `debugShowCheckedModeBanner: false`).

## 2. Branding
- ☐ Launcher icon shows the emerald mark (all densities); adaptive icon
  foreground is centered within the safe mask (round + squircle launchers).
- ☐ Themed/monochrome icon acceptable on Android 13+ themed-icons.
- ☐ Native splash shows the brand color (`#0B7D57`) → logo, **no white flash**
  before the Flutter splash; correct on API < 31 and API ≥ 31.
- ☐ In-app animated splash (emerald + logo) transitions cleanly to the first screen.
- ☐ App label reads "Career Bridge" in the launcher and recents.
- ☐ Dark-mode splash uses the dark background (`#101413`).

## 3. Localization & fonts (EN + AR)
- ☐ Switch language in Settings → whole app re-renders in the chosen language.
- ☐ **Arabic is full RTL** — layouts mirror, text right-aligns, chips/timelines flow RTL.
- ☐ **Fonts render from the bundle** — Inter (Latin) and Cairo (Arabic) glyphs, not
  a platform fallback. Verify **offline** too (see §5).
- ☐ No text overflow / clipping in either language (the `render_all_locales` test
  is the backbone; spot-check long Arabic labels live).

## 4. Core flows (smoke, both roles)
- ☐ Auth: email register/login; role selection (Job Seeker / Employer) lands on the
  correct home; logout clears the role.
- ☐ Seeker: Home AI toolkit tiles open; Resume Analyzer / Job Matching / Coach /
  CV Builder / Interview Prep / For You render; Jobs browse + detail; Applications.
- ☐ Employer: Home stats; My Jobs (create → auto-save → preview → publish);
  Applicants inbox + detail + status change; Analytics dashboard + AI insights.
- ☐ Settings / Profile: edit + save; change password entry; notification toggles.

## 5. Offline readiness
- ☐ **Airplane mode, cold start:** app launches; text renders with bundled fonts
  (no FOUT / fallback font).
- ☐ The **offline banner** appears ("You're offline — showing saved data" / Arabic);
  it does not block interaction.
- ☐ Firestore-backed screens (employer Home/Analytics) render from the **offline
  cache**.
- ☐ Network features (AI, uploads) show the existing **graceful error** messages,
  not crashes.
- ☐ Restore connectivity → the offline banner **auto-hides**; data refreshes.

## 6. Accessibility (verify live; document remaining limits in HANDOFF/RELEASE)
- ☐ **Tap targets** — interactive controls are ≥ 48×48 dp (Material minimum). Check
  icon buttons (app-bar gear/back, bookmark, overflow menus), chips, and the FAB.
- ☐ **Screen reader (TalkBack)** — enable and traverse a primary flow: buttons,
  images, and icons announce a meaningful label (not "unlabeled"); avatars/logos
  are either labeled or marked decorative; the offline banner is announced.
- ☐ **Text scaling** — set system font size to Largest (≈ 1.3–2.0×): screens remain
  usable, no critical clipping/overlap on Home, Settings, a form, and a dashboard.
- ☐ **Contrast** — primary text on emerald surfaces and on cards meets ~WCAG AA
  (4.5:1 body / 3:1 large). Verify the offline banner (white on `#101413`), primary
  buttons (white on emerald), and secondary/hint text.
- ☐ **Focus & dismissal** — dialogs/sheets are reachable and dismissible; keyboard
  (soft) does not trap focus.
- ☐ **Orientation/locale changes** don't lose state (config changes handled).

## 7. Regression (recent milestones)
- ☐ Hardened Firestore rules (P6·M2): employer read/write flows still work.
- ☐ Image decode-downsizing (P6·M2): avatars/logos render; error fallback shows an
  initial, not a blank circle.
- ☐ Telemetry (P6·M1): screen_view/events fire; consent lever respected; crash
  reports carry `app_version` + `build_type` (BuildInfo).

---

## Sign-off
- Verified by: __________  Date: __________  Build: __________ (versionName+code)
- Blocking issues: __________
- Non-blocking limitations documented in HANDOFF §7.19 / RELEASE.md.
