# Session log

## 2026-10-26 · Session 1 · M0 + M1

**Goal:** inspect workspace, plan, build auth foundation, stop for approval.

### Work done
- Inspected `pro_app/`: only `Design and icons/` existed (handoff, icons, launcher icons, splash). User chose "start fresh".
- Installed Flutter 3.47.8 in the cloud container; created project; added deps.
- Built M1 (see CHANGELOG 0.1.0).
- Checks: `dart format` clean, `flutter analyze` no issues, `flutter test` 88 passed / backend suite skipped.
- Live API attempt: blocked by container egress proxy (403) → KI-01.

### Files
- Created: `lib/**` (app, core, features), `test/**`, `config/*.json`, `dart_test.yaml`, `docs/*`, `README.md`.
- Modified (template): `pubspec.yaml`, `.gitignore`, Android manifests (+ debug network config), iOS `Info.plist` display name, launcher icons.

### Decisions
- ADR-001 … ADR-013 (DECISIONS.md).

### Handover
- Next: M2 Registration (PROJECT_STATE.md "Next step").

## 2026-10-26 · Session 2 · M2–M7

**Goal:** user said "complete the app": build every remaining milestone without stopping, isolate anything the backend contract doesn't define, keep Google disabled.

### Work done
- M2 registration, M3 password recovery, M4 role areas + Profile, M5 admin approvals, M6 account-type screen, M7 adaptive icon + cleanup (CHANGELOG 0.2.0).
- Router rewritten: sign-up `ShellRoute`, per-role `StatefulShellRoute.indexedStack`, admin review route, recovery routes for signed-in users.
- Fixed two layout bugs found by the new tests (patient check-in rows, long status pills) and ListTile ink inside `LsPanel`.
- Checks: `dart format` clean, `flutter analyze` no issues, `flutter test` 121 passed / backend suite skipped.

### Not verified
- Live backend (KI-01), device builds (KI-12).

### Decisions
- ADR-014 … ADR-021.

### Handover
- Next: PROJECT_STATE.md "Next step".

## 2026-10-26 · Session 3 · Live backend check on the user's PC

**Goal:** verify the backend from a machine that can reach it (KI-01) and run the live suite.

### Work done
- Backend `http://3.108.54.191` reachable: `/health` 200, `/openapi.json` 200 (API v0.3.0), `users/me` without token 403.
- Probed auth endpoints with fake data: login 400 string `detail`; empty register 422 list; forgot-password 202 neutral message; reset-password 400 "Invalid or expired reset code"; refresh 400; reserved `.invalid` email domains rejected with 422.
- Upgraded the PC's Flutter 3.41.2 → 3.47.8 (Dart 3.13.7); the project needs Dart ^3.13.7.
- Aligned `test/backend/auth_api_contract_test.dart` with observed responses: `example.com` test email, 401/403 for missing bearer token, runtime skip of the credential test (`--run-skipped` ignores `skip:`).
- Checks: `dart format` clean, `flutter analyze` no issues, `flutter test` 121 passed / 1 skipped, live backend suite 3 passed / 1 skipped (no patient credentials).

### Not verified
- Authenticated flows (no test patient credentials), device builds (KI-12).

### Handover
- Provide `LS_TEST_PATIENT_EMAIL` / `LS_TEST_PATIENT_PASSWORD` locally to run the credential test.
