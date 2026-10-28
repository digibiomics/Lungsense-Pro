import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/routing/routes.dart';
import '../core/widgets/ls_bottom_nav.dart';
import '../features/account_status/presentation/pages/account_status_page.dart';
import '../features/admin/domain/entities/doctor_application.dart';
import '../features/admin/domain/usecases/admin_usecases.dart';
import '../features/admin/presentation/cubit/admin_cubits.dart';
import '../features/admin/presentation/cubit/admin_users_cubit.dart';
import '../features/admin/presentation/pages/admin_doctors_page.dart';
import '../features/admin/presentation/pages/admin_review_page.dart';
import '../features/admin/presentation/pages/admin_users_page.dart';
import '../features/authentication/domain/entities/app_user.dart';
import '../features/authentication/domain/entities/session_outcome.dart';
import '../features/authentication/domain/usecases/session_usecases.dart';
import '../features/authentication/presentation/cubit/login_cubit.dart';
import '../features/authentication/presentation/cubit/session_cubit.dart';
import '../features/authentication/presentation/pages/login_page.dart';
import '../features/authentication/presentation/pages/splash_page.dart';
import '../features/authentication/presentation/pages/welcome_page.dart';
import '../features/authentication/presentation/widgets/role_scaffold.dart';
import '../features/collection/domain/entities/recording.dart';
import '../features/collection/domain/repositories/collection_repository.dart';
import '../features/collection/domain/services/draft_visibility.dart';
import '../features/collection/presentation/cubit/collection_events.dart';
import '../features/collection/presentation/cubit/collection_session_cubit.dart';
import '../features/collection/presentation/cubit/list_cubits.dart';
import '../features/collection/presentation/cubit/recorder_cubit.dart';
import '../features/collection/presentation/cubit/step_cubits.dart';
import '../features/collection/presentation/pages/clinical_page.dart';
import '../features/collection/presentation/pages/recorder_page.dart';
import '../features/collection/presentation/pages/review_submit_pages.dart';
import '../features/collection/presentation/pages/session_overview_page.dart';
import '../features/collection/presentation/pages/sessions_page.dart';
import '../features/collection/presentation/pages/start_collection_page.dart';
import '../features/collection/presentation/pages/symptoms_page.dart';
import '../features/collection/presentation/widgets/collection_mode.dart';
import '../features/doctor/presentation/pages/doctor_dashboard_page.dart';
import '../features/password_recovery/presentation/cubit/password_recovery_cubits.dart';
import '../features/password_recovery/presentation/pages/forgot_password_page.dart';
import '../features/password_recovery/presentation/pages/reset_password_page.dart';
import '../features/patient/presentation/pages/patient_home_page.dart';
import '../features/patients/domain/repositories/patient_repository.dart';
import '../features/patients/domain/usecases/patient_usecases.dart';
import '../features/patients/presentation/cubit/patient_cubits.dart';
import '../features/patients/presentation/pages/patient_detail_page.dart';
import '../features/patients/presentation/pages/patient_form_page.dart';
import '../features/patients/presentation/pages/patients_page.dart';
import '../features/patients/presentation/widgets/my_details_section.dart';
import '../features/profile/presentation/pages/profile_page.dart';
import '../features/registration/presentation/cubit/account_type_cubit.dart';
import '../features/registration/presentation/cubit/registration_cubit.dart';
import '../features/registration/presentation/cubit/resend_confirmation_cubit.dart';
import '../features/registration/presentation/pages/register_account_page.dart';
import '../features/registration/presentation/pages/register_doctor_page.dart';
import '../features/registration/presentation/pages/role_choice_page.dart';
import '../features/registration/presentation/pages/role_selection_page.dart';
import '../features/registration/presentation/pages/verify_email_page.dart';
import 'di.dart';
import 'session_redirect.dart';

