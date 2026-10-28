# Changelog

Format: [Keep a Changelog](https://keepachangelog.com). Versions follow `pubspec.yaml`.

## [Unreleased]

### Added
- "Remove draft" ("Remove this check-in" for patients) on the collection overview, with a confirm sheet. The API has no session delete (KI-25), so the draft is hidden on this device only; the server keeps it.
- Drafts not finished on the day they started are no longer listed or offered to resume (Sessions, dashboard, Patient home); opening one shows it read-only. Overview copy now says "later today".
- 9 tests (draft rules, paging past hidden drafts, dashboard, remove flow).
- Patient record fields chosen by the product owner: full name, age, gender, smoking status (required), height in cm, weight in kg and relevant history (optional). Add/Edit patient collects them (plus hospital reference and consent as before), Patient detail shows them, and patients see and edit their own on Profile ("My details", `PATCH /patients/me`). "Gender" is the API's `sex` field (male, female, other).
- 3 tests (self-update body, record parsing, My details flow); add-patient and patient-detail tests cover the new fields.

### Fixed
- Patient home: a completed check-in no longer hides "Start check-in". Patients can start another check-in the same day ("Start another check-in", with "View today's check-in" below); the API keeps every check-in.
- Patient check-in no longer dead-ends on "Research consent must be recorded before collecting data." Patient home reads the patient's own record (`GET /patients/me`) and, while consent is not given, shows a consent step that records it with `PATCH /patients/me` (`consent_status: given`) before Start check-in appears.

## [0.3.0] – 2026-10-27 · M9–M12

### Added
- Admin Users tab: search, paging, suspend (optional reason) and reactivate via `PATCH /admin/users/{id}/status`; a toast only after the server confirms.
- Patients: list with server search and paging, add patient (hospital reference, age, sex, notes, research consent) with the `409 possible_duplicate` warning and "save anyway", patient detail with its sessions, edit.
- Collection flow for doctors and patients: start collection, overview, `LsRecorder` for cough (12–15 s) and breathing (25–30 s) with mic level, auto-stop, too-short and import-length checks, presigned upload with progress, server quality check (verbatim reason), retry, playback; symptoms (10 items, 0–3, no preselection, one PUT); clinical context (notes, chest X-ray upload/remove); review with server-reported missing items and confirm sheet; submit result (submitting, success, missing items, failed); read-only session detail with X-ray links.
- Session history with All/Drafts/Completed filters; doctor dashboard counts, drafts to finish, recent activity, attention banner.
- Patient home: start or resume today's check-in; My check-ins grouped by week.
- Shared widgets: `LsCollectionHeader`, `LsStepIcon`/`LsStepRow`, `LsSeverityScale`, `LsConfirmSheet`, `showLsToast`, `LsSearchField`.
- Packages: record, just_audio, file_picker, path_provider, url_launcher; dev: fake_async.
- Android `RECORD_AUDIO`; iOS microphone and photo library usage strings.
- 37 new tests (157 total): recorder state machine, request bodies and parsers, presigned upload, admin/patient/collection/check-in UI flows.

### Changed
- Approval tabs load each status (`?status=`), so Approved and Rejected are no longer empty.
- `LsKeyValueRow` labels wrap instead of overflowing.
- Rejection reason read from `doctor_profile.rejection_reason` (documented location).

### Removed
- Empty-state placeholder pages for patients, sessions and check-ins.

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
