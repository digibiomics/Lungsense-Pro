# Architecture

## Layers (feature-first Clean Architecture)

```
presentation ──▶ domain ◀── data
 (widgets,       (entities,    (Dio, JSON models,
  cubits,         use cases,    remote data sources,
  pages)          repo contracts) repo impls)
```

| Layer | May import | Must not import |
|---|---|---|
| `features/*/domain` | Dart, `equatable`, `core/errors`, `core/utils/paged.dart` | Flutter, Dio, JSON, storage, plugins |
| `features/*/data` | domain, `core/network`, `core/storage`, Dio | presentation |
| `features/*/presentation` | domain, `core/theme`, `core/widgets`, bloc, go_router | data |
| `app/` (composition root) | everything | – |

`core/errors/failure.dart` is pure Dart and shared by all layers. The data layer converts every `DioException` into a `Failure` (`core/network/error_mapper.dart`).

## Runtime components

| Component | File | Role |
|---|---|---|
| `ApiConfig` | core/config/api_config.dart | Base URL, env, timeouts via `--dart-define` |
| `createDio` | core/network/api_client.dart | Single Dio, JSON, safe debug log (no bodies/headers) |
| `AuthInterceptor` | core/network/auth_interceptor.dart | Bearer header; 401 → refresh once → retry once |
| `SecureTokenStorage` | core/storage/token_storage.dart | Keychain/Keystore, keys `lungsense_pro.auth.*` |
| `AuthRepositoryImpl` | features/authentication/data/... | Login, restore, me, resend; single-flight `SessionRefresher` |
| `SessionOutcome.fromUser` | domain/entities/session_outcome.dart | Access policy from backend role + status |
| `SessionCubit` | presentation/cubit/session_cubit.dart | App-wide session state |
| `sessionRedirect` | app/session_redirect.dart | GoRouter guard (pure function, unit-tested) |
| DI | app/di.dart | GetIt registrations; `DeviceServices` (mic, player, picker, links) overridable for tests |
| `createUploadDio` | core/network/api_client.dart | Second Dio for presigned storage uploads: no base URL, no bearer token (ADR-025) |
| `CollectionEvents` | features/collection/presentation/cubit | Broadcast of changed session ids; lists, dashboard and overview reload on it (ADR-023) |
| `RecorderCubit` | features/collection/presentation/cubit | LsRecorder state machine (see below) |

## Auth flows

**Launch:** Splash → `RestoreSession`:
- no refresh token → SignedOut → Welcome (no network call)
- `POST /auth/refresh` → save tokens → `GET /users/me` → `SessionOutcome.fromUser`
- 400/401/422 → clear → Welcome · 403 `account_*` → clear → AccountStatus
- network/5xx/429 → keep tokens → Splash with "Try again"

**Login:** `POST /auth/login` (no auth header) → save tokens → `GET /users/me` → outcome. Non-active profile or 403 `account_*` → tokens cleared → AccountStatus. Other 403 codes (e.g. `wrong_role`) are errors, never "pending".

**Protected request:** interceptor adds `Authorization: Bearer`. On 401 (protected, not yet retried): if another request already refreshed, retry with the newer token; else `refreshAccessToken()` (concurrent callers share one call). Retry once. A failed refresh with 400/401/403/404/422 clears tokens and emits `sessionExpired` → SignedOut → Welcome. Connectivity failures keep the session.

**Logout:** local only (no logout endpoint documented): clear secure storage.

## Role routing (`sessionRedirect`)

| Session | Allowed | Otherwise → |
|---|---|---|
| Checking / restore failed | `/splash` | `/splash` |
| Signed out | `/welcome`, `/login`, `/sign-up`, `/sign-up/account`, `/sign-up/doctor`, `/verify-email`, `/forgot-password`, `/reset-password` | `/welcome` |
| Active patient | `/patient/**`, `/forgot-password`, `/reset-password` | `/patient` |
| Active approved doctor | `/doctor/**`, recovery routes | `/doctor` |
| Active admin | `/admin/**` (incl. `/admin/review/:id`), recovery routes | `/admin` |
| Restricted (pending/rejected/suspended/deactivated/unknown) | `/account-status` | `/account-status` |
| Role `new` (Google) | `/role-selection` | `/role-selection` |