GoRouter createRouter(SessionCubit session) {
  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: _StreamListenable(session.stream),
    redirect: (context, state) =>
        sessionRedirect(session.state, state.matchedLocation),
    routes: [
      GoRoute(path: Routes.splash, builder: (_, _) => const SplashPage()),
      GoRoute(path: Routes.welcome, builder: (_, _) => const WelcomePage()),
      GoRoute(
        path: Routes.login,
        builder: (_, _) => BlocProvider(
          create: (_) => LoginCubit(
            signIn: sl<SignInWithEmail>(),
            resendConfirmation: sl<ResendConfirmation>(),
            session: session,
          ),
          child: const LoginPage(),
        ),
      ),

      // Email sign-up: one RegistrationCubit across the three steps.
      ShellRoute(
        builder: (_, _, child) => BlocProvider(
          create: (_) => RegistrationCubit(sl<RegisterAccount>()),
          child: child,
        ),
        routes: [
          GoRoute(
            path: Routes.signUp,
            builder: (_, _) => const RoleChoicePage(),
          ),
          GoRoute(
            path: Routes.signUpAccount,
            builder: (_, _) => const RegisterAccountPage(),
          ),
          GoRoute(
            path: Routes.signUpDoctor,
            builder: (_, _) => const RegisterDoctorPage(),
          ),
        ],
      ),
      GoRoute(
        path: Routes.verifyEmail,
        builder: (_, state) => BlocProvider(
          create: (_) => ResendConfirmationCubit(sl<ResendConfirmation>()),
          child: VerifyEmailPage(
            email: state.uri.queryParameters['email'] ?? '',
            doctor: state.uri.queryParameters['role'] == 'doctor',
          ),
        ),
      ),
      GoRoute(
        path: Routes.forgotPassword,
        builder: (_, state) => BlocProvider(
          create: (_) => ForgotPasswordCubit(sl<RequestPasswordReset>()),
          child: ForgotPasswordPage(
            initialEmail: state.uri.queryParameters['email'],
          ),
        ),
      ),
      GoRoute(
        path: Routes.resetPassword,
        builder: (context, state) {
          final user = _signedInUser(session.state);
          return BlocProvider(
            create: (_) => ResetPasswordCubit(sl<ResetPassword>()),
            child: ResetPasswordPage(
              initialEmail: state.uri.queryParameters['email'],
              doneLabel: user == null ? 'Go to sign in' : 'Done',
              onDone: () => context.go(
                user == null ? Routes.login : _profileFor(user.role),
              ),
            ),
          );
        },
      ),
      GoRoute(
        path: Routes.accountStatus,
        builder: (_, _) => const AccountStatusPage(),
      ),
      GoRoute(
        path: Routes.roleSelection,
        builder: (_, _) {
          final s = session.state;
          final name =
              s is SessionResolved && s.outcome is RoleSelectionRequired
              ? (s.outcome as RoleSelectionRequired).user.fullName
              : null;
          return BlocProvider(
            create: (_) => AccountTypeCubit(
              sl<CompleteAccountType>(),
              onOutcome: session.resolve,
            ),
            child: RoleSelectionPage(initialName: name),
          );
        },
      ),

      // Full-screen routes (no bottom navigation) come before the tab
      // shells so `/doctor/patients/new` is not read as the Patients tab.
      ..._doctorScreens(),
      _sessionRoute(Routes.patientCheckIn, CollectionMode.patient),
      GoRoute(
        path: Routes.patientDetails,
        builder: (_, _) => BlocProvider(
          create: (_) =>
              PatientFormCubit.mine(sl<PatientRepository>())..loadInitial(),
          child: const PatientFormPage(),
        ),
      ),

      _roleShell(RoleNavItems.patient, [
        GoRoute(
          path: Routes.patientHome,
          builder: (_, _) => MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (_) => PatientHomeCubit(
                  sl<CollectionRepository>(),
                  events: sl<CollectionEvents>(),
                  drafts: sl<DraftVisibility>(),
                )..load(),
              ),
              BlocProvider(
                create: (_) => StartSessionCubit(
                  sl<CollectionRepository>(),
                  events: sl<CollectionEvents>(),
                ),
              ),
              BlocProvider(
                create: (_) => MyConsentCubit(sl<PatientRepository>())..load(),
              ),
            ],
            child: const PatientHomePage(),
          ),
        ),
        GoRoute(
          path: Routes.patientCheckIns,
          builder: (_, _) => BlocProvider(
            create: (_) => SessionsCubit(
              sl<CollectionRepository>(),
              events: sl<CollectionEvents>(),
              drafts: sl<DraftVisibility>(),
            )..load(),
            child: const SessionsPage(mode: CollectionMode.patient),
          ),
        ),
        GoRoute(
          path: Routes.patientProfile,
          builder: (_, _) => BlocProvider(
            create: (_) => MyRecordCubit(sl<PatientRepository>())..load(),
            child: const ProfilePage(details: MyDetailsSection()),
          ),
        ),
      ]),
      _roleShell(RoleNavItems.doctor, [
        GoRoute(
          path: Routes.doctorDashboard,
          builder: (_, _) => BlocProvider(
            create: (_) => DashboardCubit(
              sl<CollectionRepository>(),
              events: sl<CollectionEvents>(),
              drafts: sl<DraftVisibility>(),
            )..load(),
            child: const DoctorDashboardPage(),
          ),
        ),
        GoRoute(
          path: Routes.doctorPatients,
          builder: (_, _) => BlocProvider(
            create: (_) => PatientsCubit(
              sl<ListPatients>(),
              events: sl<CollectionEvents>(),
            )..load(),
            child: const PatientsPage(),
          ),
        ),
        GoRoute(
          path: Routes.doctorSessions,
          builder: (_, _) => BlocProvider(
            create: (_) => SessionsCubit(
              sl<CollectionRepository>(),
              events: sl<CollectionEvents>(),
              drafts: sl<DraftVisibility>(),
            )..load(),
            child: const SessionsPage(mode: CollectionMode.doctor),
          ),
        ),
        GoRoute(
          path: Routes.doctorProfile,
          builder: (_, _) => const ProfilePage(),
        ),
      ]),
      _roleShell(RoleNavItems.admin, [
        GoRoute(
          path: Routes.adminHome,
          builder: (_, _) => BlocProvider(
            create: (_) =>
                AdminDoctorsCubit(sl<ListDoctorApplications>())..load(),
            child: const AdminDoctorsPage(),
          ),
        ),
        GoRoute(
          path: Routes.adminUsers,
          builder: (_, _) => BlocProvider(
            create: (_) =>
                AdminUsersCubit(sl<ListUsers>(), sl<SetUserStatus>())..load(),
            child: const AdminUsersPage(),
          ),
        ),
        GoRoute(
          path: Routes.adminProfile,
          builder: (_, _) => const ProfilePage(),
        ),
      ]),
      // Full-screen, above the admin tabs. No single-application endpoint is
      // documented, so the list hands the application over in `extra`.
      GoRoute(
        path: '${Routes.adminReview}/:id',
        builder: (_, state) {
          final application = state.extra;
          if (application is! DoctorApplication ||
              application.userId != state.pathParameters['id']) {
            return const AdminReviewMissingPage();
          }
          return BlocProvider(
            create: (_) => AdminReviewCubit(
              application: application,
              approve: sl<ApproveDoctor>(),
              reject: sl<RejectDoctor>(),
            ),
            child: const AdminReviewPage(),
          );
        },
      ),
    ],
  );
}

