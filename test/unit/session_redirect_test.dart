import 'package:flutter_test/flutter_test.dart';
import 'package:lungsense_pro/app/session_redirect.dart';
import 'package:lungsense_pro/core/errors/failure.dart';
import 'package:lungsense_pro/core/routing/routes.dart';
import 'package:lungsense_pro/features/authentication/domain/entities/app_user.dart';
import 'package:lungsense_pro/features/authentication/domain/entities/session_outcome.dart';
import 'package:lungsense_pro/features/authentication/presentation/cubit/session_cubit.dart';

import '../helpers/fakes.dart';

SessionState resolved(SessionOutcome o) => SessionResolved(o);

void main() {
  test('checking and restore failure stay on splash', () {
    expect(
      sessionRedirect(const SessionChecking(), Routes.patientHome),
      Routes.splash,
    );
    expect(sessionRedirect(const SessionChecking(), Routes.splash), isNull);
    expect(
      sessionRedirect(
        const SessionRestoreFailed(Failure(kind: FailureKind.network)),
        Routes.login,
      ),
      Routes.splash,
    );
  });

  test('signed out may use public routes only', () {
    final s = resolved(const SignedOut());
    expect(sessionRedirect(s, Routes.login), isNull);
    expect(sessionRedirect(s, Routes.welcome), isNull);
    expect(sessionRedirect(s, Routes.doctorDashboard), Routes.welcome);
    expect(sessionRedirect(s, Routes.adminHome), Routes.welcome);
    expect(sessionRedirect(s, Routes.splash), Routes.welcome);
  });

  test('each role is pinned to its own area', () {
    final patient = resolved(Authenticated(userWith(role: UserRole.patient)));
    final doctor = resolved(Authenticated(userWith(role: UserRole.doctor)));
    final admin = resolved(Authenticated(userWith(role: UserRole.admin)));

    expect(sessionRedirect(patient, Routes.adminHome), Routes.patientHome);
    expect(sessionRedirect(patient, Routes.login), Routes.patientHome);
    expect(sessionRedirect(patient, Routes.patientHome), isNull);
    expect(sessionRedirect(doctor, Routes.patientHome), Routes.doctorDashboard);
    expect(sessionRedirect(doctor, '${Routes.doctorDashboard}/x'), isNull);
    expect(sessionRedirect(admin, Routes.doctorDashboard), Routes.adminHome);
  });

  test('restricted accounts only see the status screen', () {
    final s = resolved(const AccountRestricted(AccountStatus.pendingApproval));
    expect(sessionRedirect(s, Routes.doctorDashboard), Routes.accountStatus);
    expect(sessionRedirect(s, Routes.login), Routes.accountStatus);
    expect(sessionRedirect(s, Routes.accountStatus), isNull);
  });

  test('new Google role goes to role selection', () {
    final s = resolved(RoleSelectionRequired(userWith(role: UserRole.newUser)));
    expect(sessionRedirect(s, Routes.patientHome), Routes.roleSelection);
  });

  test('sign-up and recovery are public; app areas are not', () {
    final s = resolved(const SignedOut());
    for (final r in [
      Routes.signUp,
      Routes.signUpAccount,
      Routes.signUpDoctor,
      Routes.verifyEmail,
      Routes.forgotPassword,
      Routes.resetPassword,
    ]) {
      expect(sessionRedirect(s, r), isNull, reason: r);
    }
    expect(sessionRedirect(s, Routes.roleSelection), Routes.welcome);
    expect(sessionRedirect(s, '${Routes.adminReview}/d-1'), Routes.welcome);
  });

  test('signed-in users may use recovery but not sign-up', () {
    final p = resolved(Authenticated(userWith(role: UserRole.patient)));
    expect(sessionRedirect(p, Routes.forgotPassword), isNull);
    expect(sessionRedirect(p, Routes.resetPassword), isNull);
    expect(sessionRedirect(p, Routes.signUp), Routes.patientHome);
    expect(sessionRedirect(p, Routes.patientProfile), isNull);
    expect(sessionRedirect(p, '${Routes.adminReview}/d-1'), Routes.patientHome);
  });

  test('admin tabs and review stay inside the admin area', () {
    final a = resolved(Authenticated(userWith(role: UserRole.admin)));
    expect(sessionRedirect(a, Routes.adminUsers), isNull);
    expect(sessionRedirect(a, '${Routes.adminReview}/d-1'), isNull);
    expect(sessionRedirect(a, Routes.doctorPatients), Routes.adminHome);
  });

  test('role-new users are held on role selection', () {
    final n = resolved(RoleSelectionRequired(userWith(role: UserRole.newUser)));
    expect(sessionRedirect(n, Routes.roleSelection), isNull);
    expect(sessionRedirect(n, Routes.patientHome), Routes.roleSelection);
  });
}
