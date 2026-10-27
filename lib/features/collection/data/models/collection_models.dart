import '../../../../core/network/json_read.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../core/utils/paged.dart';
import '../../domain/entities/collection_session.dart';
import '../../domain/entities/dashboard_stats.dart';
import '../../domain/entities/recording.dart';
import '../../domain/entities/symptoms.dart';

/// Parsers and request bodies for the documented collection schemas
/// (docs/openapi_snapshot.json).
abstract final class CollectionModels {
  static const _session = 'collection session';

  static Paged<SessionSummary> pageFromJson(Object? json) {
    final p = JsonRead.page(json, summaryFromJson, 'session list');
    return Paged(items: p.items, total: p.total);
  }

  static SessionSummary summaryFromJson(Object? json) {
    final m = JsonRead.map(json, _session);
    final c = m['counts'] is Map
        ? (m['counts'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};
    return SessionSummary(
      id: JsonRead.reqStr(m, 'id', _session),
      patientId: JsonRead.reqStr(m, 'patient_id', _session),
      studyId: JsonRead.reqStr(m, 'study_id', _session),
      status: SessionStatus.fromApi(JsonRead.str(m['status'])),
      source: JsonRead.str(m['collection_source']),
      notes: JsonRead.str(m['notes']),
      startedAt: JsonRead.date(m['started_at']),
      completedAt: JsonRead.date(m['completed_at']),
      updatedAt: JsonRead.date(m['updated_at']),
      counts: SessionCounts(
        cough: JsonRead.integer(c['cough_recordings']) ?? 0,
        breathing: JsonRead.integer(c['breathing_recordings']) ?? 0,
        xrays: JsonRead.integer(c['xray_images']) ?? 0,
        symptomsRecorded: JsonRead.boolean(c['symptoms_recorded']) ?? false,
      ),
    );
  }

  static CollectionSession sessionFromJson(Object? json) {
    final m = JsonRead.map(json, _session);
    final patient = m['patient'] is Map
        ? (m['patient'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};
    final missing = <CollectionStep>[
      for (final v in JsonRead.list(m['missing_modalities']))
        if (v is String) ?CollectionStep.fromApi(v),
    ];
    return CollectionSession(
      summary: summaryFromJson(m),
      patientName: JsonRead.str(patient['full_name']),
      symptoms: m['symptoms'] == null ? null : symptomsFromJson(m['symptoms']),
      recordings: [
        for (final r in JsonRead.list(m['audio_recordings'])) audioFromJson(r),
      ],
      xrays: [for (final x in JsonRead.list(m['xray_images'])) xrayFromJson(x)],
      missing: missing,
    );
  }

  static SymptomRatings symptomsFromJson(Object? json) {
    final m = JsonRead.map(json, 'symptom form');
    final values = <SymptomKey, int>{};
    for (final k in SymptomKey.values) {
      final v = JsonRead.integer(m[k.api]);
      if (v != null && v >= 0 && v <= 3) values[k] = v;
    }
    return SymptomRatings(
      values,
      checkinDate: JsonRead.date(m['checkin_date']),
    );
  }

  /// `SessionSymptomsIn`: all ten ratings. `checkin_date` is left to the
  /// server unless the form already had one.
  static Map<String, dynamic> symptomsBody(SymptomRatings r) {
    if (!r.isComplete) {
      throw ArgumentError('All ten symptoms must be rated before saving.');
    }
    return {
      if (r.checkinDate != null)
        'checkin_date': LsDates.isoDate(r.checkinDate!),
      for (final k in SymptomKey.values) k.api: r[k],
    };
  }

  static AudioRecording audioFromJson(Object? json) {
    const what = 'recording';
    final m = JsonRead.map(json, what);
    return AudioRecording(
      id: JsonRead.reqStr(m, 'id', what),
      type: RecordingType.fromApi(JsonRead.str(m['recording_type'])),
      contentType: JsonRead.str(m['content_type']) ?? '',
      uploadStatus: JsonRead.str(m['upload_status']) ?? '',
      processingStatus: JsonRead.str(m['processing_status']) ?? '',
      sizeBytes: JsonRead.integer(m['size_bytes']),
      qcPassed: JsonRead.boolean(m['qc_passed']),
      qcReason: JsonRead.str(m['qc_reason']),
      durationSeconds: JsonRead.number(m['duration_seconds']),
      qualityScore: JsonRead.number(m['quality_score']),
      createdAt: JsonRead.date(m['created_at']),
      uploadedAt: JsonRead.date(m['uploaded_at']),
    );
  }

  static XrayImage xrayFromJson(Object? json) {
    const what = 'X-ray';
    final m = JsonRead.map(json, what);
    return XrayImage(
      id: JsonRead.reqStr(m, 'id', what),
      contentType: JsonRead.str(m['content_type']) ?? '',
      uploadStatus: JsonRead.str(m['upload_status']) ?? '',
      fileName: JsonRead.str(m['original_filename']),
      sizeBytes: JsonRead.integer(m['size_bytes']),
      view: XrayView.fromApi(JsonRead.str(m['view'])),
      takenOn: JsonRead.date(m['taken_on']),
      notes: JsonRead.str(m['notes']),
      uploadedAt: JsonRead.date(m['uploaded_at']),
    );
  }

  static DashboardStats dashboardFromJson(Object? json) {
    const what = 'dashboard';
    final m = JsonRead.map(json, what);
    int n(String k) => JsonRead.integer(m[k]) ?? 0;
    return DashboardStats(
      patientsRegistered: n('patients_registered'),
      patientsRecorded: n('patients_recorded'),
      sessionsTotal: n('sessions_total'),
      sessionsCompleted: n('sessions_completed'),
      sessionsDraft: n('sessions_draft'),
      coughRecordings: n('cough_recordings'),
      breathingRecordings: n('breathing_recordings'),
      xrayImages: n('xray_images'),
      recordingsFailedQc: n('recordings_failed_qc'),
      draftsMissingItems: n('draft_sessions_missing_items'),
      incompleteUploads: n('incomplete_uploads'),
      recent: [
        for (final r in JsonRead.list(m['recent_activity'])) _recentFromJson(r),
      ],
    );
  }

  static RecentSession _recentFromJson(Object? json) {
    const what = 'dashboard';
    final m = JsonRead.map(json, what);
    return RecentSession(
      sessionId: JsonRead.reqStr(m, 'session_id', what),
      patientId: JsonRead.reqStr(m, 'patient_id', what),
      studyId: JsonRead.reqStr(m, 'study_id', what),
      status: SessionStatus.fromApi(JsonRead.str(m['status'])),
      startedAt: JsonRead.date(m['started_at']),
      completedAt: JsonRead.date(m['completed_at']),
    );
  }

  /// `UploadTicket`: the presigned POST target and its form fields.
  static ({String id, Uri url, Map<String, String> fields, int? maxBytes})
  ticketFromJson(Object? json) {
    const what = 'upload ticket';
    final m = JsonRead.map(json, what);
    final upload = JsonRead.map(m['upload'], what);
    final url = Uri.tryParse(JsonRead.reqStr(upload, 'url', what));
    if (url == null || !url.hasScheme) throw JsonRead.unexpected(what);
    final fields = <String, String>{};
    final raw = upload['fields'];
    if (raw is Map) {
      raw.forEach((k, v) {
        final s = JsonRead.str(v);
        if (s != null) fields['$k'] = s;
      });
    }
    return (
      id: JsonRead.reqStr(m, 'id', what),
      url: url,
      fields: fields,
      maxBytes: JsonRead.integer(m['max_bytes']),
    );
  }

  /// Reads `409 incomplete_session` (`detail.missing`).
  static IncompleteSession? incompleteFrom(int? status, Object? body) {
    if (status != 409 || body is! Map) return null;
    final detail = body['detail'];
    if (detail is! Map) return null;
    final code = JsonRead.str(detail['code']);
    final missing = <CollectionStep>[
      for (final v in JsonRead.list(detail['missing']))
        if (v is String) ?CollectionStep.fromApi(v),
    ];
    if (code != 'incomplete_session' && missing.isEmpty) return null;
    return IncompleteSession(missing);
  }
}
