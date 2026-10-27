# Roadmap

M1 ended with a stop for approval. On 2026-10-26 the user said "complete the app", which approved M2–M7 without further stops. On 2026-10-27 the user approved building everything still missing (M9–M12) without stopping between milestones.

| ID | Milestone | Scope | Design refs | Status |
|---|---|---|---|---|
| M0 | Inspect + plan | Workspace, assets, designs, API docs | all | ✅ Done |
| M1 | Auth foundation | Config, API client, refresh, secure storage, errors, theme, widgets, splash/restore, Welcome, Login, AccountStatus, route guard | Main, Login, AccountStatus, Tokens, Components | ✅ Done |
| M2 | Registration | RoleChoice, patient + doctor registration, consent, 422 handling, Check-your-email + resend | RoleChoice, Register, RegisterDoctor, VerifyEmail | ✅ Done |
| M3 | Password recovery | Forgot password (neutral), Reset with 6-digit OTP + confirm field | ForgotPassword, ResetPassword | ✅ Done |
| M4 | Role areas | Patient Home, Doctor Dashboard, Profile, `LsBottomNav`, empty states (only documented APIs) | PatientHome, Dashboard, Profile, States | ✅ Done |
| M5 | Admin | Doctor applications list, review, approve, reject (reason sheet) | AdminDoctors, AdminReview, AdminUsers | ✅ Done; Users tab (search, suspend, reactivate) added in M9 |
| M6 | Google | Account-type step for `role: new` users | RoleChoice, RegisterDoctor | ✅ Account-type screen done; Google sign-in disabled until server is configured (KI-03) |
| M7 | Hardening | Adaptive icon, placeholder removal, docs, version 0.2.0 | – | ✅ Done (HTTPS, iOS ATS, native splash still open: KI-05, KI-10) |
| M8 | Live verification | Run backend contract tests, device builds, fix contract mismatches | – | ⬜ Needs network access to backend |
| M9 | Admin users + patients | Users tab with search, suspend/reactivate; approval tabs per status; patient list, add (duplicate check, consent), detail, edit | AdminUsers, Patients, AddPatient, PatientDetail | ✅ Done (0.3.0) |
| M10 | Collection flow | Start collection, overview, `LsRecorder` (cough/breathing, import validation, presigned upload, server QC), symptoms, clinical context with X-ray, review, submit result, read-only session detail | StartCollection, CollectionOverview, Recorder, Symptoms, Clinical, Review, SubmitResult, SessionDetail | ✅ Done (0.3.0); diagnosis picker left out (KI-18) |
| M11 | Sessions + dashboard | Session history with filters, dashboard counts, drafts to finish, recent activity | Sessions, Dashboard | ✅ Done (0.3.0) |
| M12 | Patient check-in | Patient home (start/resume today), My check-ins, the collection flow in patient mode | PatientHome, PatientHistory | ✅ Done (0.3.0) |
| M13 | Device verification | Run on Android/iOS against the backend with real accounts; record, upload, submit | – | ⬜ Needs test accounts and a device |
