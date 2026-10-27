import '../../../../core/utils/paged.dart';
import '../entities/patient.dart';
import '../repositories/patient_repository.dart';

class ListPatients {
  const ListPatients(this._repo);
  final PatientRepository _repo;
  Future<Paged<PatientSummary>> call({String? search, int offset = 0}) {
    final q = search?.trim();
    return _repo.list(
      search: q == null || q.isEmpty ? null : q,
      offset: offset,
    );
  }
}

class GetPatient {
  const GetPatient(this._repo);
  final PatientRepository _repo;
  Future<Patient> call(String id) => _repo.get(id);
}

class SavePatient {
  const SavePatient(this._repo);
  final PatientRepository _repo;

  /// Creates a patient, or updates [id] when given.
  Future<Patient> call(
    PatientInput input, {
    String? id,
    bool allowDuplicate = false,
  }) => id == null
      ? _repo.create(input, allowDuplicate: allowDuplicate)
      : _repo.update(id, input);
}
