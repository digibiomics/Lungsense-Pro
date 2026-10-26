import '../entities/doctor_application.dart';
import '../repositories/admin_repository.dart';

class ListDoctorApplications {
  const ListDoctorApplications(this._repo);
  final AdminRepository _repo;
  Future<List<DoctorApplication>> call() => _repo.listDoctorApplications();
}

class ApproveDoctor {
  const ApproveDoctor(this._repo);
  final AdminRepository _repo;
  Future<void> call(String userId) => _repo.approveDoctor(userId);
}

class RejectDoctor {
  const RejectDoctor(this._repo);
  final AdminRepository _repo;
  Future<void> call(String userId, String reason) =>
      _repo.rejectDoctor(userId, reason: reason.trim());
}
