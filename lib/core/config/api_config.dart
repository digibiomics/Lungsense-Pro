/// Build-time configuration for the LungSense Pro backend.
///
/// Values are injected with `--dart-define` (or `--dart-define-from-file`),
/// so no URL or secret is hardcoded elsewhere in the app.
///
/// WARNING: the documented default base URL uses plain HTTP. It is only
/// suitable for development and testing. Production builds must point
/// `API_BASE_URL` at an HTTPS endpoint before handling real credentials,
/// OTPs, tokens or patient data.
class ApiConfig {
  const ApiConfig._();

  /// One of `development`, `testing` or `production`.
  static const String environment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://3.108.54.191',
  );

  static const String apiPrefix = '/api/v1';

  /// Support address shown on blocked-account screens. Empty hides the action.
  static const String supportEmail = String.fromEnvironment('SUPPORT_EMAIL');

  /// OAuth callback registered for the Pro app (Google sign-in, not yet live).
  static const String googleRedirectUri = 'lungsensepro://auth/callback';

  /// Google sign-in stays disabled until the backend confirms it is set up.
  static const bool googleSignInEnabled = bool.fromEnvironment(
    'GOOGLE_SIGN_IN_ENABLED',
  );

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);

  static bool get isProduction => environment == 'production';

  static bool get usesHttps => baseUrl.startsWith('https://');
}
