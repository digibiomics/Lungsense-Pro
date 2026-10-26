/// Pure-Dart error model shared by the domain and presentation layers.
/// The data layer converts HTTP/transport errors into [Failure]s, so nothing
/// above it depends on Dio or JSON.
enum FailureKind {
  /// No connection, DNS failure, connection refused.
  network,

  /// Connect/send/receive timeout.
  timeout,

  /// 400: invalid credentials, unconfirmed email, invalid reset code.
  badRequest,

  /// 401: invalid or expired token.
  unauthorized,

  /// 403: account-status restriction or wrong role.
  forbidden,

  /// 404.
  notFound,

  /// 409 / 422: validation error or duplicate registration.
  validation,

  /// 429: too many attempts.
  rateLimited,

  /// 503: authentication service unavailable or not configured.
  serviceUnavailable,

  /// Other 5xx.
  server,

  /// Response could not be parsed, or anything unexpected.
  unknown,
}

class Failure implements Exception {
  const Failure({
    required this.kind,
    this.statusCode,
    this.code,
    this.message,
    this.fieldErrors = const {},
  });

  final FailureKind kind;
  final int? statusCode;

  /// Machine-readable `detail.code` from the backend, when provided
  /// (for example `account_pending_approval`).
  final String? code;

  /// Server-provided human message (`detail` or `detail.message`). Safe to
  /// show; never contains tokens because the backend does not echo them.
  final String? message;

  /// Field-level validation messages keyed by request field name
  /// (FastAPI 422 `detail[].loc` last segment).
  final Map<String, String> fieldErrors;

  bool get isConnectivity =>
      kind == FailureKind.network || kind == FailureKind.timeout;

  @override
  String toString() => 'Failure(kind: $kind, status: $statusCode, code: $code)'; // no message: may echo user input
}
