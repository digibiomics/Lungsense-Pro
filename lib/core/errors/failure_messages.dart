import 'failure.dart';

/// User-facing copy for generic failures. Screens add their own wording
/// for the cases the design specifies.
abstract final class FailureMessages {
  static ({String title, String body}) generic(Failure f) => switch (f.kind) {
    FailureKind.network || FailureKind.timeout => (
      title: 'Can\'t reach LungSense Pro.',
      body: 'Check your connection and try again.',
    ),
    FailureKind.rateLimited => (
      title: 'Too many attempts.',
      body: 'Please wait a few minutes and try again.',
    ),
    FailureKind.serviceUnavailable => (
      title: 'Server-side problem.',
      body: 'The service is temporarily unavailable. Please try again later.',
    ),
    FailureKind.server => (
      title: 'Server-side problem.',
      body: 'Something went wrong on our side. Please try again.',
    ),
    FailureKind.unauthorized => (
      title: 'Your session has ended.',
      body: 'Please sign in again.',
    ),
    FailureKind.forbidden => (
      title: 'Not allowed.',
      body: f.message ?? 'Your account can\'t do this.',
    ),
    _ => (
      title: 'Something went wrong.',
      body: f.message ?? 'Please try again.',
    ),
  };

  /// True when a register/account error means the email is taken.
  static bool isDuplicateAccount(Failure f) {
    if (f.kind != FailureKind.validation && f.kind != FailureKind.badRequest) {
      return false;
    }
    final text = '${f.code ?? ''} ${f.message ?? ''}'.toLowerCase();
    return text.contains('already') ||
        text.contains('exists') ||
        text.contains('duplicate');
  }
}
