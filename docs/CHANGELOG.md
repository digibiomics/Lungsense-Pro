# Changelog

Format: [Keep a Changelog](https://keepachangelog.com). Versions follow `pubspec.yaml`.

## [0.2.0] – 2026-10-26 · M2–M7

### Added
- Registration: role choice, patient and doctor sign-up, consent, duplicate-email and field-level errors, Check your email with resend cooldown.
- Password recovery: neutral forgot-password, 6-digit reset with client-only confirm field; Change password from Profile.
- Role areas with bottom navigation for patient, doctor and admin; shared Profile with pull to refresh.
- Admin doctor approvals: list with tabs, review, approve, reject with reason.
- Account-type screen for first-time Google users (`role: new`).
- Android adaptive launcher icon from the handoff.
- Shared widgets: status pill, avatar, empty state, panel, key/value row, checkbox tile, choice card, bottom nav.
- 33 new tests (121 total): request bodies, admin parser, cubits, redirects, full-app flows with mocked HTTP.

### Changed
- Password-recovery routes are allowed while signed in.
- `LsPanel` is a `Material` so tappable rows show ink.

### Removed
- `UpcomingPage` placeholders and the M1 role shells.

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
