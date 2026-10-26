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
