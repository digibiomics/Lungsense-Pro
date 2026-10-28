import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/error_mapper.dart';
import '../../../../core/utils/paged.dart';
import '../../domain/entities/patient.dart';
import '../models/patient_models.dart';

class PatientRemoteDataSource {
  const PatientRemoteDataSource(this._dio);
  final Dio _dio;

  static const pageSize = 50;

  Future<Paged<PatientSummary>> list({String? search, int offset = 0}) =>
      _guard(() async {
        final r = await _dio.get<Object?>(
          ApiEndpoints.patients,
          queryParameters: {
            'search': ?search,
            'limit': pageSize,
            'offset': offset,
          },
        );
        return PatientModels.pageFromJson(r.data);
      });

  Future<Patient> get(String id) => _guard(() async {
    final r = await _dio.get<Object?>(ApiEndpoints.patient(id));
    return PatientModels.fromJson(r.data);
  });

  Future<Patient> create(PatientInput input, bool allowDuplicate) =>
      _guard(() async {
        final r = await _dio.post<Object?>(
          ApiEndpoints.patients,
          data: PatientModels.body(input, allowDuplicate: allowDuplicate),
        );
        return PatientModels.fromJson(r.data);
      });

  Future<Patient> update(String id, PatientInput input) => _guard(() async {
    final r = await _dio.patch<Object?>(
      ApiEndpoints.patient(id),
      data: PatientModels.body(input),
    );
    return PatientModels.fromJson(r.data);
  });

  Future<Patient> mine() => _guard(() async {
    final r = await _dio.get<Object?>(ApiEndpoints.myPatientRecord);
    return PatientModels.fromJson(r.data);
  });

  /// `PATCH /patients/me` (`PatientSelfUpdate`) with the details form.
  Future<Patient> updateMine(PatientInput input) => _guard(() async {
    final r = await _dio.patch<Object?>(
      ApiEndpoints.myPatientRecord,
      data: PatientModels.selfBody(input),
    );
    return PatientModels.fromJson(r.data);
  });

  /// `PATCH /patients/me` (`PatientSelfUpdate`) with the consent only.
  Future<Patient> setMyConsent(ConsentStatus status) => _guard(() async {
    final r = await _dio.patch<Object?>(
      ApiEndpoints.myPatientRecord,
      data: {'consent_status': status.api},
    );
    return PatientModels.fromJson(r.data);
  });

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      final dup = PatientModels.duplicateFrom(
        e.response?.statusCode,
        e.response?.data,
      );
      if (dup != null) throw dup;
      throw ErrorMapper.fromDio(e);
    }
  }
}
