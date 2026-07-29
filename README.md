# Wazifly

An AI-powered career platform that connects job seekers with employers through intelligent matching, AI-powered career tools, and a modern recruitment experience.

Wazifly helps candidates discover opportunities, improve their resumes, prepare for interviews, and manage applications, while enabling employers to post jobs, manage candidates, and make smarter hiring decisions.

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

---

# 📄 Documentation

Additional documentation can be found in:

- docs/
- HANDOFF.md
- SOURCE_CODE_GUIDE.md

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

---

# 👨‍💻 Developed For

Hackathon Project

Built using Flutter, Firebase, Riverpod, and AI technologies.

---

# 📜 License

This project is intended for educational, research, and hackathon purposes.
- Job discovery, matching, resume analysis, career coach, interview prep.
