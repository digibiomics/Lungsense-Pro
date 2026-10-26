# Project state

| Field | Value |
|---|---|
| Last updated | 2026-10-26 |
| Phase | Authentication |
| Current milestone | **M1 Auth foundation: done, awaiting approval** |
| Next milestone | M2 Registration + email confirmation |
| Branch | `main` |
| Latest commit | `0cfcc4c` feat: M1 auth foundation |
| App version | 0.1.0+1 |

## Completed
- M0 Inspect + plan (no prior Flutter project; handoff, icons, launcher icons inventoried)
- M1 Auth foundation: config, Dio client, 401 refresh interceptor, secure token storage, error mapping, theme/tokens, asset registry, splash/session restore, Welcome, Login, Account status, role shells, route guard. 88 tests passing.

## In progress
- Nothing. Waiting for approval of M1.

## Next step (exact)
1. Get approval for M1.
2. Start **M2** (TASKS.md M2-*): build RoleChoice → Register → RegisterDoctor → VerifyEmail from `designs/RoleChoice|Register|RegisterDoctor|VerifyEmail.dc.html`, wire `POST /auth/register` and `/auth/resend-confirmation`, replace the `/sign-up` `UpcomingPage` route.

## Blockers / open
- Backend not reachable from the cloud dev container (proxy 403); live API tests unverified. See KNOWN_ISSUES KI-01.
