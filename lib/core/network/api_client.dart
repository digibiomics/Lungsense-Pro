import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/api_config.dart';
import '../logging/app_logger.dart';

/// Builds the single Dio instance used for all backend calls.
/// Auth handling is added by registering an `AuthInterceptor` on it.
Dio createDio({String baseUrl = ApiConfig.baseUrl}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      sendTimeout: ApiConfig.receiveTimeout,
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
      headers: const {'Accept': 'application/json'},
    ),
  );
  if (kDebugMode) dio.interceptors.add(_SafeLogInterceptor());
  return dio;
}

/// Logs method, path and status only. Bodies and headers are never logged
/// because they carry passwords, OTPs and tokens.
class _SafeLogInterceptor extends Interceptor {
  @override
  void onResponse(Response<dynamic> r, ResponseInterceptorHandler handler) {
    AppLogger.debug(
      '${r.requestOptions.method} ${r.requestOptions.path} -> ${r.statusCode}',
    );
    handler.next(r);
  }

  @override
  void onError(DioException e, ErrorInterceptorHandler handler) {
    AppLogger.debug(
      '${e.requestOptions.method} ${e.requestOptions.path} -> '
      '${e.response?.statusCode ?? e.type.name}',
    );
    handler.next(e);
  }
}
