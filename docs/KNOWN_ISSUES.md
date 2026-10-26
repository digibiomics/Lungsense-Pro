# Known issues & open questions

| ID | Severity | Issue | Action / owner |
|---|---|---|---|
| KI-01 | High | Backend `http://3.108.54.191` not reachable from the cloud dev container (egress proxy returns 403). **No endpoint verified live.** All behaviour is tested against mocks. | Run `flutter test --tags backend ...` from a machine that can reach the API (README). |
| KI-02 | High | Admin response schemas, pagination, `PATCH /admin/users/{id}/status` body and allowed values not documented. App parses the list tolerantly (ADR-015) and does not implement the status change (ADR-016). | Backend dev to confirm list shape and status body. |
| KI-03 | High | Google OAuth not enabled on server; redirect `lungsensepro://auth/callback` not registered in app. Button is disabled; account-type screen is built but only reachable once Google sign-in exists. | Server config, then wire PKCE flow. |
| KI-04 | Medium | Login 400 "email not confirmed" has no documented `detail.code`; app matches message text. | Backend to confirm code/message. |
| KI-05 | Critical (prod) | API is HTTP. iOS ATS blocks it (no exception added on purpose); Android allows it in debug only. | Enable HTTPS on backend before any real data. |
| KI-06 | Medium | Exact `users/me` schema, `id` type, and all `account_status` values unverified. Unknown values are blocked. | Confirm with backend. |
| KI-07 | Medium | Email-confirmation deep link not documented; app tells user to confirm then sign in. | Backend to confirm link target. |
| KI-08 | Resolved | ~~Placeholder pages~~ replaced in 0.2.0. | – |
| KI-09 | Medium | Collection, patient lists and sessions have no documented API, so role areas show empty states and disabled actions. | Backend to publish collection API. |
| KI-10 | Low | No native splash (white launch screen before Flutter splash). Adaptive Android icon wired in 0.2.0. | M7. |
| KI-11 | Low | `SUPPORT_EMAIL` unknown; contact action hidden until set. | Product owner. |
| KI-12 | Low | No device/emulator build run yet (no Android SDK/Xcode in the cloud container). | Run `flutter run` locally. |
| KI-13 | Info | Refresh-token expiry/revocation rules unknown; app saves whatever refresh token the server returns. | Backend to confirm. |
| KI-14 | Medium | Register/account-type success bodies, the duplicate-email error shape (app checks for "already/exists/duplicate" in 409/422/400 messages) and approve/reject response bodies are undocumented. App only relies on the 2xx status. | Backend to confirm. |
| KI-15 | Low | Admin "Users" tab has no list endpoint, so it shows an explanation only. | Backend to document a users list if needed. |
| KI-16 | Low | Whether reset-password ends other sessions is unknown; a signed-in user stays signed in after "Change password". | Backend to confirm. |