/// Doctor screens above the tabs: add/edit patient, patient detail, start
/// collection and the collection flow.
List<RouteBase> _doctorScreens() => [
  GoRoute(
    path: Routes.doctorAddPatient,
    builder: (_, _) => BlocProvider(
      create: (_) => PatientFormCubit(sl<SavePatient>(), sl<GetPatient>()),
      child: const PatientFormPage(),
    ),
  ),
  GoRoute(
    path: '${Routes.doctorPatient}/:id',
    builder: (_, state) => BlocProvider(
      create: (_) => PatientDetailCubit(
        sl<GetPatient>(),
        sl<CollectionRepository>(),
        state.pathParameters['id']!,
        events: sl<CollectionEvents>(),
      )..load(),
      child: const PatientDetailPage(),
    ),
    routes: [
      GoRoute(
        path: 'edit',
        builder: (_, state) => BlocProvider(
          create: (_) => PatientFormCubit(
            sl<SavePatient>(),
            sl<GetPatient>(),
            patientId: state.pathParameters['id'],
          )..loadInitial(),
          child: const PatientFormPage(),
        ),
      ),
    ],
  ),
  GoRoute(
    path: Routes.doctorStartCollection,
    builder: (_, state) => MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              PatientsCubit(sl<ListPatients>(), events: sl<CollectionEvents>())
                ..load(),
        ),
        BlocProvider(
          create: (_) => StartSessionCubit(
            sl<CollectionRepository>(),
            events: sl<CollectionEvents>(),
          ),
        ),
      ],
      child: StartCollectionPage(
        patientId: state.uri.queryParameters['patient'],
        studyId: state.uri.queryParameters['study'],
      ),
    ),
  ),
  _sessionRoute(Routes.doctorSession, CollectionMode.doctor),
];