Unknown roles or statuses never grant access. Backend authorization stays authoritative.

## Screens and routes

| Route | Screen | Notes |
|---|---|---|
| `/sign-up` → `/sign-up/account` → `/sign-up/doctor` | RoleChoice, Register, RegisterDoctor | One `RegistrationCubit` via `ShellRoute`; patients submit on step 2 |
| `/verify-email?email=&role=` | Check your email | Resend with 60 s cooldown |
| `/forgot-password?email=` · `/reset-password?email=` | Forgot, Reset | Also used signed-in from Profile |
| `/role-selection` | Account type (Google `new`) | `AccountTypeCubit` → `session.resolve(outcome)` |
| `/patient`, `/patient/check-ins`, `/patient/profile` | Patient tabs | `StatefulShellRoute.indexedStack` + `RoleScaffold` |
| `/doctor`, `/doctor/patients`, `/doctor/sessions`, `/doctor/profile` | Doctor tabs | Dashboard, Patients, Sessions, Profile |
| `/doctor/patients/new` | Add patient | Pops with the saved patient |
| `/doctor/patient/:id` · `/edit` | Patient detail · Edit | |
| `/doctor/collect?patient=&study=` | Start collection | `POST /collection/sessions` → overview |
| `/doctor/session/:id` | Overview (draft) or Session detail (completed) | Children: `cough`, `breathing`, `symptoms`, `context`, `review`, `submit` |
| `/patient/check-in/:id` (+ same children) | Patient check-in | Same screens, `CollectionMode.patient` copy |
| `/admin`, `/admin/users`, `/admin/profile` | Admin tabs | Approvals (3 status tabs), Users (search, suspend, reactivate) |
| `/admin/review/:id` | Review doctor | Application passed in `extra`; cold link → "Application not loaded" |

## API contract (documented endpoints and where they are used)

| Method | Path | Body sent | Used in |
|---|---|---|---|
| POST | /api/v1/auth/login | email, password | Login |
| POST | /api/v1/auth/refresh | refresh_token | Restore, 401 retry |
| GET | /api/v1/users/me | Bearer | Restore, login, Profile refresh |
| POST | /api/v1/auth/resend-confirmation | email | Login banner, Check your email |
| POST | /api/v1/auth/register | email, password, full_name, account_type, doctor_profile (doctor, incl. credential_notes) | Sign-up |
| POST | /api/v1/auth/forgot-password | email | Forgot |
| POST | /api/v1/auth/reset-password | email, otp_code, new_password (no confirm field) | Reset |
| POST | /api/v1/users/me/account-type | account_type, full_name, doctor_profile (doctor, no credential_notes) | Role selection |
| GET | /api/v1/admin/doctors?status= | – | Approvals: one call per tab status |
| POST | /api/v1/admin/doctors/{id}/approve | none | Review |
| POST | /api/v1/admin/doctors/{id}/reject | reason | Review |
| GET/POST | /api/v1/auth/google/authorize-url · token | – | **Not used** (KI-03) |
| GET | /api/v1/admin/users?search=&limit=&offset= | – | Users tab |
| PATCH | /api/v1/admin/users/{id}/status | account_status (active/suspended), reason? | Suspend / reactivate |
| GET | /api/v1/patients?search=&limit=&offset= | – | Patient list, Start collection |
| POST | /api/v1/patients | external_id, age_years, sex, consent_status, relevant_history, allow_duplicate | Add patient (409 possible_duplicate, KI-17) |
| GET · PATCH | /api/v1/patients/{id} | same fields, no allow_duplicate | Patient detail · Edit |
| POST | /api/v1/collection/sessions | patient_id (doctor) / {} (patient) | Start collection / check-in |
| GET | /api/v1/collection/sessions?status=&patient_id=&limit=&offset= | – | Sessions, drafts, patient detail, patient home |
| GET · PATCH | /api/v1/collection/sessions/{id} | notes | Overview, review, detail · clinical notes |
| POST | /api/v1/collection/sessions/{id}/complete | – | Submit (409 incomplete_session → missing items) |
| GET · PUT | /api/v1/collection/sessions/{id}/symptoms | all 10 ratings 0–3 | Symptoms |
| POST | /api/v1/collection/sessions/{id}/audio/upload-url | recording_type, content_type, file_size_bytes | Recorder → presigned POST → `POST /collection/audio/{id}/complete` |
| GET · DELETE | /api/v1/collection/audio/{id} · /download-url | – | QC polling, replace take, playback |
| POST | /api/v1/collection/sessions/{id}/xrays/upload-url | content_type, file_size_bytes, original_filename, view?, taken_on? | Clinical context → presigned POST → `POST /collection/xrays/{id}/complete` |
| DELETE · GET | /api/v1/collection/xrays/{id} · /download-url | – | Remove X-ray · View |
| GET | /api/v1/collection/dashboard | – | Doctor dashboard |

