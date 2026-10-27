# Dependencies

Resolved with Flutter 3.47.8 / Dart 3.13.7 (see `pubspec.lock`).

## Runtime

| Package | Version | Purpose |
|---|---|---|
| dio | 5.11.1 | HTTP client, interceptors |
| flutter_bloc | 9.1.1 | Cubits for session/login state |
| equatable | 3.0.0 | Value equality for entities and states |
| get_it | 9.3.0 | Dependency injection (composition root `app/di.dart`) |
| go_router | 18.1.1 | Routing + redirect guard |
| flutter_secure_storage | 11.2.0 | Tokens in Keychain / Keystore |
| cupertino_icons | 1.0.9 | Flutter template default |
| record | 7.1.2 | Microphone recording (AAC/M4A) and input level |
| just_audio | 0.10.6 | Playback and imported-file duration check |
| file_picker | 13.3.0 | Import an audio file; attach an X-ray |
| path_provider | 2.1.x | Temporary folder for recordings |
| url_launcher | 6.3.3 | Open an X-ray download link |

## Dev

| Package | Version | Purpose |
|---|---|---|
| flutter_test | SDK | Unit/widget tests |
| integration_test | SDK | Reserved for device integration tests (M7) |
| mocktail | 1.0.5 | Explicit mocks (labelled in tests) |
| fake_async | 1.3.3 | Drives the recorder timer and QC polling in unit tests |
| bloc_test | 10.0.0 | Cubit tests |
| flutter_lints | 6.0.0 | Lint rules |

## Bundled assets

| Asset | Licence |
|---|---|
| Public Sans 400/500/600/700 (npm `public-sans` 0.1.7-1, USWDS) | OFL-1.1 (`assets/fonts/OFL-PublicSans.md`) |

## Planned (not added yet)

| Package | Milestone | Why |
|---|---|---|
| flutter_web_auth_2 | M6 | Browser OAuth session for Google PKCE |
| crypto | M6 | SHA-256 for PKCE code challenge |
