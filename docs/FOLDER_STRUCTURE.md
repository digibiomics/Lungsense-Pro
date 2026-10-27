# Folder structure

Location: `pro_app/lungsense_pro/` (design handoff at `pro_app/Design and icons/`, read-only).
Platform folders `android/` and `ios/` are Flutter template files plus icons/manifests noted in CHANGELOG.

```
lungsense_pro/
├── README.md
├── pubspec.yaml · pubspec.lock · analysis_options.yaml · dart_test.yaml
├── config/                     # --dart-define-from-file env files
│   ├── development.json · testing.json · production.example.json
├── assets/
│   ├── fonts/                  # Public Sans 400–700 + OFL licence
│   └── images/                 # logos copied from Design and icons/
├── docs/                       # project memory (10 files)
├── lib/
│   ├── main.dart               # bootstrap: DI, session restore, runApp
│   ├── app/                    # composition root
│   │   ├── app.dart            # MaterialApp.router + theme
│   │   ├── di.dart             # GetIt registrations
│   │   ├── router.dart         # GoRouter routes
│   │   └── session_redirect.dart  # route guard (pure)
│   ├── core/
│   │   ├── assets/app_assets.dart
│   │   ├── config/             # api_config, app_info (version label)
│   │   ├── errors/             # failure, failure_messages
│   │   ├── logging/app_logger.dart
│   │   ├── network/            # api_client (+ upload Dio), api_endpoints, auth_interceptor, error_mapper, json_read
│   │   ├── routing/routes.dart
│   │   ├── storage/token_storage.dart
│   │   ├── theme/              # app_colors, design_tokens, app_theme
│   │   ├── utils/              # validators, date_format, paged
│   │   └── widgets/            # ls_button, ls_text_field, ls_banner, ls_screen, brand, ls_components, ls_bottom_nav,
│   │                           # ls_sheet (confirm sheet, toast), ls_search_field
│   └── features/
│       ├── authentication/
│       │   ├── domain/         # entities (app_user, registration, session_outcome), repositories, usecases
│       │   ├── data/           # models (auth, request), datasources, repositories
│       │   └── presentation/   # cubit (session, login), pages (splash, welcome, login),
│       │                       # widgets (google_sign_in_button, role_scaffold, role_page)
│       ├── registration/presentation/      # cubits (registration, resend, account_type), role choice,
│       │                                   # register, register doctor, verify email, role selection
│       ├── password_recovery/presentation/ # forgot + reset cubits and pages
│       ├── account_status/presentation/pages/account_status_page.dart
│       ├── patient/presentation/pages/     # patient home (today's check-in)
│       ├── doctor/presentation/pages/      # dashboard
│       ├── patients/                       # domain (patient, repo, use cases), data (models, datasource),
│       │                                   # presentation (list, add/edit, detail)
│       ├── collection/
│       │   ├── domain/         # session, recording, symptoms, dashboard entities; repository; device service interfaces
│       │   ├── data/           # models, remote datasource (presigned uploads), repository, device/ (record, just_audio, file_picker)
│       │   └── presentation/   # cubits (session, recorder, steps, lists, events), pages (start, overview, recorder,
│       │                       # symptoms, clinical, review/submit, sessions), widgets (header, step row, severity, copy)
│       ├── profile/presentation/pages/profile_page.dart
│       └── admin/
│           ├── domain/         # doctor_application, admin_repository, admin_usecases
│           ├── data/           # doctor_application_model (tolerant parser), datasource, repository
│           └── presentation/   # cubits, approvals list, review, users
├── test/
│   ├── helpers/                # fakes.dart (MOCK adapter, in-memory storage), collection_fakes.dart (device fakes, JSON samples), pump.dart
│   ├── unit/                   # mapper, models, request bodies, admin parser, policy, repository, interceptor, use cases, cubits, redirect, storage
│   ├── widget/                 # login, account status, welcome/splash, full app flow, feature flows
│   └── backend/                # live API contract tests (tag: backend, skipped by default)
├── android/                    # + mipmaps + adaptive icon from handoff, INTERNET permission, debug-only cleartext config
└── ios/                        # + AppIcon.appiconset from handoff
```
