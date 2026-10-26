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
import '../features/doctor/presentation/pages/doctor_dashboard_page.dart';
import '../features/doctor/presentation/pages/doctor_lists_pages.dart';
import '../features/password_recovery/presentation/cubit/password_recovery_cubits.dart';
import '../features/password_recovery/presentation/pages/forgot_password_page.dart';
import '../features/password_recovery/presentation/pages/reset_password_page.dart';
import '../features/patient/presentation/pages/patient_check_ins_page.dart';
import '../features/patient/presentation/pages/patient_home_page.dart';
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

      _roleShell(RoleNavItems.patient, [
        GoRoute(
          path: Routes.patientHome,
          builder: (_, _) => const PatientHomePage(),
        ),
        GoRoute(
          path: Routes.patientCheckIns,
          builder: (_, _) => const PatientCheckInsPage(),
        ),
        GoRoute(
          path: Routes.patientProfile,
          builder: (_, _) => const ProfilePage(),
        ),
      ]),
      _roleShell(RoleNavItems.doctor, [
        GoRoute(
          path: Routes.doctorDashboard,
          builder: (_, _) => const DoctorDashboardPage(),
        ),
        GoRoute(
          path: Routes.doctorPatients,
          builder: (_, _) => const DoctorPatientsPage(),
        ),
        GoRoute(
          path: Routes.doctorSessions,
          builder: (_, _) => const DoctorSessionsPage(),
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
          builder: (_, _) => const AdminUsersPage(),
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
