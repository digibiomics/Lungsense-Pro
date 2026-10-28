# Project state

| Field | Value |
|---|---|
| Last updated | 2026-10-28 |
| Phase | Every designed screen built against the OpenAPI snapshot |
| Current milestone | **M9–M12 done** (user approved building everything still missing without stops) |
| Next milestone | M13 device verification with test accounts |
| Branch | `main` |
| Latest commit | see `git log -1` (0.3.0 commit follows `bc083a2`) |
| App version | 0.3.0+3 |

## Completed
- M0–M7: auth, registration, recovery, role areas, admin approvals, account type, hardening (see CHANGELOG 0.1.0, 0.2.0).
- M9 Admin Users tab (search, suspend with reason, reactivate); approval tabs per status; patients list, add (duplicate check, consent), detail, edit.
- M10 Collection flow: start collection, overview, cough and breathing recorder (limits, import check, presigned upload, server QC, retry, playback), symptoms (10 items), clinical context (notes, X-ray), review, submit result, read-only session detail.
- M11 Session history with filters; dashboard counts, drafts, recent activity.
- M12 Patient home (start/resume today's check-in), My check-ins, collection screens in patient mode.
- Remove draft and same-day draft hiding, device-side only (ADR-032, KI-25).
- Patient record fields (ADR-033): full name, age, gender, smoking status required; height, weight, relevant history optional. Add/Edit patient, Patient detail, and patient Profile "My details" (edit via `PATCH /patients/me`).
- Label/value alignment: `LsKeyValueRow` keeps values flush right on one line and drops long values under the label; Patient detail uses the design's two-column `LsFactGrid`.
- Checks (2026-10-28, user's PC): `flutter analyze` no issues; `flutter test` 178 passed, 1 skipped (live backend group).

## In progress
- Nothing.

## Next step (exact)
1. Ask the product owner the two open questions: where the diagnosis goes (KI-18) and the descriptors for 8 symptoms (KI-19). Symptom text goes in `features/collection/presentation/widgets/symptom_copy.dart`.
2. With a test doctor and a test patient account, run the app on Android (`flutter run --dart-define-from-file=config/development.json`) and record, upload and submit one session and one check-in (M13). Confirm KI-17, KI-20, KI-21, KI-22.
3. Patient sign-in live test stays on hold until the user provides credentials.

## Blockers / open
- KI-25 no API to delete/cancel a session; drafts are only hidden on the device until the backend adds it.
- KI-18 diagnosis picker has no API field; KI-19 symptom descriptors missing (product owner).
- Google OAuth not configured on the server (KI-03); sign-in stays disabled.
- Microphone, file picking, playback and storage upload not yet run on a device (KI-24).
- API is HTTP (KI-05): no real patient data until HTTPS.
