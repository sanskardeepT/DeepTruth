# DeepTruth

> **In a world of lies, let DeepTruth be your eyes.**

DeepTruth is a powerful AI-driven fact-checking and digital intelligence app built with Flutter. It empowers users to verify news, investigate digital footprints, and separate truth from misinformation — all in real time.

## Features

- 🔍 **Truth Lens** — AI-powered fact-checking for news, claims, and URLs
- 📰 **Trust Feed** — Curated news with AI summaries and truth scores
- 🕵️ **TraceIQ** — OSINT toolkit for email breach checks, username lookups, IP tracing, and more
- 🤖 **AskIQ** — AI assistant for fact-based Q&A
- 🎬 **ReelIQ** — Reel & video claim verification
- 🔥 **Streak** — Gamified daily truth-checking with ranks and achievements
- 📄 **PDF Reports** — Generate and share verified intelligence reports

## Getting Started

1. **Clone the repo** and run `flutter pub get`
2. Set up your API keys in `lib/core/constants/api_keys.dart`
3. Run the app with `flutter run`

## Tech Stack

- **Framework**: Flutter (Dart)
- **AI**: Google Gemini
- **Backend**: Firebase (Firestore, Analytics, Crashlytics, Remote Config)
- **Monetization**: Google AdMob
- **Storage**: Hive (local), SharedPreferences
- **PDF**: `pdf` + `printing` packages
