import '../../../../core/utils/paged.dart';
import '../../domain/entities/admin_user.dart';
import '../../domain/entities/doctor_application.dart';
import '../../domain/repositories/admin_repository.dart';
import '../datasources/admin_remote_data_source.dart';

class AdminRepositoryImpl implements AdminRepository {
  const AdminRepositoryImpl(this._remote);
  final AdminRemoteDataSource _remote;

  /// The list endpoint filters by one status, so the three approval tabs
  /// are read with three requests.
  static const _statuses = ['pending_approval', 'active', 'rejected'];

  @override
  Future<List<DoctorApplication>> listDoctorApplications() async {
    final lists = await Future.wait([
      for (final s in _statuses) _remote.listDoctors(status: s),
    ]);
    final seen = <String>{};
    return [
      for (final l in lists)
        for (final a in l)
          if (seen.add(a.userId)) a,
    ];
  }

  @override
  Future<void> approveDoctor(String userId) => _remote.approve(userId);

  @override
  Future<void> rejectDoctor(String userId, {required String reason}) =>
      _remote.reject(userId, reason);

  @override
  Future<Paged<AdminUser>> listUsers({String? search, int offset = 0}) =>
      _remote.listUsers(search: search, offset: offset);

  @override
  Future<AdminUser> setUserStatus(
    String userId,
    UserStatusChange status, {
    String? reason,
  }) => _remote.setStatus(userId, status, reason);
}
