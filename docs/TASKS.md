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
- ⬜ M2-1 Domain: `RegistrationData`, `DoctorProfileInput`, `RegisterAccount` use case
- ⬜ M2-2 Data: `POST /auth/register` (patient/doctor bodies exactly as documented)
- ⬜ M2-3 RoleChoice page (step counter, "Needs admin approval" pill)
- ⬜ M2-4 Register page (name, email, password, consent; 422 duplicate banner; field errors)
- ⬜ M2-5 RegisterDoctor page (licence, specialty, institution, city, country, phone, credential notes)
- ⬜ M2-6 VerifyEmail page + resend (60 s cooldown, neutral copy)
- ⬜ M2-7 Tests (serialization, cubits, widgets)

## M3 Password recovery
- ⬜ M3-1 Forgot password (always neutral message)
- ⬜ M3-2 Reset password (6 boxes, confirm field client-only, 400 invalid/expired → new code)
- ⬜ M3-3 Tests

## M4 Role homes · M5 Admin · M6 Google · M7 Hardening
- ⬜ See ROADMAP.md; tasks broken down when the milestone starts.
