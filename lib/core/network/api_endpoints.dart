import '../config/api_config.dart';

/// Documented LungSense Pro endpoints. Do not add paths that are not in the
/// backend contract (docs/openapi_snapshot.json, docs/ARCHITECTURE.md).
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
      '$_p/admin/doctors/${_e(userId)}/approve';
  static String rejectDoctor(String userId) =>
      '$_p/admin/doctors/${_e(userId)}/reject';
  static const String adminUsers = '$_p/admin/users';
  static String adminUser(String userId) => '$_p/admin/users/${_e(userId)}';
  static String userStatus(String userId) =>
      '$_p/admin/users/${_e(userId)}/status';

  // Patients
  static const String patients = '$_p/patients';
  static String patient(String id) => '$_p/patients/${_e(id)}';
  static String patientSessions(String id) => '$_p/patients/${_e(id)}/sessions';

  // Collection
  static const String sessions = '$_p/collection/sessions';
  static String session(String id) => '$_p/collection/sessions/${_e(id)}';
  static String completeSession(String id) =>
      '$_p/collection/sessions/${_e(id)}/complete';
  static String sessionSymptoms(String id) =>
      '$_p/collection/sessions/${_e(id)}/symptoms';
  static String audioUploadUrl(String sessionId) =>
      '$_p/collection/sessions/${_e(sessionId)}/audio/upload-url';
  static String audio(String id) => '$_p/collection/audio/${_e(id)}';
  static String completeAudio(String id) =>
      '$_p/collection/audio/${_e(id)}/complete';
  static String audioDownloadUrl(String id) =>
      '$_p/collection/audio/${_e(id)}/download-url';
  static String xrayUploadUrl(String sessionId) =>
      '$_p/collection/sessions/${_e(sessionId)}/xrays/upload-url';
  static String xray(String id) => '$_p/collection/xrays/${_e(id)}';
  static String completeXray(String id) =>
      '$_p/collection/xrays/${_e(id)}/complete';
  static String xrayDownloadUrl(String id) =>
      '$_p/collection/xrays/${_e(id)}/download-url';
  static const String dashboard = '$_p/collection/dashboard';

  static String _e(String v) => Uri.encodeComponent(v);
}
