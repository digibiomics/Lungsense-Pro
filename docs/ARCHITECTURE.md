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
| `features/*/domain` | Dart, `equatable`, `core/errors` | Flutter, Dio, JSON, storage |
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
| DI | app/di.dart | GetIt registrations |

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
| Signed out | `/welcome`, `/login`, `/sign-up`, `/forgot-password` | `/welcome` |
| Active patient | `/patient/**` | `/patient` |
| Active approved doctor | `/doctor/**` | `/doctor` |
| Active admin | `/admin/**` | `/admin` |
| Restricted (pending/rejected/suspended/deactivated/unknown) | `/account-status` | `/account-status` |
| Role `new` (Google) | `/role-selection` | `/role-selection` |

Unknown roles or statuses never grant access. Backend authorization stays authoritative.

## API contract (documented, used so far)

| Method | Path | Body | Used in |
|---|---|---|---|
| POST | /api/v1/auth/login | email, password | M1 ✅ |
| POST | /api/v1/auth/refresh | refresh_token | M1 ✅ |
| GET | /api/v1/users/me | Bearer | M1 ✅ |
| POST | /api/v1/auth/resend-confirmation | email | M1 ✅ (login banner) |
| POST | /api/v1/auth/register | see API docs | M2 |
| POST | /api/v1/auth/forgot-password · reset-password | email · email, otp_code, new_password | M3 |
| GET/POST | /api/v1/auth/google/authorize-url · token | – | M6 |
| POST | /api/v1/users/me/account-type | – | M6 |
| GET/POST/PATCH | /api/v1/admin/doctors · …/approve · …/reject · admin/users/{id}/status | – | M5 |

All paths are in `core/network/api_endpoints.dart`. Verified only against mocks so far (KI-01).

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
| Launcer Icon/android/adaptive-foreground.png, appstore.png, playstore.png, AppIcon.icon/ | – | Not yet used (store listing, adaptive icon in M7) |
| lungsense-pro-handoff/designs/*.dc.html | – | Layout/copy/state source of truth |
| lungsense-pro-handoff/lib_snippets/design_tokens.dart | – | Adapted into `core/theme/design_tokens.dart` |

Feature-row and status icons are Material icons (no matching asset supplied); the handoff draws them as inline SVG strokes.
