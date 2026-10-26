import 'package:equatable/equatable.dart';

import '../../../authentication/domain/entities/app_user.dart';

/// One entry from `GET /api/v1/admin/doctors`. Only fields the documented
/// user profile already defines are read; the exact schema is unconfirmed.
class DoctorApplication extends Equatable {
  const DoctorApplication({
    required this.userId,
    required this.email,
    required this.status,
    this.fullName,
    this.doctorProfile,
    this.submittedAt,
    this.rejectionReason,
  });

  final String userId;
  final String email;
  final String? fullName;
  final AccountStatus status;
  final DoctorProfile? doctorProfile;
  final DateTime? submittedAt;
  final String? rejectionReason;

  String get displayName =>
      (fullName != null && fullName!.trim().isNotEmpty) ? fullName! : email;

  DoctorApplication withStatus(AccountStatus s, {String? reason}) =>
      DoctorApplication(
        userId: userId,
        email: email,
        fullName: fullName,
        status: s,
        doctorProfile: doctorProfile,
        submittedAt: submittedAt,
        rejectionReason: reason ?? rejectionReason,
      );

  @override
  List<Object?> get props => [
    userId,
    email,
    fullName,
    status,
    doctorProfile,
    submittedAt,
    rejectionReason,
  ];
}
