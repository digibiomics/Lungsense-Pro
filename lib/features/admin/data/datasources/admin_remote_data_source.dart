import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/error_mapper.dart';
import '../../domain/entities/doctor_application.dart';
import '../models/doctor_application_model.dart';

class AdminRemoteDataSource {
  const AdminRemoteDataSource(this._dio);
  final Dio _dio;

  Future<List<DoctorApplication>> listDoctors() => _guard(() async {
    final r = await _dio.get<Object?>(ApiEndpoints.adminDoctors);
    return DoctorApplicationModel.listFromJson(r.data);
  });

  /// Success is any 2xx; the response body is not documented and ignored.
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

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }
}
