# Changelog

Format: [Keep a Changelog](https://keepachangelog.com). Versions follow `pubspec.yaml`.

## [0.1.0] – 2026-10-26 · M1 Auth foundation

### Added
- Flutter project `lungsense_pro` (Android, iOS), package `com.digibiomics.lungsense_pro`.
- Supplied launcher icons (Android mipmaps, iOS appiconset), logos and Public Sans font.
- `AppColors`, design tokens, `AppTheme`; widgets `LsButton`, `LsTextField`, `LsBanner`, `LsScreen`, wordmark, "Powered by DigiBiomics".
- `ApiConfig` with `--dart-define` env files (development, testing, production template).
- Dio client, `AuthInterceptor` (Bearer, refresh once, retry once, single-flight), `ErrorMapper` for FastAPI error shapes.
- `SecureTokenStorage` with `lungsense_pro.auth.*` keys.
- Auth domain/data: login, refresh, users/me, resend-confirmation, session policy.
- Screens: Splash (session restore + retry), Welcome, Sign in (all error variants), Account status, Patient/Doctor/Admin shells.
- GoRouter guard by backend role + status.
- 88 tests (unit, cubit, widget, full-app flow with mocked HTTP); 4 live API tests (skipped by default).
- docs/ project memory and README.
