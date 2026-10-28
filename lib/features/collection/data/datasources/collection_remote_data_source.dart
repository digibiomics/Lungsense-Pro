import 'package:dio/dio.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/error_mapper.dart';
import '../../../../core/network/json_read.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../core/utils/paged.dart';
import '../../domain/entities/collection_session.dart';
import '../../domain/entities/dashboard_stats.dart';
import '../../domain/entities/recording.dart';
import '../../domain/entities/symptoms.dart';
import '../models/collection_models.dart';

/// `/api/v1/collection` and `/patients/{id}/sessions`.
///
/// Files go straight to storage: the API returns a presigned POST
/// (`UploadTicket.upload` = url + form fields), the app posts the file there
/// with [_uploadDio] (no bearer token, no base URL), then calls `complete`.
class CollectionRemoteDataSource {
  const CollectionRemoteDataSource(this._dio, this._uploadDio);
  final Dio _dio;
  final Dio _uploadDio;

  Future<CollectionSession> createSession(String? patientId) =>
      _guard(() async {
        final r = await _dio.post<Object?>(
          ApiEndpoints.sessions,
          data: {'patient_id': ?patientId},
        );
        return CollectionModels.sessionFromJson(r.data);
      });

  Future<Paged<SessionSummary>> listSessions({
    SessionStatus? status,
    String? patientId,
    required int offset,
    required int limit,
  }) => _guard(() async {
    final r = await _dio.get<Object?>(
      ApiEndpoints.sessions,
      queryParameters: {
        if (status == SessionStatus.draft) 'status': 'draft',
        if (status == SessionStatus.completed) 'status': 'complete',
        'patient_id': ?patientId,
        'limit': limit,
        'offset': offset,
      },
    );
    return CollectionModels.pageFromJson(r.data);
  });

  Future<CollectionSession> getSession(String id) => _guard(() async {
    final r = await _dio.get<Object?>(ApiEndpoints.session(id));
    return CollectionModels.sessionFromJson(r.data);
  });

  /// `SessionUpdate`: `{"notes": ...}` (null clears them).
  Future<CollectionSession> updateNotes(String id, String? notes) =>
      _guard(() async {
        final r = await _dio.patch<Object?>(
          ApiEndpoints.session(id),
          data: {'notes': notes},
        );
        return CollectionModels.sessionFromJson(r.data);
      });

  Future<CollectionSession> completeSession(String id) async {
    try {
      final r = await _dio.post<Object?>(ApiEndpoints.completeSession(id));
      return CollectionModels.sessionFromJson(r.data);
    } on DioException catch (e) {
      final incomplete = CollectionModels.incompleteFrom(
        e.response?.statusCode,
        e.response?.data,
      );
      if (incomplete != null) throw incomplete;
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<SymptomRatings?> getSymptoms(String sessionId) => _guard(() async {
    final r = await _dio.get<Object?>(ApiEndpoints.sessionSymptoms(sessionId));
    return r.data == null || r.data == ''
        ? null
        : CollectionModels.symptomsFromJson(r.data);
  });

  Future<SymptomRatings> saveSymptoms(String sessionId, SymptomRatings s) =>
      _guard(() async {
        final r = await _dio.put<Object?>(
          ApiEndpoints.sessionSymptoms(sessionId),
          data: CollectionModels.symptomsBody(s),
        );
        return CollectionModels.symptomsFromJson(r.data);
      });

  Future<AudioRecording> uploadAudio(
    String sessionId,
    RecordingType type,
    LocalFile file,
    UploadProgress? onProgress,
  ) => _guard(() async {
    final t = await _dio.post<Object?>(
      ApiEndpoints.audioUploadUrl(sessionId),
      data: {
        'recording_type': type.api,
        'content_type': file.contentType,
        'file_size_bytes': file.sizeBytes,
      },
    );
    final ticket = CollectionModels.ticketFromJson(t.data);
    await _upload(ticket, file, onProgress);
    final done = await _dio.post<Object?>(
      ApiEndpoints.completeAudio(ticket.id),
    );
    return CollectionModels.audioFromJson(done.data);
  });

  Future<AudioRecording> getAudio(String id) => _guard(() async {
    final r = await _dio.get<Object?>(ApiEndpoints.audio(id));
    return CollectionModels.audioFromJson(r.data);
  });

  Future<void> deleteAudio(String id) => _guard(() async {
    await _dio.delete<Object?>(ApiEndpoints.audio(id));
  });

  Future<Uri> audioDownloadUrl(String id) =>
      _guard(() => _downloadUrl(ApiEndpoints.audioDownloadUrl(id)));

  Future<XrayImage> uploadXray(
    String sessionId,
    LocalFile file,
    XrayView? view,
    DateTime? takenOn,
    UploadProgress? onProgress,
  ) => _guard(() async {
    final t = await _dio.post<Object?>(
      ApiEndpoints.xrayUploadUrl(sessionId),
      data: {
        'content_type': file.contentType,
        'file_size_bytes': file.sizeBytes,
        'original_filename': file.name,
        'view': ?view?.api,
        if (takenOn != null) 'taken_on': LsDates.isoDate(takenOn),
      },
    );
    final ticket = CollectionModels.ticketFromJson(t.data);
    await _upload(ticket, file, onProgress);
    final done = await _dio.post<Object?>(ApiEndpoints.completeXray(ticket.id));
    return CollectionModels.xrayFromJson(done.data);
  });

  Future<void> deleteXray(String id) => _guard(() async {
    await _dio.delete<Object?>(ApiEndpoints.xray(id));
  });

  Future<Uri> xrayDownloadUrl(String id) =>
      _guard(() => _downloadUrl(ApiEndpoints.xrayDownloadUrl(id)));

  Future<DashboardStats> dashboard(DateTime? from, DateTime? to) =>
      _guard(() async {
        final r = await _dio.get<Object?>(
          ApiEndpoints.dashboard,
          queryParameters: {
            if (from != null) 'date_from': LsDates.isoDate(from),
            if (to != null) 'date_to': LsDates.isoDate(to),
          },
        );
        return CollectionModels.dashboardFromJson(r.data);
      });

  Future<Uri> _downloadUrl(String path) async {
    final r = await _dio.get<Object?>(path);
    final m = JsonRead.map(r.data, 'download link');
    final url = Uri.tryParse(JsonRead.reqStr(m, 'url', 'download link'));
    if (url == null || !url.hasScheme) {
      throw JsonRead.unexpected('download link');
    }
    return url;
  }

  /// Presigned POST: the ticket's fields first, the file last.
  Future<void> _upload(
    ({String id, Uri url, Map<String, String> fields, int? maxBytes}) ticket,
    LocalFile file,
    UploadProgress? onProgress,
  ) async {
    if (ticket.maxBytes != null && file.sizeBytes > ticket.maxBytes!) {
      throw const Failure(
        kind: FailureKind.validation,
        code: 'file_too_large',
        message: 'This file is larger than the server accepts.',
      );
    }
    final form = FormData.fromMap({
      ...ticket.fields,
      'file': await MultipartFile.fromFile(
        file.path,
        filename: file.name,
        contentType: DioMediaType.parse(file.contentType),
      ),
    });
    await _uploadDio.postUri<Object?>(
      ticket.url,
      data: form,
      onSendProgress: onProgress == null
          ? null
          : (sent, total) {
              if (total > 0) onProgress(sent / total);
            },
    );
  }

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }
}
