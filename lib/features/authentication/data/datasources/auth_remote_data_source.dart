import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/auth_interceptor.dart';
import '../../../../core/network/error_mapper.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/entities/app_user.dart';
import '../models/auth_models.dart';

/// Calls the documented LungSense Pro auth endpoints. Converts every error
/// into a `Failure`.
class AuthRemoteDataSource {
  const AuthRemoteDataSource(this._dio);
  final Dio _dio;

  Future<TokenResponseModel> login(String email, String password) =>
      _guard(() async {
        final r = await _dio.post<Object?>(
          ApiEndpoints.login,
          data: {'email': email, 'password': password},
          options: AuthOptions.public(),
        );
        return TokenResponseModel.fromJson(r.data);
      });

  Future<TokenResponseModel> refresh(String refreshToken) => _guard(() async {
    final r = await _dio.post<Object?>(
      ApiEndpoints.refresh,
      data: {'refresh_token': refreshToken},
      options: AuthOptions.public(),
    );
    return TokenResponseModel.fromJson(r.data);
  });

  Future<AppUser> me() => _guard(() async {
    final r = await _dio.get<Object?>(ApiEndpoints.me);
    return UserModel.fromJson(r.data);
  });

  Future<void> resendConfirmation(String email) => _guard(() async {
    await _dio.post<Object?>(
      ApiEndpoints.resendConfirmation,
      data: {'email': email},
      options: AuthOptions.public(),
    );
  });

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    } on Failure {
      rethrow;
    } on FormatException {
      throw const Failure(kind: FailureKind.unknown);
    }
  }
}
