# Decisions (ADR log)

| ID | Date | Decision | Rationale |
|---|---|---|---|
| ADR-001 | 2026-10-26 | New project at `pro_app/lungsense_pro/` | No Flutter project existed; user confirmed "start fresh". Handoff stays read-only next to it. |
| ADR-002 | 2026-10-26 | Stack: Flutter 3.47.8, flutter_bloc (Cubit), GetIt, GoRouter, Dio, flutter_secure_storage | Matches brief; latest stable versions resolved by pub. |
| ADR-003 | 2026-10-26 | Domain errors are a pure-Dart `Failure` thrown by repositories (no Either type) | Keeps domain free of Dio/JSON without adding a functional library; `kind` + `code` cover all documented cases. |
| ADR-004 | 2026-10-26 | Access policy lives in domain (`SessionOutcome.fromUser`); router guard is a pure function | Single place for role/status rules; easy to unit-test; never uses a stored role. |
| ADR-005 | 2026-10-26 | Single-flight refresh in `AuthRepositoryImpl`; interceptor depends on `SessionRefresher` interface | `core` doesn't depend on features; app start-up and 401 handling share one refresh. |
| ADR-006 | 2026-10-26 | Clear session only when refresh is rejected (400/401/403/404/422) | Offline users keep their session and can retry. |
| ADR-007 | 2026-10-26 | Restricted accounts (pending, rejected, suspended, deactivated, unknown) are signed out | Backend flow: pending doctor stays logged out; fail closed on unknown values. |
| ADR-008 | 2026-10-26 | Bundle Public Sans TTFs instead of `google_fonts` | No runtime font download (privacy, offline), deterministic tests. Same typeface as handoff. |
| ADR-009 | 2026-10-26 | Google button visible on Login but disabled with "isn't available yet" | Design shows it; brief forbids implying it works. Enabled via `GOOGLE_SIGN_IN_ENABLED` in M6. |
| ADR-010 | 2026-10-26 | Pending-approval "Check again" becomes "Back to sign in" | User is logged out while pending, so the app can't re-check without signing in again. |
| ADR-011 | 2026-10-26 | Not-yet-built flows (`/sign-up`, `/forgot-password`, `/role-selection`) route to `UpcomingPage` | Links stay wired and honest between milestones. **Superseded in 0.2.0**: all three are built. |
| ADR-012 | 2026-10-26 | Login 400 "email not confirmed" detected by `detail.code` or message text | API documents two 400 cases with no code. Isolated in `mapLoginFailure`; revisit when backend confirms (KI-04). |
| ADR-013 | 2026-10-26 | Android cleartext allowed for the dev IP in **debug** manifest only | Lets developers hit the documented HTTP API; release stays HTTPS-only. |
| ADR-014 | 2026-10-26 | Role choice has no preselected option | The role can't be changed later, so it must be an explicit choice. |
| ADR-015 | 2026-10-26 | Admin list parser accepts an array or `{items|doctors|results|data: [...]}` and throws on anything else | Schema undocumented (KI-02). Tolerant to likely shapes, but never shows an empty list for a response it doesn't understand. |
| ADR-016 | 2026-10-26 | `PATCH /admin/users/{id}/status` is not implemented; Users tab says why | Body and allowed values undocumented; brief forbids inventing them. **Superseded by ADR-022** (spec now documents it). |
| ADR-017 | 2026-10-26 | Google sign-in stays disabled; only the account-type step for `role: new` is built | Server isn't configured (KI-03); the account-type endpoint is documented and usable once it is. Supersedes the M6 part of ADR-009. |
| ADR-018 | 2026-10-26 | Forgot/reset password routes are reachable while signed in | Serves "Change password" from Profile without a separate (undocumented) endpoint. |
| ADR-019 | 2026-10-26 | Admin review receives the application through router `extra`; a cold deep link shows "Application not loaded" | No single-application endpoint is documented. |
| ADR-020 | 2026-10-26 | Collection features render disabled actions and empty states | No collection/patient API is documented; screens never show fabricated data. **Superseded by ADR-023.** |
| ADR-021 | 2026-10-26 | Forgot password shows the neutral result for every server answer except offline, 429 and 5xx | Never reveals whether an email is registered, while still telling users when to retry. |
| ADR-022 | 2026-10-27 | `docs/openapi_snapshot.json` (server API v0.3.0) is the contract; only `/api/v1` routes are used | It documents admin users/status, patients and collection. The older non-`/api/v1` Wellness routes (`/checkins`, `/score/*`, …) are not used: the design forbids scores in Pro. |
| ADR-023 | 2026-10-27 | Every collection step saves to the server itself; screens re-read the session instead of sharing local state | Drafts survive leaving the app; success is never shown before the server confirms; `CollectionEvents` tells lists and the overview to reload. |
| ADR-024 | 2026-10-27 | Collection cubits depend on the `CollectionRepository` contract directly (no per-call use cases) | The calls carry no domain logic beyond the contract; a thin use case per endpoint would add 18 pass-through classes. Patients and admin keep use cases (input trimming). |
| ADR-025 | 2026-10-27 | Uploads use a separate Dio (`createUploadDio`) with no base URL and no bearer token | The presigned POST goes to storage; the API token must never be sent there. Fields first, file last. |
| ADR-026 | 2026-10-27 | Device access (mic, player, picker, links) sits behind domain interfaces (`device_services.dart`), injected through `DeviceServices` | Keeps Flutter plugins out of cubits and lets tests drive the recorder state machine without hardware. |
| ADR-027 | 2026-10-27 | Re-recording keeps a passed recording until a new one passes, then deletes the older ones; a failed-QC recording is deleted when the user records again | The session never loses its last good recording, and the server is not left with failed takes. Deletes are best effort. |
| ADR-028 | 2026-10-27 | Diagnosis picker left out; symptom copy isolated in one file | No API field (KI-18) and no approved wording for 8 symptoms (KI-19). Nothing is invented; both wait for the product owner. |
| ADR-029 | 2026-10-27 | Add patient also records research consent (`consent_status`) | The API stores it and the study needs it; unticking a previously given consent sends `withdrawn`, never a silent reset. Patient detail warns when consent is not recorded. |
| ADR-030 | 2026-10-27 | Approval tabs read `GET /admin/doctors?status=` once per status (pending_approval, active, rejected) | The endpoint filters by one status (default pending), so a single call left the Approved and Rejected tabs empty. |
