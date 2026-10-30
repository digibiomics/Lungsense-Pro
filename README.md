# LungSense Pro

LungSense Pro is a cross-platform mobile application for clinical respiratory research. It lets doctors, patients and study administrators capture standardised cough and breathing recordings, symptom scores and clinical context, and submit them securely to the LungSense Pro research platform.

The app is built with Flutter and runs on Android and iOS.

## Key features

**For doctors**
- Patient registry with search, paging, duplicate detection and research consent tracking
- Guided collection sessions: cough and breathing recordings, a 10-item symptom questionnaire, clinical notes and chest X-ray upload
- Session history with draft, completed and filtered views, plus a dashboard of recent activity

**For patients**
- Self-guided daily check-ins, with consent captured in the app
- A personal check-in history and editable personal details

**For administrators**
- Review, approve and reject doctor registrations
- User management, including suspension and reactivation

**Platform**
- Secure sign-in, email verification and password recovery
- Role-based access for doctors, patients and administrators
- Built-in recording quality checks: duration limits, level metering, server-side quality validation and retry
- Direct-to-storage uploads with progress reporting

## Technology

| Area | Choice |
|---|---|
| Framework | Flutter (Dart 3) |
| State management | `flutter_bloc` |
| Navigation | `go_router` |
| Networking | `dio` |
| Dependency injection | `get_it` |
| Secure storage | `flutter_secure_storage` |
| Audio | `record`, `just_audio` |
| Testing | `flutter_test`, `bloc_test`, `mocktail` |

The code follows a feature-first, layered architecture (data, domain, presentation). See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for details.

## Getting started

### Prerequisites

- Flutter SDK (stable channel) with Dart 3.13 or later
- Android Studio with the Android SDK, and/or Xcode for iOS builds
- Access to a LungSense Pro backend environment

### Installation

```bash
git clone https://github.com/digibiomics/Lungsense-Pro.git
cd Lungsense-Pro
flutter pub get
```

### Configuration

The app is configured at build time with `--dart-define` values. Environment files live in the `config/` folder:

| File | Purpose |
|---|---|
| `config/development.json` | Local development |
| `config/testing.json` | Automated tests |
| `config/production.example.json` | Template for production. Copy it to `config/production.json`, which git ignores, and fill in your values. |

| Key | Description |
|---|---|
| `API_BASE_URL` | Base URL of the LungSense Pro API |
| `APP_ENV` | `development`, `testing` or `production` |
| `SUPPORT_EMAIL` | Support contact shown to users when an account needs attention |
| `GOOGLE_SIGN_IN_ENABLED` | Reserved for future Google sign-in support |

Backend addresses and credentials are provided to authorised team members and are not published in this repository. Production builds must use an HTTPS endpoint.

### Running the app

```bash
flutter run --dart-define-from-file=config/development.json
```

## Quality checks

```bash
dart format .
flutter analyze
flutter test
```

The test suite covers unit and widget tests, with all network traffic mocked. Contract tests against a live test backend are tagged `backend` and are skipped by default.

## Documentation

| Document | Contents |
|---|---|
| [Architecture](docs/ARCHITECTURE.md) | Layers, authentication flow and API integration |
| [Folder structure](docs/FOLDER_STRUCTURE.md) | Project layout |
| [Decisions](docs/DECISIONS.md) | Architecture decision records |
| [Dependencies](docs/DEPENDENCIES.md) | Packages and why they are used |
| [Roadmap](docs/ROADMAP.md) | Milestones |
| [Changelog](docs/CHANGELOG.md) | Release history |
| [Known issues](docs/KNOWN_ISSUES.md) | Open items and limitations |

## Data protection

LungSense Pro handles health-related research data. Do not use real patient data outside approved, secured environments. Never commit credentials, tokens, environment-specific endpoints or patient information to this repository.

## License

Copyright © DigiBiomics. All rights reserved. This software is proprietary and may not be used, copied or distributed without written permission.
