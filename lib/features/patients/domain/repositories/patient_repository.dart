import '../../../../core/utils/paged.dart';
import '../entities/patient.dart';

/// Documented `/api/v1/patients` operations for doctors. Methods throw
/// `Failure`; [create] also throws [PossibleDuplicate].
abstract interface class PatientRepository {
  Future<Paged<PatientSummary>> list({String? search, int offset = 0});
  Future<Patient> get(String id);
  Future<Patient> create(PatientInput input, {bool allowDuplicate = false});
  Future<Patient> update(String id, PatientInput input);
}
