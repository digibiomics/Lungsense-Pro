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
