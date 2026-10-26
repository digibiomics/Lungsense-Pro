import '../entities/doctor_application.dart';

/// Documented admin operations. All require an admin session; the backend
/// enforces it. Methods throw `Failure` on error.
///
/// `PATCH /api/v1/admin/users/{user_id}/status` is intentionally absent:
/// its request body is not documented (docs/KNOWN_ISSUES.md KI-02).
abstract interface class AdminRepository {
  Future<List<DoctorApplication>> listDoctorApplications();
  Future<void> approveDoctor(String userId);
  Future<void> rejectDoctor(String userId, {required String reason});
}