Not used: `GET/PUT /doctors/me` (profile editing not in scope yet), `/patients/me`, `/patients/by-study-id`, `/admin/users/{id}` and `/role`, `/admin/audit-logs`, `/admin/stats` (no design), and the non-`/api/v1` Wellness routes (ADR-022).

## Recorder state machine (`RecorderCubit`)

```
loading → idle ─record→ recording ─stop < min→ tooShort
                            └─stop ≥ min / auto-stop at max→ uploading → checking ─qc true→ passed
                                                                 │           ├─qc false / failed→ qualityFailed
                                                                 │           └─20 s no answer→ checkPending
                                                                 └─error→ uploadFailed ─Retry→ uploading
idle ─import─ length outside min–max → importInvalid · mic refused → micDenied
```
Continue is enabled in `passed` (and `checkPending`, KI-20). The server's `qc_reason` is shown verbatim.

All paths are in `core/network/api_endpoints.dart`. Auth bodies are built in `RequestModels`, patient bodies in `PatientModels`, collection bodies in `CollectionModels`. Collection, patient and admin-user calls are verified against mocks only (KI-24).

## Asset inventory

Source: `pro_app/Design and icons/` (never modified). Copied into `assets/images/` and referenced only via `AppAssets`.

| Source file | Size | App file / use |
|---|---|---|
| icons/LungSense Pro Clinical Logo.png | 1672×941, alpha | `logo_clinical_stacked.png` → Splash |
| icons/LungSense Pro Medical Logo.png | 1920×819, alpha | `logo_horizontal.png` → reserved for wide headers |
| icons/Respiratory Waves Medical App Icon.png | 1254², alpha | `app_icon_tile.png` → Welcome brand mark (72px) |
| icons/digibiomics-logo.png | 430×120, alpha | `digibiomics_logo.png` → "Powered by" (Welcome, Splash) |
| LungSense Pro Medical App Splash Screen.png | 941×1672, opaque | Reference only; Splash page recreates it from the logos |
| Launcer Icon/android/mipmap-*/ic_launcher.png | 48–192 | → `android/app/src/main/res/mipmap-*/` |
| Launcer Icon/Assets.xcassets/AppIcon.appiconset | 20–1024 | → `ios/Runner/Assets.xcassets/AppIcon.appiconset/` |
| Launcer Icon/android/adaptive-foreground.png | 1024² | Scaled to 432² → `drawable-nodpi/ic_launcher_foreground.png`; `mipmap-anydpi-v26/ic_launcher.xml` on white |
| appstore.png, playstore.png, AppIcon.icon/ | – | Not used (store listing / iOS 26 Icon Composer) |
| lungsense-pro-handoff/designs/*.dc.html | – | Layout/copy/state source of truth |
| lungsense-pro-handoff/lib_snippets/design_tokens.dart | – | Adapted into `core/theme/design_tokens.dart` |

Feature-row and status icons are Material icons (no matching asset supplied); the handoff draws them as inline SVG strokes.
