import '../../../../core/utils/paged.dart';
import '../entities/patient.dart';

/// Documented `/api/v1/patients` operations: the record operations for
/// doctors, and [mine] / [setMyConsent] for a signed-in patient. Methods
/// throw `Failure`; [create] also throws [PossibleDuplicate].
abstract interface class PatientRepository {
  Future<Paged<PatientSummary>> list({String? search, int offset = 0});
  Future<Patient> get(String id);
  Future<Patient> create(PatientInput input, {bool allowDuplicate = false});
  Future<Patient> update(String id, PatientInput input);

  /// The signed-in patient's own record (`GET /patients/me`).
  Future<Patient> mine();

  /// Records the patient's own research consent (`PATCH /patients/me`).
  Future<Patient> setMyConsent(ConsentStatus status);
}
