import 'package:equatable/equatable.dart';

import '../../../authentication/domain/entities/app_user.dart';

/// One account from `GET /api/v1/admin/users` (`AdminUserOut`).
class AdminUser extends Equatable {
  const AdminUser({
    required this.id,
    required this.email,
    required this.role,
    required this.status,
    this.fullName,
    this.createdAt,
  });

  final String id;
  final String email;
  final String? fullName;
  final UserRole role;
  final AccountStatus status;
  final DateTime? createdAt;

  String get displayName =>
      (fullName != null && fullName!.trim().isNotEmpty) ? fullName! : email;

  /// Accounts an admin can suspend from the Users tab. Doctor applications
  /// (pending/rejected) use approve/reject instead.
  bool get canSuspend => status == AccountStatus.active;

  /// Suspended and deactivated accounts can be made active again.
  bool get canReactivate =>
      status == AccountStatus.suspended || status == AccountStatus.deactivated;

  @override
  List<Object?> get props => [id, email, fullName, role, status, createdAt];
}

/// Allowed `StatusUpdate.account_status` values.
enum UserStatusChange {
  active('active'),
  suspended('suspended'),
  deactivated('deactivated');

  const UserStatusChange(this.api);
  final String api;
}
