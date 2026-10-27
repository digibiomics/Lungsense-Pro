# Tasks

Legend: ✅ done · ⏳ in progress · ⬜ todo · ⛔ blocked

## M0 Inspect + plan
- ✅ M0-1 Inventory workspace (no Flutter project found)
- ✅ M0-2 Inventory handoff designs, icons, launcher icons, splash
- ✅ M0-3 Plan milestones (ROADMAP.md)

## M1 Auth foundation
- ✅ M1-1 Create Flutter project `lungsense_pro` (android, ios), git init
- ✅ M1-2 Copy assets + Public Sans; `AppAssets` registry; launcher icons (Android mipmaps, iOS appiconset)
- ✅ M1-3 `AppColors`, design tokens, `AppTheme`
- ✅ M1-4 Widgets: `LsButton`, `LsTextField`, `LsBanner`, `LsScreen`, brand widgets
- ✅ M1-5 `ApiConfig` + env files; `ApiEndpoints`
- ✅ M1-6 `Failure` + `ErrorMapper` (string / structured / 422 list)
- ✅ M1-7 `TokenStorage` (secure, `lungsense_pro.` namespace)
- ✅ M1-8 `AuthInterceptor` (attach, refresh once, retry once, single-flight)
- ✅ M1-9 Auth domain: entities, `SessionOutcome` policy, repository contract, use cases
- ✅ M1-10 Auth data: models, remote data source, `AuthRepositoryImpl`
- ✅ M1-11 `SessionCubit`, `LoginCubit`
- ✅ M1-12 Pages: Splash, Welcome, Login, AccountStatus, Patient/Doctor/Admin shells
- ✅ M1-13 GoRouter + `sessionRedirect` guard
- ✅ M1-14 Tests: 88 passing (unit, cubit, widget, full-app flow); 4 live tests written, skipped
- ✅ M1-15 Android INTERNET permission, debug-only cleartext, app labels
- ✅ M1-16 docs/ + README

## M2 Registration
- ✅ M2-1 Domain: `RegistrationRequest`, `DoctorProfileInput`, `AccountType`, `RegisterAccount`
- ✅ M2-2 Data: `POST /auth/register` with exact documented bodies (`RequestModels`)
- ✅ M2-3 RoleChoice page (no preselection, step counter)
- ✅ M2-4 Register page (name, email, password, consent; duplicate banner; field errors)
- ✅ M2-5 RegisterDoctor page (licence, specialty, institution, city, country, phone, credential notes)
- ✅ M2-6 VerifyEmail page + resend (60 s cooldown, neutral copy)
- ✅ M2-7 Tests (request bodies, cubit guards, full-app sign-up flows)

## M3 Password recovery
- ✅ M3-1 Forgot password (neutral result unless offline / 429 / 5xx)
- ✅ M3-2 Reset password (6 boxes, confirm client-only, 400 → invalid code + new code link, 422 → field error)
- ✅ M3-3 Signed-in "Change password" from Profile reuses the same screens
- ✅ M3-4 Tests

## M4 Role areas
- ✅ M4-1 `LsBottomNav`, `RoleScaffold`, per-role `StatefulShellRoute`
- ✅ M4-2 Patient Home + Check-ins (empty, check-in disabled until collection API exists)
- ✅ M4-3 Doctor Home, Patients, Sessions (empty, "Start new collection" disabled)
- ✅ M4-4 Profile from `users/me`, pull to refresh, change password, sign out, version

## M5 Admin
- ✅ M5-1 Domain/data for list, approve, reject (tolerant list parser, fails loudly on unknown shapes)
- ✅ M5-2 Approvals list with tabs + review screen + reject reason sheet
- ✅ M5-3 Users tab explains missing list endpoint / undocumented status body
- ✅ M5-4 Change user status (`PATCH /admin/users/{id}/status`), built in M9

## M6 Google
- ✅ M6-1 Account-type screen for `role: new` (`POST /users/me/account-type`, no credential_notes)
- ⛔ M6-2 Google PKCE sign-in: server not configured (KI-03)

## M7 Hardening
- ✅ M7-1 Android adaptive icon (handoff foreground, white background)
- ✅ M7-2 Remove `UpcomingPage` placeholders
- ✅ M7-3 Docs, version 0.2.0+2
- ⬜ M7-4 Native splash, HTTPS + iOS ATS (KI-05, KI-10)

## M9 Admin users + patients (0.3.0)
- ✅ M9-1 `GET /admin/users` search + paging, suspend (reason) / reactivate, no self-suspend
- ✅ M9-2 Approval tabs read `?status=` for pending, active, rejected
- ✅ M9-3 Patients domain/data (list, get, create with `allow_duplicate`, update)
- ✅ M9-4 Patient list, Add/Edit patient (reference, age, sex, notes, consent), 409 duplicate banner
- ✅ M9-5 Patient detail with sessions and Start new collection

## M10 Collection flow (0.3.0)
- ✅ M10-1 Collection domain/data: sessions, symptoms, audio and X-ray upload tickets, presigned POST, complete, dashboard
- ✅ M10-2 Device services behind interfaces (record, just_audio, file_picker, url_launcher)
- ✅ M10-3 `RecorderCubit` state machine + `RecorderPage` (cough, breathing, import validation, QC polling, retry, playback)
- ✅ M10-4 Overview, Symptoms (10 items), Clinical context (notes, X-ray), Review, Submit result, Session detail
- ✅ M10-5 Start collection (choose or register patient)
- ⛔ M10-6 Diagnosis picker: no API field (KI-18)
- ⛔ M10-7 Descriptors for 8 symptoms: no approved text (KI-19)

## M11 Sessions + dashboard (0.3.0)
- ✅ M11-1 Session history with filters, grouped by day
- ✅ M11-2 Dashboard counts, drafts to finish, recent activity

## M12 Patient check-in (0.3.0)
- ✅ M12-1 Patient home: start or resume today's check-in
- ✅ M12-2 My check-ins grouped by week; collection screens in patient mode

## M13 Device verification
- ⬜ M13-1 Record, upload and submit on Android and iOS with a test doctor and a test patient
- ⬜ M13-2 Confirm KI-17, KI-20, KI-21, KI-22 against real responses

## M8 Live verification
- ⬜ M8-1 Run `--tags backend` suite against the test backend
- ⬜ M8-2 Device builds (Android, iOS)
