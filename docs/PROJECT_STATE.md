# Project state

| Field | Value |
|---|---|
| Last updated | 2026-10-26 |
| Phase | Feature-complete for every documented endpoint |
| Current milestone | **M2–M7 done** (user said "complete the app", which approved all remaining milestones) |
| Next milestone | M8 live verification against the backend (needs a network that reaches it) |
| Branch | `main` |
| Latest commit | see `git log -1` (M2–M7 commit follows `8594383`) |
| App version | 0.2.0+2 |

## Completed
- M0 Inspect + plan.
- M1 Auth foundation (config, Dio, refresh interceptor, secure storage, errors, theme, splash, Welcome, Login, Account status, route guard).
- M2 Registration: RoleChoice (no preselection), Register, RegisterDoctor, Check your email + resend with 60 s cooldown, duplicate-email handling, field-level 422 errors.
- M3 Password recovery: Forgot (always neutral), Reset (6-digit code, confirm field client-only, 400 → invalid code, 422 → field error). Also reachable from Profile as "Change password".
- M4 Role areas with bottom navigation: Patient (Home, Check-ins, Profile), Doctor (Home, Patients, Sessions, Profile), shared Profile from `users/me` with pull-to-refresh. Collection features show honest empty/disabled states.
- M5 Admin: doctor approvals list (Pending/Approved/Rejected tabs), review screen, approve, reject with reason sheet. Users tab explains why status changes are unavailable.
- M6 First-time Google user (`role: new`) account-type screen via `POST /users/me/account-type`. Google sign-in itself stays disabled.
- M7 Hardening: Android adaptive launcher icon, removed placeholder pages, version 0.2.0, docs.
- Checks: `flutter analyze` no issues; `flutter test` 121 passed, 1 skipped group (live backend).

## In progress
- Nothing.

## Next step (exact)
1. From a machine that can reach `http://3.108.54.191`, run the live suite (README "Checks") and `flutter run` on a device.
2. Ask the backend team the open questions in KNOWN_ISSUES (KI-02, KI-03, KI-04, KI-06, KI-07, KI-14).
3. When the collection API is documented, start M8+ (recording flow).

## Blockers / open
- Backend not reachable from the cloud dev container (KI-01): **no endpoint has been verified live.**
- Admin list response shape and the user-status PATCH body are undocumented (KI-02).
- Google OAuth not configured on the server (KI-03).
