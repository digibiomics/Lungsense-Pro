import 'package:equatable/equatable.dart';

/// `sex` enum of the patient schemas.
enum PatientSex {
  female('female', 'Female'),
  male('male', 'Male'),
  other('other', 'Other'),
  unknown('unknown', 'Not recorded');

  const PatientSex(this.api, this.label);
  final String api;
  final String label;

  static PatientSex? fromApi(String? v) {
    for (final s in values) {
      if (s.api == v) return s;
    }
    return null;
  }
}

/// `consent_status` enum of the patient schemas.
enum ConsentStatus {
  notRecorded('not_recorded', 'Not recorded'),
  given('given', 'Given'),
  withdrawn('withdrawn', 'Withdrawn');

  const ConsentStatus(this.api, this.label);
  final String api;
  final String label;

  static ConsentStatus fromApi(String? v) {
    for (final s in values) {
      if (s.api == v) return s;
    }
    return ConsentStatus.notRecorded;
  }
}

/// One row of `GET /api/v1/patients` (`PatientListItem`).
class PatientSummary extends Equatable {
  const PatientSummary({
    required this.id,
    required this.studyId,
    required this.consent,
    required this.isArchived,
    required this.sessionCount,
    this.fullName,
    this.ageYears,
    this.sex,
    this.externalId,
    this.lastSessionAt,
  });

  final String id;

  /// Server-assigned research ID (e.g. LS-0142), shown instead of names.
  final String studyId;
  final String? fullName;
  final int? ageYears;
  final PatientSex? sex;
  final String? externalId;
  final ConsentStatus consent;
  final bool isArchived;
  final int sessionCount;
  final DateTime? lastSessionAt;

  @override
  List<Object?> get props => [
    id,
    studyId,
    fullName,
    ageYears,
    sex,
    externalId,
    consent,
    isArchived,
    sessionCount,
    lastSessionAt,
  ];
}

/// A full patient record (`PatientOut`). Fields the Pro design does not
/// collect (name, phone, height, weight, smoking) are kept only for display.
class Patient extends Equatable {
  const Patient({
    required this.id,
    required this.studyId,
    required this.consent,
    required this.isArchived,
    this.fullName,
    this.externalId,
    this.ageYears,
    this.dateOfBirth,
    this.sex,
    this.relevantHistory,
    this.consentVersion,
    this.consentRecordedAt,
    this.createdAt,
  });

  final String id;
  final String studyId;
  final String? fullName;
  final String? externalId;
  final int? ageYears;
  final DateTime? dateOfBirth;
  final PatientSex? sex;
  final String? relevantHistory;
  final ConsentStatus consent;
  final String? consentVersion;
  final DateTime? consentRecordedAt;
  final bool isArchived;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [
    id,
    studyId,
    fullName,
    externalId,
    ageYears,
    dateOfBirth,
    sex,
    relevantHistory,
    consent,
    consentVersion,
    consentRecordedAt,
    isArchived,
    createdAt,
  ];
}

/// What the Add/Edit patient form sends (AddPatient.dc.html fields plus
/// research consent). Null fields are left out of the request.
class PatientInput extends Equatable {
  const PatientInput({
    required this.externalId,
    required this.ageYears,
    required this.sex,
    required this.consent,
    this.relevantHistory,
  });

  final String externalId;
  final int ageYears;
  final PatientSex sex;
  final ConsentStatus consent;
  final String? relevantHistory;

  @override
  List<Object?> get props => [
    externalId,
    ageYears,
    sex,
    consent,
    relevantHistory,
  ];
}

/// An existing record the server matched as a possible duplicate.
class DuplicateMatch extends Equatable {
  const DuplicateMatch({this.id, this.studyId, this.externalId});
  final String? id;
  final String? studyId;
  final String? externalId;

  @override
  List<Object?> get props => [id, studyId, externalId];
}

/// `409 possible_duplicate` from `POST /patients`. Resending with
/// `allow_duplicate: true` creates the record anyway.
class PossibleDuplicate implements Exception {
  const PossibleDuplicate(this.matches, {this.message});
  final List<DuplicateMatch> matches;
  final String? message;
}
