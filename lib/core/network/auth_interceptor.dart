import 'package:dio/dio.dart';

import '../errors/failure.dart';
import '../storage/token_storage.dart';

/// Request option keys understood by [AuthInterceptor].
abstract final class AuthOptions {
  /// Set to `false` for public endpoints (login, register, refresh, ...).
  static const requiresAuth = 'requiresAuth';

  /// Internal: marks a request that was already retried after a refresh.
  static const retried = 'authRetried';

  /// Public endpoint options: no Authorization header, no refresh on 401.
  static Options public() => Options(extra: {requiresAuth: false});
}

/// Exchanges the stored refresh token for new tokens.
///
/// Implementations must be single-flight (concurrent callers share one
/// refresh), save the returned tokens, and clear the session when the server
/// rejects the refresh token. They throw a [Failure] on error.
abstract interface class SessionRefresher {
  Future<String> refreshAccessToken();
}

/// Attaches `Authorization: Bearer <access_token>` to protected requests and,
/// on a 401, refreshes the session once and retries the request once.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this._dio,
    required this._storage,
    required this._refresher,
  });

  final Dio _dio;
  final TokenStorage _storage;
  final SessionRefresher _refresher;

  static const _tokenUsedKey = 'authTokenUsed';

  bool _requiresAuth(RequestOptions o) =>
      o.extra[AuthOptions.requiresAuth] != false;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_requiresAuth(options)) {
      final token = await _storage.readAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
        options.extra[_tokenUsedKey] = token;
      }
    } else {
      options.headers.remove('Authorization');
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final eligible =
        err.response?.statusCode == 401 &&
        _requiresAuth(options) &&
        options.extra[AuthOptions.retried] != true;
    if (!eligible) return handler.next(err);

    try {
      // If another request already refreshed while this one was in flight,
      // retry with the newer token instead of refreshing again.
      final current = await _storage.readAccessToken();
      final used = options.extra[_tokenUsedKey];
      if (current == null || current == used) {
        await _refresher.refreshAccessToken();
      }
    } on Failure {
      // Refresher has already cleared the session if the token was rejected.
      return handler.next(err);
    }

    try {
      options.extra[AuthOptions.retried] = true;
      final response = await _dio.fetch<dynamic>(options);
      handler.resolve(response);
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }
}
