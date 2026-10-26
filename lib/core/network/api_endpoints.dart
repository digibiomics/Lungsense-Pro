import '../config/api_config.dart';

/// Documented LungSense Pro endpoints. Do not add paths that are not in the
/// backend contract (see docs/ARCHITECTURE.md, "API contract").
class ApiEndpoints {
  const ApiEndpoints._();

  static const String _p = ApiConfig.apiPrefix;

  // Authentication
  static const String register = '$_p/auth/register';
  static const String login = '$_p/auth/login';
  static const String refresh = '$_p/auth/refresh';
  static const String resendConfirmation = '$_p/auth/resend-confirmation';
  static const String forgotPassword = '$_p/auth/forgot-password';
  static const String resetPassword = '$_p/auth/reset-password';
  static const String googleAuthorizeUrl = '$_p/auth/google/authorize-url';
  static const String googleToken = '$_p/auth/google/token';

  // Current user
  static const String me = '$_p/users/me';
  static const String meAccountType = '$_p/users/me/account-type';

  // Admin
  static const String adminDoctors = '$_p/admin/doctors';
  static String approveDoctor(String userId) =>
      '$_p/admin/doctors/${Uri.encodeComponent(userId)}/approve';
  static String rejectDoctor(String userId) =>
      '$_p/admin/doctors/${Uri.encodeComponent(userId)}/reject';
  static String userStatus(String userId) =>
      '$_p/admin/users/${Uri.encodeComponent(userId)}/status';
}
