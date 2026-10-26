# LungSense Pro

Flutter app for doctors, patients and administrators collecting respiratory research data (cough, breathing, symptoms). Talks to the existing LungSense Pro FastAPI backend. Separate from LungSense Wellness: separate accounts, tokens and storage.

> Status: **0.2.0, every documented endpoint wired (M1–M7).** Sign-in, sign-up, email confirmation, password recovery, role areas, profile and admin doctor approvals are built and tested against mocked HTTP. **Not yet verified against the live backend** (it wasn't reachable from the build environment). Google sign-in is disabled until the server enables it. See [docs/PROJECT_STATE.md](docs/PROJECT_STATE.md) and [docs/KNOWN_ISSUES.md](docs/KNOWN_ISSUES.md).

## What works

| Area | Screens |
|---|---|
| Auth | Splash/session restore, Welcome, Sign in, Account status (pending/rejected/suspended) |
| Sign-up | Doctor or patient, account details, doctor details, Check your email + resend |
| Recovery | Forgot password (neutral), Reset with 6-digit code; Change password from Profile |
| Patient | Home, Check-ins, Profile (collection not available yet) |
| Doctor | Home, Patients, Sessions, Profile (collection not available yet) |
| Admin | Doctor approvals (tabs, review, approve, reject with reason), Users (info), Profile |
| Google | Button disabled; account-type screen ready for `role: new` users |

## Prerequisites

| Tool | Version used |
|---|---|
| Flutter | 3.47.8 stable |
| Dart | 3.13.7 |
| Android SDK / Xcode | For device builds (not used in CI so far) |

## Setup

```bash
cd lungsense_pro
flutter pub get
```

## Configuration

All settings are `--dart-define` values read in `lib/core/config/api_config.dart`. Ready-made files live in `config/`:

| File | Use |
|---|---|
| `config/development.json` | Dev API (HTTP, documented host) |
| `config/testing.json` | Test runs |
| `config/production.example.json` | Template. Copy to `config/production.json` (git-ignored) and set an **HTTPS** URL |

| Key | Default | Meaning |
|---|---|---|
| `API_BASE_URL` | `http://3.108.54.191` | Backend base URL (`/api/v1` is appended per endpoint) |
| `APP_ENV` | `development` | `development` / `testing` / `production` |
| `SUPPORT_EMAIL` | empty | Shown on rejected/suspended screens; empty hides it |
| `GOOGLE_SIGN_IN_ENABLED` | `false` | Reserved. Has no effect yet: the Google flow isn't wired until the server enables OAuth |

> **Security:** the documented API is plain HTTP. Use it for development only. Never send real credentials, OTPs, tokens or patient data over HTTP. Android allows cleartext to that host in **debug builds only**; iOS blocks it (see docs/KNOWN_ISSUES.md).

## Run

```bash
flutter run --dart-define-from-file=config/development.json
```

## Checks

```bash
dart format .
flutter analyze
flutter test                      # unit + widget (HTTP mocked)
# Live API contract tests (test backend only, needs test credentials):
flutter test --tags backend --run-skipped \
  --dart-define=LS_BACKEND_TESTS=true \
  --dart-define=LS_TEST_PATIENT_EMAIL=... --dart-define=LS_TEST_PATIENT_PASSWORD=...
```

## Project docs

| Doc | Purpose |
|---|---|
| [PROJECT_STATE](docs/PROJECT_STATE.md) | Where we are, next step |
| [ROADMAP](docs/ROADMAP.md) | Milestones |
| [TASKS](docs/TASKS.md) | Task checklist |
| [ARCHITECTURE](docs/ARCHITECTURE.md) | Layers, auth flow, API contract, assets |
| [FOLDER_STRUCTURE](docs/FOLDER_STRUCTURE.md) | Directory tree |
| [DECISIONS](docs/DECISIONS.md) | ADRs |
| [DEPENDENCIES](docs/DEPENDENCIES.md) | Packages |
| [KNOWN_ISSUES](docs/KNOWN_ISSUES.md) | Gaps, open backend questions |
| [CHANGELOG](docs/CHANGELOG.md) | Versions |
| [SESSION](docs/SESSION.md) | Session log |

Design source of truth: `../Design and icons/lungsense-pro-handoff/` (read-only).
