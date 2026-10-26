import '../../domain/entities/doctor_application.dart';
import '../../domain/repositories/admin_repository.dart';
import '../datasources/admin_remote_data_source.dart';

class AdminRepositoryImpl implements AdminRepository {
  const AdminRepositoryImpl(this._remote);
  final AdminRemoteDataSource _remote;

  @override
  Future<List<DoctorApplication>> listDoctorApplications() =>
      _remote.listDoctors();

  @override
  Future<void> approveDoctor(String userId) => _remote.approve(userId);

  @override
  Future<void> rejectDoctor(String userId, {required String reason}) =>
      _remote.reject(userId, reason);
}
