# Known issues & open questions

| ID | Severity | Issue | Action / owner |
|---|---|---|---|
| KI-01 | High | Backend `http://3.108.54.191` not reachable from the cloud dev container (egress proxy returns 403). **No endpoint verified live.** All behaviour is tested against mocks. | Run `flutter test --tags backend ...` from a machine that can reach the API (README). |
| KI-02 | High | Admin response schemas, pagination, `PATCH /admin/users/{id}/status` body and allowed values not documented. | Backend dev to confirm before M5. |
| KI-03 | High | Google OAuth not enabled on server; redirect `lungsensepro://auth/callback` not registered in app yet. | Server config, then M6. |
| KI-04 | Medium | Login 400 "email not confirmed" has no documented `detail.code`; app matches message text. | Backend to confirm code/message. |
| KI-05 | Critical (prod) | API is HTTP. iOS ATS blocks it (no exception added on purpose); Android allows it in debug only. | Enable HTTPS on backend before any real data. |
| KI-06 | Medium | Exact `users/me` schema, `id` type, and all `account_status` values unverified. Unknown values are blocked. | Confirm with backend. |
| KI-07 | Medium | Email-confirmation deep link not documented; app tells user to confirm then sign in. | Backend to confirm link target. |
| KI-08 | Low | `/sign-up`, `/forgot-password`, `/role-selection` show `UpcomingPage` placeholders. | M2, M3, M6. |
| KI-09 | Low | Role home screens are minimal shells (account card + sign out); no bottom nav yet. | M4. |
| KI-10 | Low | No native splash (white launch screen before Flutter splash); adaptive Android icon not wired. | M7. |
| KI-11 | Low | `SUPPORT_EMAIL` unknown; contact action hidden until set. | Product owner. |
| KI-12 | Low | No device/emulator build run yet (no Android SDK/Xcode in the cloud container). | Run `flutter run` locally. |
| KI-13 | Info | Refresh-token expiry/revocation rules unknown; app saves whatever refresh token the server returns. | Backend to confirm. |
