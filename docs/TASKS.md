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
- ⛔ M5-4 Change user status (`PATCH /admin/users/{id}/status`): body undocumented (KI-02)

## M6 Google
- ✅ M6-1 Account-type screen for `role: new` (`POST /users/me/account-type`, no credential_notes)
- ⛔ M6-2 Google PKCE sign-in: server not configured (KI-03)

## M7 Hardening
- ✅ M7-1 Android adaptive icon (handoff foreground, white background)
- ✅ M7-2 Remove `UpcomingPage` placeholders
- ✅ M7-3 Docs, version 0.2.0+2
- ⬜ M7-4 Native splash, HTTPS + iOS ATS (KI-05, KI-10)

## M8 Live verification
- ⬜ M8-1 Run `--tags backend` suite against the test backend
- ⬜ M8-2 Device builds (Android, iOS)
