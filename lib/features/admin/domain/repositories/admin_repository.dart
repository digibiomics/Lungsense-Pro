import '../../../../core/utils/paged.dart';
import '../entities/admin_user.dart';
import '../entities/doctor_application.dart';

/// Documented admin operations. All require an admin session; the backend
/// enforces it. Methods throw `Failure` on error.
abstract interface class AdminRepository {
  Future<List<DoctorApplication>> listDoctorApplications();
  Future<void> approveDoctor(String userId);
  Future<void> rejectDoctor(String userId, {required String reason});

  Future<Paged<AdminUser>> listUsers({String? search, int offset = 0});

  /// `PATCH /admin/users/{id}/status`; returns the updated account.
  Future<AdminUser> setUserStatus(
    String userId,
    UserStatusChange status, {
    String? reason,
  });
}
