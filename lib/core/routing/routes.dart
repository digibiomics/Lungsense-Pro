abstract final class Routes {
  // Public
  static const splash = '/splash';
  static const welcome = '/welcome';
  static const login = '/login';
  static const signUp = '/sign-up';
  static const signUpAccount = '/sign-up/account';
  static const signUpDoctor = '/sign-up/doctor';
  static const verifyEmail = '/verify-email';
  static const forgotPassword = '/forgot-password';
  static const resetPassword = '/reset-password';

  // Session gated
  static const accountStatus = '/account-status';
  static const roleSelection = '/role-selection';

  static const patientHome = '/patient';
  static const patientCheckIns = '/patient/check-ins';
  static const patientProfile = '/patient/profile';

  static const doctorDashboard = '/doctor';
  static const doctorPatients = '/doctor/patients';
  static const doctorSessions = '/doctor/sessions';
  static const doctorProfile = '/doctor/profile';

  static const adminHome = '/admin';
  static const adminUsers = '/admin/users';
  static const adminProfile = '/admin/profile';
  static const adminReview = '/admin/review';

  /// Reachable while signed out.
  static const public = {
    welcome,
    login,
    signUp,
    signUpAccount,
    signUpDoctor,
    verifyEmail,
    forgotPassword,
    resetPassword,
  };

  /// Password recovery also serves "Change password" for signed-in users.
  static const passwordRecovery = {forgotPassword, resetPassword};

  static String verifyEmailFor(String email, {required bool doctor}) => Uri(
    path: verifyEmail,
    queryParameters: {'email': email, if (doctor) 'role': 'doctor'},
  ).toString();

  static String forgotPasswordFor(String email) => Uri(
    path: forgotPassword,
    queryParameters: email.isEmpty ? null : {'email': email},
  ).toString();

  static String resetPasswordFor(String email) => Uri(
    path: resetPassword,
    queryParameters: email.isEmpty ? null : {'email': email},
  ).toString();

  static String adminReviewFor(String userId) =>
      '$adminReview/${Uri.encodeComponent(userId)}';
}
