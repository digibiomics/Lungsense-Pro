# Roadmap

M1 ended with a stop for approval. On 2026-10-26 the user said "complete the app", which approved M2–M7 without further stops.

| ID | Milestone | Scope | Design refs | Status |
|---|---|---|---|---|
| M0 | Inspect + plan | Workspace, assets, designs, API docs | all | ✅ Done |
| M1 | Auth foundation | Config, API client, refresh, secure storage, errors, theme, widgets, splash/restore, Welcome, Login, AccountStatus, route guard | Main, Login, AccountStatus, Tokens, Components | ✅ Done |
| M2 | Registration | RoleChoice, patient + doctor registration, consent, 422 handling, Check-your-email + resend | RoleChoice, Register, RegisterDoctor, VerifyEmail | ✅ Done |
| M3 | Password recovery | Forgot password (neutral), Reset with 6-digit OTP + confirm field | ForgotPassword, ResetPassword | ✅ Done |
| M4 | Role areas | Patient Home, Doctor Dashboard, Profile, `LsBottomNav`, empty states (only documented APIs) | PatientHome, Dashboard, Profile, States | ✅ Done |
| M5 | Admin | Doctor applications list, review, approve, reject (reason sheet) | AdminDoctors, AdminReview, AdminUsers | ✅ Done (list parser tolerant, KI-02); user status change not built (body undocumented) |
| M6 | Google | Account-type step for `role: new` users | RoleChoice, RegisterDoctor | ✅ Account-type screen done; Google sign-in disabled until server is configured (KI-03) |
| M7 | Hardening | Adaptive icon, placeholder removal, docs, version 0.2.0 | – | ✅ Done (HTTPS, iOS ATS, native splash still open: KI-05, KI-10) |
| M8 | Live verification | Run backend contract tests, device builds, fix contract mismatches | – | ⬜ Needs network access to backend |
| M9+ | Collection flow | Recorder, symptoms, clinical, review, submit, sessions | rows 3–4 of canvas | ⬜ Needs collection API docs |
