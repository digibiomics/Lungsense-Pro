import '../../../../core/utils/paged.dart';
import '../../domain/entities/patient.dart';
import '../../domain/repositories/patient_repository.dart';
import '../datasources/patient_remote_data_source.dart';

class PatientRepositoryImpl implements PatientRepository {
  const PatientRepositoryImpl(this._remote);
  final PatientRemoteDataSource _remote;

  @override
  Future<Paged<PatientSummary>> list({String? search, int offset = 0}) =>
      _remote.list(search: search, offset: offset);

  @override
  Future<Patient> get(String id) => _remote.get(id);

  @override
  Future<Patient> create(PatientInput input, {bool allowDuplicate = false}) =>
      _remote.create(input, allowDuplicate);

  @override
  Future<Patient> update(String id, PatientInput input) =>
      _remote.update(id, input);

  @override
  Future<Patient> mine() => _remote.mine();

  @override
  Future<Patient> setMyConsent(ConsentStatus status) =>
      _remote.setMyConsent(status);
}
