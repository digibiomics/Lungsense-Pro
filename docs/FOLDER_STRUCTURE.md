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
│   │   ├── config/api_config.dart
│   │   ├── errors/failure.dart
│   │   ├── logging/app_logger.dart
│   │   ├── network/            # api_client, api_endpoints, auth_interceptor, error_mapper
│   │   ├── routing/routes.dart
│   │   ├── storage/token_storage.dart
│   │   ├── theme/              # app_colors, design_tokens, app_theme
│   │   ├── utils/validators.dart
│   │   └── widgets/            # ls_button, ls_text_field, ls_banner, ls_screen, brand, upcoming_page
│   └── features/
│       ├── authentication/
│       │   ├── domain/         # entities (app_user, session_outcome), repositories, usecases
│       │   ├── data/           # models, datasources, repositories
│       │   └── presentation/   # cubit (session, login), pages (splash, welcome, login), widgets (role_shell)
│       ├── account_status/presentation/pages/account_status_page.dart
│       ├── patient/presentation/pages/patient_home_page.dart
│       ├── doctor/presentation/pages/doctor_dashboard_page.dart
│       └── admin/presentation/pages/admin_home_page.dart
├── test/
│   ├── helpers/                # fakes.dart (MOCK adapter, in-memory storage), pump.dart
│   ├── unit/                   # mapper, models, policy, repository, interceptor, use cases, cubits, redirect, storage
│   ├── widget/                 # login, account status, welcome/splash, full app flow
│   └── backend/                # live API contract tests (tag: backend, skipped by default)
├── android/                    # + mipmaps from handoff, INTERNET permission, debug-only cleartext config
└── ios/                        # + AppIcon.appiconset from handoff
```