/// `<base>/:id` (overview, or read-only detail once completed) and its
/// steps. Each step reads what it needs from the server.
GoRoute _sessionRoute(String base, CollectionMode mode) {
  String id(GoRouterState s) => s.pathParameters['id']!;
  CollectionSessionCubit sessionCubit(GoRouterState s) =>
      CollectionSessionCubit(
        sl<CollectionRepository>(),
        id(s),
        events: sl<CollectionEvents>(),
        opener: sl<DeviceServices>().links,
        drafts: sl<DraftVisibility>(),
      )..load();
  GoRoute recorder(RecordingType type) => GoRoute(
    path: type == RecordingType.cough
        ? CollectionRoute.cough.segment
        : CollectionRoute.breathing.segment,
    builder: (_, s) {
      final devices = sl<DeviceServices>();
      return BlocProvider(
        create: (_) => RecorderCubit(
          repository: sl<CollectionRepository>(),
          capture: devices.capture(),
          inspector: devices.inspector,
          playback: devices.playback(),
          files: devices.files,
          sessionId: id(s),
          type: type,
          events: sl<CollectionEvents>(),
        )..load(),
        child: RecorderPage(type: type, mode: mode),
      );
    },
  );

  return GoRoute(
    path: '$base/:id',
    builder: (_, s) => BlocProvider(
      create: (_) => sessionCubit(s),
      child: SessionOverviewPage(mode: mode),
    ),
    routes: [
      recorder(RecordingType.cough),
      recorder(RecordingType.breathing),
      GoRoute(
        path: CollectionRoute.symptoms.segment,
        builder: (_, s) => BlocProvider(
          create: (_) => SymptomsCubit(
            sl<CollectionRepository>(),
            id(s),
            events: sl<CollectionEvents>(),
          )..load(),
          child: SymptomsPage(mode: mode),
        ),
      ),
      GoRoute(
        path: CollectionRoute.context.segment,
        builder: (_, s) => BlocProvider(
          create: (_) => ClinicalCubit(
            sl<CollectionRepository>(),
            sl<DeviceServices>().files,
            id(s),
            events: sl<CollectionEvents>(),
          )..load(),
          child: ClinicalPage(mode: mode),
        ),
      ),
      GoRoute(
        path: CollectionRoute.review.segment,
        builder: (_, s) => BlocProvider(
          create: (_) => sessionCubit(s),
          child: ReviewPage(mode: mode),
        ),
      ),
      GoRoute(
        path: CollectionRoute.submit.segment,
        builder: (_, s) => BlocProvider(
          create: (_) => SubmitCubit(
            sl<CollectionRepository>(),
            id(s),
            events: sl<CollectionEvents>(),
          )..submit(),
          child: SubmitResultPage(mode: mode),
        ),
      ),
    ],
  );
}

StatefulShellRoute _roleShell(List<LsNavItem> items, List<GoRoute> tabs) =>
    StatefulShellRoute.indexedStack(
      builder: (_, _, shell) => RoleScaffold(shell: shell, items: items),
      branches: [
        for (final t in tabs) StatefulShellBranch(routes: [t]),
      ],
    );

AppUser? _signedInUser(SessionState s) => switch (s) {
  SessionResolved(outcome: Authenticated(:final user)) => user,
  _ => null,
};

String _profileFor(UserRole role) => switch (role) {
  UserRole.doctor => Routes.doctorProfile,
  UserRole.admin => Routes.adminProfile,
  _ => Routes.patientProfile,
};

class _StreamListenable extends ChangeNotifier {
  _StreamListenable(Stream<dynamic> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }
  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
