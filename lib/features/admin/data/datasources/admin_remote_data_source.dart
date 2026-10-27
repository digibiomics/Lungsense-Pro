import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/error_mapper.dart';
import '../../../../core/utils/paged.dart';
import '../../domain/entities/admin_user.dart';
import '../../domain/entities/doctor_application.dart';
import '../models/admin_user_model.dart';
import '../models/doctor_application_model.dart';

class AdminRemoteDataSource {
  const AdminRemoteDataSource(this._dio);
  final Dio _dio;

  static const pageSize = 50;

  /// `GET /admin/doctors?status=` (the server defaults to
  /// `pending_approval`).
  Future<List<DoctorApplication>> listDoctors({String? status}) =>
      _guard(() async {
        final r = await _dio.get<Object?>(
          ApiEndpoints.adminDoctors,
          queryParameters: {'status': ?status, 'limit': 100},
        );
        return DoctorApplicationModel.listFromJson(r.data);
      });

  /// Success is any 2xx; the `AdminDoctorOut` body is not needed.
  Future<void> approve(String userId) => _guard(() async {
    await _dio.post<Object?>(ApiEndpoints.approveDoctor(userId));
  });

  /// Documented body: `{"reason": "..."}`.
  Future<void> reject(String userId, String reason) => _guard(() async {
    await _dio.post<Object?>(
      ApiEndpoints.rejectDoctor(userId),
      data: {'reason': reason},
    );
  });

  Future<Paged<AdminUser>> listUsers({String? search, int offset = 0}) =>
      _guard(() async {
        final r = await _dio.get<Object?>(
          ApiEndpoints.adminUsers,
          queryParameters: {
            'search': ?search,
            'limit': pageSize,
            'offset': offset,
          },
        );
        return AdminUserModel.pageFromJson(r.data);
      });

  /// `StatusUpdate`: `{"account_status": ..., "reason": ...?}`.
  Future<AdminUser> setStatus(
    String userId,
    UserStatusChange status,
    String? reason,
  ) => _guard(() async {
    final r = await _dio.patch<Object?>(
      ApiEndpoints.userStatus(userId),
      data: {'account_status': status.api, 'reason': ?reason},
    );
    return AdminUserModel.fromJson(r.data);
  });

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }
}
