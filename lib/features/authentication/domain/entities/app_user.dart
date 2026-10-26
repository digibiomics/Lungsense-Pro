import 'package:equatable/equatable.dart';

enum UserRole {
  patient,
  doctor,
  admin,

  /// First-time Google user who has not chosen an account type yet.
  newUser,

  /// Any value the app does not recognise. Never grants access.
  unknown;

  static UserRole fromApi(String? value) => switch (value?.toLowerCase()) {
    'patient' => UserRole.patient,
    'doctor' => UserRole.doctor,
    'admin' => UserRole.admin,
    'new' => UserRole.newUser,
    _ => UserRole.unknown,
  };
}

enum AccountStatus {
  active,
  pendingApproval,
  rejected,
  suspended,
  deactivated,

  /// Any value the app does not recognise. Never grants access.
  unknown;

  static AccountStatus fromApi(String? value) => switch (value?.toLowerCase()) {
    'active' => AccountStatus.active,
    'pending_approval' => AccountStatus.pendingApproval,
    'rejected' => AccountStatus.rejected,
    'suspended' => AccountStatus.suspended,
    'deactivated' => AccountStatus.deactivated,
    _ => AccountStatus.unknown,
  };

  /// Maps a 403 `detail.code` to a status, or null for other codes
  /// (for example `wrong_role`).
  static AccountStatus? fromErrorCode(String? code) => switch (code) {
    'account_pending_approval' => AccountStatus.pendingApproval,
    'account_rejected' => AccountStatus.rejected,
    'account_suspended' => AccountStatus.suspended,
    'account_deactivated' => AccountStatus.deactivated,
    _ => null,
  };
}

class DoctorProfile extends Equatable {
  const DoctorProfile({
    this.licenseNumber,
    this.specialty,
    this.institution,
    this.city,
    this.country,
    this.phone,
    this.credentialNotes,
  });

  final String? licenseNumber;
  final String? specialty;
  final String? institution;
  final String? city;
  final String? country;
  final String? phone;
  final String? credentialNotes;

  @override
  List<Object?> get props => [
    licenseNumber,
    specialty,
    institution,
    city,
    country,
    phone,
    credentialNotes,
  ];
}

/// The authenticated user as reported by `GET /api/v1/users/me`.
class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.email,
    required this.role,
    required this.accountStatus,
    this.fullName,
    this.doctorProfile,
    this.patientProfileId,
    this.patientStudyId,
  });

  final String id;
  final String email;
  final String? fullName;
  final UserRole role;
  final AccountStatus accountStatus;
  final DoctorProfile? doctorProfile;
  final String? patientProfileId;
  final String? patientStudyId;

  String get displayName =>
      (fullName != null && fullName!.trim().isNotEmpty) ? fullName! : email;

  @override
  List<Object?> get props => [
    id,
    email,
    fullName,
    role,
    accountStatus,
    doctorProfile,
    patientProfileId,
    patientStudyId,
  ];
}
