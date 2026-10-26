import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/routing/routes.dart';
import '../core/widgets/upcoming_page.dart';
import '../features/account_status/presentation/pages/account_status_page.dart';
import '../features/admin/presentation/pages/admin_home_page.dart';
import '../features/authentication/domain/usecases/session_usecases.dart';
import '../features/authentication/presentation/cubit/login_cubit.dart';
import '../features/authentication/presentation/cubit/session_cubit.dart';
import '../features/authentication/presentation/pages/login_page.dart';
import '../features/authentication/presentation/pages/splash_page.dart';
import '../features/authentication/presentation/pages/welcome_page.dart';
import '../features/doctor/presentation/pages/doctor_dashboard_page.dart';
import '../features/patient/presentation/pages/patient_home_page.dart';
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
      GoRoute(
        path: Routes.signUp,
        builder: (context, _) => UpcomingPage(
          title: 'Create an account',
          message:
              'Patient and doctor registration is coming in the next '
              'release of this build.',
          onBack: () => _back(context),
        ),
      ),
      GoRoute(
        path: Routes.forgotPassword,
        builder: (context, _) => UpcomingPage(
          title: 'Reset your password',
          message:
              'Password recovery is coming in a later release of this '
              'build.',
          onBack: () => _back(context),
        ),
      ),
      GoRoute(
        path: Routes.roleSelection,
        builder: (context, _) => UpcomingPage(
          title: 'Choose your account type',
          message:
              'Account-type selection for Google sign-in is not '
              'available yet.',
          onBack: () => session.signOut(),
        ),
      ),
      GoRoute(
        path: Routes.accountStatus,
        builder: (_, _) => const AccountStatusPage(),
      ),
      GoRoute(
        path: Routes.patientHome,
        builder: (_, _) => const PatientHomePage(),
      ),
      GoRoute(
        path: Routes.doctorDashboard,
        builder: (_, _) => const DoctorDashboardPage(),
      ),
      GoRoute(path: Routes.adminHome, builder: (_, _) => const AdminHomePage()),
    ],
  );
}

void _back(BuildContext context) =>
    context.canPop() ? context.pop() : context.go(Routes.welcome);

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
