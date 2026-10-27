import '../../../../core/network/json_read.dart';
import '../../../../core/utils/paged.dart';
import '../../domain/entities/patient.dart';

/// Parsers and request bodies for the documented patient schemas.
abstract final class PatientModels {
  static const _what = 'patient record';
  static const _list = 'patient list';

  static Paged<PatientSummary> pageFromJson(Object? json) {
    final p = JsonRead.page(json, summaryFromJson, _list);
    return Paged(items: p.items, total: p.total);
  }

  static PatientSummary summaryFromJson(Object? json) {
    final m = JsonRead.map(json, _list);
    return PatientSummary(
      id: JsonRead.reqStr(m, 'id', _list),
      studyId: JsonRead.reqStr(m, 'study_id', _list),
      fullName: JsonRead.str(m['full_name']),
      ageYears: JsonRead.integer(m['age_years']),
      sex: PatientSex.fromApi(JsonRead.str(m['sex'])),
      externalId: JsonRead.str(m['external_id']),
      consent: ConsentStatus.fromApi(JsonRead.str(m['consent_status'])),
      isArchived: JsonRead.boolean(m['is_archived']) ?? false,
      sessionCount: JsonRead.integer(m['session_count']) ?? 0,
      lastSessionAt: JsonRead.date(m['last_session_at']),
    );
  }

  static Patient fromJson(Object? json) {
    final m = JsonRead.map(json, _what);
    return Patient(
      id: JsonRead.reqStr(m, 'id', _what),
      studyId: JsonRead.reqStr(m, 'study_id', _what),
      fullName: JsonRead.str(m['full_name']),
      externalId: JsonRead.str(m['external_id']),
      ageYears: JsonRead.integer(m['age_years']),
      dateOfBirth: JsonRead.date(m['date_of_birth']),
      sex: PatientSex.fromApi(JsonRead.str(m['sex'])),
      relevantHistory: JsonRead.str(m['relevant_history']),
      consent: ConsentStatus.fromApi(JsonRead.str(m['consent_status'])),
      consentVersion: JsonRead.str(m['consent_version']),
      consentRecordedAt: JsonRead.date(m['consent_recorded_at']),
      isArchived: JsonRead.boolean(m['is_archived']) ?? false,
      createdAt: JsonRead.date(m['created_at']),
    );
  }

  /// `PatientCreate` / `PatientUpdate` body with the form's fields only.
  static Map<String, dynamic> body(PatientInput i, {bool? allowDuplicate}) => {
    'external_id': i.externalId.trim(),
    'age_years': i.ageYears,
    'sex': i.sex.api,
    'consent_status': i.consent.api,
    'relevant_history': _blankToNull(i.relevantHistory),
    'allow_duplicate': ?allowDuplicate,
  };

  /// Reads a `409 possible_duplicate` reply. The shape of the matches is
  /// not documented (KI-17), so any list of objects under `detail` that
  /// carry `study_id` or `id` is read; a 409 without them still counts.
  static PossibleDuplicate? duplicateFrom(int? status, Object? body) {
    if (status != 409 || body is! Map) return null;
    final detail = body['detail'];
    String? code;
    String? message;
    final matches = <DuplicateMatch>[];
    void collect(Object? v) {
      if (v is! List) return;
      for (final item in v) {
        if (item is! Map) continue;
        final m = item.cast<String, dynamic>();
        final match = DuplicateMatch(
          id: JsonRead.str(m['id']) ?? JsonRead.str(m['patient_id']),
          studyId: JsonRead.str(m['study_id']),
          externalId: JsonRead.str(m['external_id']),
        );
        if (match.id != null || match.studyId != null) matches.add(match);
      }
    }

    if (detail is Map) {
      code = JsonRead.str(detail['code']);
      message = JsonRead.str(detail['message']);
      detail.values.forEach(collect);
    } else if (detail is String) {
      message = detail;
    }
    final text = '${code ?? ''} ${message ?? ''}'.toLowerCase();
    if (code != 'possible_duplicate' &&
        !text.contains('duplicate') &&
        matches.isEmpty) {
      return null;
    }
    return PossibleDuplicate(matches, message: message);
  }

  static String? _blankToNull(String? v) {
    final t = v?.trim();
    return t == null || t.isEmpty ? null : t;
  }
}
