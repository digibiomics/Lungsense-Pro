import '../../../../core/utils/paged.dart';
import '../entities/admin_user.dart';
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

class ListUsers {
  const ListUsers(this._repo);
  final AdminRepository _repo;
  Future<Paged<AdminUser>> call({String? search, int offset = 0}) {
    final q = search?.trim();
    return _repo.listUsers(
      search: q == null || q.isEmpty ? null : q,
      offset: offset,
    );
  }
}

class SetUserStatus {
  const SetUserStatus(this._repo);
  final AdminRepository _repo;
  Future<AdminUser> call(
    String userId,
    UserStatusChange status, {
    String? reason,
  }) {
    final r = reason?.trim();
    return _repo.setUserStatus(
      userId,
      status,
      reason: r == null || r.isEmpty ? null : r,
    );
  }
}
