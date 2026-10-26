import 'package:flutter/foundation.dart';

/// Development-only logger. Never pass request/response bodies here; use
/// [redact] for anything that might contain user data.
abstract final class AppLogger {
  static const _sensitiveKeys = {
    'password',
    'new_password',
    'access_token',
    'refresh_token',
    'otp_code',
    'code',
    'code_verifier',
    'authorization',
    'token',
  };

  static void debug(String message) {
    if (kDebugMode) debugPrint('[LungSensePro] $message');
  }

  /// Returns a copy of [data] with sensitive values replaced by `***`.
  static Object? redact(Object? data) {
    if (data is Map) {
      return {
        for (final e in data.entries)
          e.key: _sensitiveKeys.contains('${e.key}'.toLowerCase())
              ? '***'
              : redact(e.value),
      };
    }
    if (data is List) return data.map(redact).toList();
    return data;
  }
}
