# Roadmap

Each milestone ends with checks green, docs updated, and a stop for approval.

| ID | Milestone | Scope | Design refs | Status |
|---|---|---|---|---|
| M0 | Inspect + plan | Workspace, assets, designs, API docs | all | ✅ Done |
| M1 | Auth foundation | Config, API client, refresh, secure storage, errors, theme, widgets, splash/restore, Welcome, Login, AccountStatus, role shells, route guard | Main, Login, AccountStatus, Tokens, Components | ✅ Done (awaiting approval) |
| M2 | Registration | RoleChoice, patient + doctor registration, consent, 422 handling, Check-your-email + resend | RoleChoice, Register, RegisterDoctor, VerifyEmail | ⏳ Next |
| M3 | Password recovery | Forgot password (neutral 202), Reset with 6-digit OTP + confirm field | ForgotPassword, ResetPassword | ⬜ |
| M4 | Role homes | Patient Home, Doctor Dashboard, Profile, `LsBottomNav`, empty/loading states (only documented APIs) | PatientHome, Dashboard, Profile, States | ⬜ |
| M5 | Admin | Doctor applications list, review, approve, reject (reason sheet), user status | AdminDoctors, AdminReview, AdminUsers | ⬜ Blocked on admin schemas (KI-02) |
| M6 | Google sign-in | PKCE, browser auth, state check, token exchange, account-type for `new` | Login, RoleChoice, RegisterDoctor | ⬜ Blocked on server config (KI-03) |
| M7 | Integration + hardening | Live contract tests, HTTPS, iOS ATS, native splash, release config | – | ⬜ |
| M8+ | Collection flow | Recorder, symptoms, clinical, review, submit, sessions | rows 3–4 of canvas | ⬜ Needs collection API docs |
