import 'package:dio/dio.dart';

import '../errors/failure.dart';

/// Converts transport and HTTP errors into [Failure]s.
///
/// Supports the documented FastAPI error shapes:
/// * `{"detail": "Invalid login credentials"}`
/// * `{"detail": {"code": "account_pending_approval", "message": "..."}}`
/// * FastAPI validation: `{"detail": [{"loc": [...], "msg": "..."}]}`
abstract final class ErrorMapper {
  static Failure fromDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const Failure(kind: FailureKind.timeout);
      case DioExceptionType.connectionError:
        return const Failure(kind: FailureKind.network);
      case DioExceptionType.badCertificate:
        return const Failure(kind: FailureKind.network);
      case DioExceptionType.cancel:
        return const Failure(kind: FailureKind.unknown);
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        final response = e.response;
        if (response == null) {
          return const Failure(kind: FailureKind.network);
        }
        return fromResponse(response.statusCode, response.data);
    }
  }

  static Failure fromResponse(int? statusCode, Object? body) {
    final parsed = _parseDetail(body);
    return Failure(
      kind: _kindFor(statusCode),
      statusCode: statusCode,
      code: parsed.code,
      message: parsed.message,
      fieldErrors: parsed.fieldErrors,
    );
  }

  static FailureKind _kindFor(int? status) {
    return switch (status) {
      400 => FailureKind.badRequest,
      401 => FailureKind.unauthorized,
      403 => FailureKind.forbidden,
      404 => FailureKind.notFound,
      409 || 422 => FailureKind.validation,
      429 => FailureKind.rateLimited,
      503 => FailureKind.serviceUnavailable,
      final int s when s >= 500 => FailureKind.server,
      _ => FailureKind.unknown,
    };
  }

  static ({String? code, String? message, Map<String, String> fieldErrors})
  _parseDetail(Object? body) {
    if (body is! Map) return (code: null, message: null, fieldErrors: const {});
    final detail = body['detail'];

    if (detail is String) {
      return (code: null, message: detail, fieldErrors: const {});
    }
    if (detail is Map) {
      final code = detail['code'];
      final message = detail['message'];
      return (
        code: code is String ? code : null,
        message: message is String ? message : null,
        fieldErrors: const {},
      );
    }
    if (detail is List) {
      final fields = <String, String>{};
      String? first;
      for (final item in detail) {
        if (item is! Map) continue;
        final msg = item['msg'];
        if (msg is! String) continue;
        first ??= msg;
        final loc = item['loc'];
        if (loc is List && loc.isNotEmpty) {
          fields.putIfAbsent('${loc.last}', () => _cleanPydantic(msg));
        }
      }
      return (
        code: null,
        message: first == null ? null : _cleanPydantic(first),
        fieldErrors: fields,
      );
    }
    return (code: null, message: null, fieldErrors: const {});
  }

  /// Pydantic prefixes custom validator messages with "Value error, ".
  static String _cleanPydantic(String msg) =>
      msg.startsWith('Value error, ') ? msg.substring(13) : msg;
}
