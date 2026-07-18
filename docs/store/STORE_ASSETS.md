# Wazifly — Store Assets Specifications

> **Specifications and a capture plan only — no graphic assets are generated in
> this milestone.** Each entry lists the exact Play requirement, the brand
> source already in the repo, and production guidance. Brand colors: emerald
> `#0E9F6E` (icon), `#0B7D57` (splash), dark `#101413` — must match
> `lib/core/theme/app_colors.dart`.

---

## 1. App icon (required)

| Spec | Value |
| --- | --- |
| Dimensions | **512 × 512 px** |
| Format | 32-bit PNG (with alpha) |
| Max size | 1 MB |
| Shape | Full square; Play applies the launcher mask |

- **Source in repo:** `assets/icon/app_icon.png` (1024², emerald `#0E9F6E`
  background). Export/downscale a **512×512** PNG for the Console — do **not**
  add rounded corners or shadow (Play masks it).
- The on-device adaptive icon (foreground `assets/icon/ic_foreground.png` +
  background `assets/icon/ic_background.png`) is already generated via
  `flutter_launcher_icons`; the 512 store icon is a separate upload.

## 2. Feature graphic (required)

| Spec | Value |
| --- | --- |
| Dimensions | **1024 × 500 px** |
| Format | PNG or JPG (no alpha) |
| Max size | 1 MB |

- **Layout guidance:** emerald gradient background (`#0B7D57` → `#0E9F6E`), the
  Wazifly logo/wordmark, and a short tagline (e.g. *"AI career platform
  for job seekers & employers"*). Keep text within the central safe area —
  Play may overlay the install button and crop edges on some surfaces.
- Provide an **Arabic variant** if publishing the Arabic listing (same layout,
  RTL tagline: *«منصّة مهنية بالذكاء الاصطناعي»*).

## 3. Phone screenshots (required — 2 to 8)

| Spec | Value |
| --- | --- |
| Count | Minimum 2, **recommend 6–8** |
| Format | PNG or JPG |
| Min dimension | 320 px (shorter side) |
| Max dimension | 3840 px (longer side) |
| Aspect | 16:9 or 9:16 (portrait recommended) |

### Recommended screenshot order (strongest features first)

Play shows the first 2–3 thumbnails most prominently, so lead with the app's
highest-impact, most differentiated screens. This order balances the Job Seeker
and Employer sides while front-loading the "wow" AI features:

| # | Screen | Why it's placed here | Caption idea |
| --- | --- | --- | --- |
| 1 | **Resume Analyzer results** (ATS score gauge + strengths/gaps) | Strongest, most visual "wow" — instantly communicates the AI value. | "Instant AI resume analysis & ATS score" |
| 2 | **AI Job Matching** (ranked jobs with % + reason) | Core seeker value; shows personalization at a glance. | "Jobs ranked to your profile by AI" |
| 3 | **Home — AI toolkit grid** | Orients the viewer: shows the breadth of tools in one shot. | "Your complete AI career toolkit" |
| 4 | **Career Coach** (chat) or **CV Builder** (PDF preview) | Demonstrates depth of the seeker experience. | "Chat with your AI career coach" / "Build an ATS-ready CV" |
| 5 | **Employer Dashboard / Analytics** (funnel + AI insights) | Introduces the employer side — the platform is two-sided. | "Hire smarter with AI recruiter insights" |
| 6 | **Applicants management** (candidates + status pipeline) | Reinforces the employer workspace. | "Review candidates with AI match insights" |
| 7 | **Interview Prep** (scored feedback) *(optional)* | Extra seeker depth. | "Practice interviews with scored feedback" |
| 8 | **Arabic (RTL) screen** — e.g. Home or Job Matching in العربية *(optional)* | Proves full bilingual/RTL support to Arabic-market users. | "Full Arabic & right-to-left support" |

> Aim for **at least one seeker screen and one employer screen in the first
> five** so both audiences see themselves. If publishing the Arabic listing,
> upload an **Arabic-language screenshot set** captured with the app in Arabic.

### Capture guidance
- Capture on the **release build** for accurate branding/fonts.
- Per HANDOFF §10 emulator quirks: run the emulator with **`-gpu host`** and the
  app with **`--no-enable-impeller`** (Skia) so `adb screencap` is reliable and
  not stale.
- Optional: add device frames + captions in a design tool, but raw screenshots
  are acceptable.

## 4. Tablet screenshots (optional but recommended for reach)

| Spec | Value |
| --- | --- |
| 7-inch | up to 8, JPG/PNG, min 320 px |
| 10-inch | up to 8, JPG/PNG, min 320 px |

Reuse the same screen order as phone. Only needed if you want the app featured
as tablet-optimized.

## 5. Promotional assets (optional)

| Asset | Spec | Notes |
| --- | --- | --- |
| Promo video | YouTube URL | 30–120 s walkthrough; optional, boosts conversion. |
| (Legacy) Promo graphic | 180 × 120 px | Deprecated on modern Play; skip unless a surface requires it. |

## 6. Asset production checklist

- ☐ 512×512 app icon exported from `assets/icon/app_icon.png` (no rounded corners).
- ☐ 1024×500 feature graphic (EN) — brand gradient + logo + tagline.
- ☐ (If AR listing) 1024×500 feature graphic (AR).
- ☐ 6–8 phone screenshots (EN) in the recommended order above.
- ☐ (If AR listing) phone screenshots captured in Arabic.
- ☐ (Optional) 7"/10" tablet screenshots.
- ☐ (Optional) promo video URL.
- ☐ All assets within Play size/format limits; text inside safe areas.

> All brand sources live under `assets/icon/`. Do not commit exported store
> assets into the app bundle — they are Console uploads, not shipped resources
> (see [`../RELEASE.md`](../RELEASE.md) §10, reserved/generated assets).
