# Wazifly

An AI-powered career platform that connects job seekers with employers through intelligent matching, AI-powered career tools, and a modern recruitment experience.

Wazifly helps candidates discover opportunities, improve their resumes, prepare for interviews, and manage applications, while enabling employers to post jobs, manage candidates, and make smarter hiring decisions.

---

# 📌 Project Status

The app is feature-complete and release-engineered: R8 release builds, deployed
Firestore rules, bundled fonts, and store/legal paperwork prepared. Two things
are deliberately not what they may appear, and are worth knowing before
evaluating:

- **The job catalogue job seekers browse is a bundled dataset** of 18 bilingual
  openings (`assets/data/seed_jobs.json`), not live Firestore data. Jobs an
  employer publishes go to Firestore and appear on that employer's dashboard.
- **Submitted applications are session-scoped** (in memory), so they do not
  survive a restart and do not reach an employer's applicant list.

Both sit behind the same repository interfaces the real implementations would,
so connecting them is a provider rebind rather than a rewrite. Full analysis:
[docs/TECHNICAL_AUDIT.md](docs/TECHNICAL_AUDIT.md).

---

# ✨ Features

## For Job Seekers

- AI Resume Analyzer
- AI Interview Preparation
- Smart Job Recommendations
- Intelligent Job Matching
- CV Builder
- Job Search & Filtering
- Internship Discovery
- Application Tracking
- Saved Jobs
- Career Recommendations
- Profile Management
- Learning Interests
- English & Arabic Support
- Dark & Light Theme

---

## For Employers

- Employer Dashboard
- Company Profile Management
- Company Logo Upload
- Job Creation & Management
- Applicant Tracking
- Candidate Matching
- AI Interview Kit
- Recruitment Analytics
- Resume Summary
- Candidate Notes
- Hiring Insights

---

## Security & Performance

- Firebase Authentication
- Cloud Firestore
- Firebase App Check
- Firebase Analytics
- Crash Reporting
- Secure Storage
- Biometric Authentication
- Offline Support
- Notification Preferences

---

# 🛠 Tech Stack

- Flutter
- Dart
- Firebase Authentication
- Cloud Firestore
- Firebase Storage
- Riverpod
- Go Router
- Material 3
- Gemini AI
- Flutter Animate

---

# 🚀 Getting Started

## Requirements

- Flutter 3.27+
- Dart 3.6+
- Firebase Project
- FlutterFire CLI

---

## Installation

```bash
git clone https://github.com/yshaltout0310-collab/Wazifly.git

cd Wazifly

flutter pub get

flutterfire configure

flutter run
```

---

## Firebase Setup

1. Create a Firebase project.

2. Enable:

- Authentication
- Cloud Firestore
- Firebase Storage
- Firebase Analytics
- Firebase App Check

3. Configure FlutterFire:

```bash
flutterfire configure
```

4. Deploy Firestore Rules:

```bash
firebase deploy --only firestore:rules
```

---

# 📱 Main Modules

- Authentication
- User Profiles
- Employer Portal
- Company Management
- Jobs
- Applications
- Resume Analyzer
- AI Interview Preparation
- Job Matching
- Career Recommendations
- CV Builder
- Internships
- Learning
- Settings
- Security

---

# 📂 Project Structure

```
lib/
│
├── core/
├── features/
│   ├── applications/
│   ├── auth/
│   ├── career_coach/
│   ├── cv_builder/
│   ├── cv_repository/
│   ├── employer/
│   ├── internships/
│   ├── interview_prep/
│   ├── job_matching/
│   ├── jobs/
│   ├── learning/
│   ├── profile/
│   ├── recommendations/
│   ├── resume_analyzer/
│   ├── security/
│   ├── settings/
│   └── splash/
│
└── shared/
```

Architecture follows a feature-first approach with clear separation between Presentation, Application, and Domain layers.

---

# 🌍 Localization

- English
- Arabic (RTL)

The localization system is designed to support additional languages with minimal configuration.

---

# 🤖 AI Features

- Resume Analysis
- Interview Preparation
- Job Matching
- Career Recommendations
- Employer Interview Assistant

---

# 🧪 Testing

The project includes extensive unit and widget tests covering major features and business logic.

Run tests using:

```bash
flutter test
```

Current state of the quality gates:

| Check | Result |
| --- | --- |
| `flutter analyze` | No issues found |
| `flutter test` | 696 tests pass (127 test files) |
| Line coverage | 67.0% |
| Localization parity | 1041 / 1041 keys, English ↔ Arabic |
| `flutter build web --release` | Succeeds |

---

# 📄 Documentation

| Document | Purpose |
| --- | --- |
| [SOURCE_CODE_GUIDE.md](SOURCE_CODE_GUIDE.md) | Full source walkthrough for reviewers — architecture, every subsystem, build & run |
| [docs/TECHNICAL_AUDIT.md](docs/TECHNICAL_AUDIT.md) | Evidence-backed audit: findings, severities, security review, recommendations |
| [docs/JUDGE_BRIEF.md](docs/JUDGE_BRIEF.md) | Demo script, architecture talking points and Q&A prep for a technical evaluation |
| [docs/REPLIT_DEPLOYMENT.md](docs/REPLIT_DEPLOYMENT.md) | Deploying the web build on Replit, including the Firebase console steps |
| [docs/RELEASE.md](docs/RELEASE.md) | Reproducible Android release runbook (keystore → Play upload) |
| [docs/PRODUCTION_READINESS.md](docs/PRODUCTION_READINESS.md) | Go/No-Go sign-off for Google Play |
| [docs/QA_CHECKLIST.md](docs/QA_CHECKLIST.md) | Pre-release manual QA sweep (EN + AR, light + dark) |
| [docs/store/](docs/store/) · [docs/legal/](docs/legal/) | Play listing, data safety, console declarations · privacy policy + terms templates |
| [HANDOFF.md](HANDOFF.md) | Running engineering log of every phase and milestone |

---

# 📦 Build Release

Android APK:

```bash
flutter build apk --release
```

Android App Bundle:

```bash
flutter build appbundle
```

Web:

```bash
flutter build web --release
```

The web target builds from a clean clone — `firebase_options.dart` carries the
web Firebase config. Biometrics, Crashlytics, push notifications and App Check
have no web implementation and disable themselves silently; everything else,
including all AI features, works. Note that `android/app/google-services.json`
is gitignored, so supply your own before building the **Android** target.

Deploying the web build to Replit (`.replit`, `replit.nix` and `tool/replit/`
are checked in): see [docs/REPLIT_DEPLOYMENT.md](docs/REPLIT_DEPLOYMENT.md).

---

# 👨‍💻 Developed For

Hackathon Project

Built using Flutter, Firebase, Riverpod, and AI technologies.

---

# 📜 License

This project is intended for educational, research, and hackathon purposes.
