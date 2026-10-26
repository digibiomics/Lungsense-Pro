abstract final class Routes {
  // Public
  static const splash = '/splash';
  static const welcome = '/welcome';
  static const login = '/login';
  static const signUp = '/sign-up';
  static const forgotPassword = '/forgot-password';

  // Session gated
  static const accountStatus = '/account-status';
  static const roleSelection = '/role-selection';
  static const patientHome = '/patient';
  static const doctorDashboard = '/doctor';
  static const adminHome = '/admin';

  static const public = {welcome, login, signUp, forgotPassword};
}
