import 'package:equatable/equatable.dart';

import 'app_user.dart';

/// Where a sign-in or session restore ends up. Decided only from the
/// backend's `users/me` response or its 403 `detail.code`, never from a
/// locally stored role.
sealed class SessionOutcome extends Equatable {
  const SessionOutcome();

  /// Applies the access policy to a freshly fetched profile.
  static SessionOutcome fromUser(AppUser user) {
    if (user.accountStatus != AccountStatus.active) {
      return AccountRestricted(user.accountStatus);
    }
    return switch (user.role) {
      UserRole.patient ||
      UserRole.doctor ||
      UserRole.admin => Authenticated(user),
      UserRole.newUser => RoleSelectionRequired(user),
      UserRole.unknown => const AccountRestricted(AccountStatus.unknown),
    };
  }

  @override
  List<Object?> get props => [];
}

class SignedOut extends SessionOutcome {
  const SignedOut();
}

/// Active patient, approved doctor or active admin.
class Authenticated extends SessionOutcome {
  const Authenticated(this.user);
  final AppUser user;

  @override
  List<Object?> get props => [user];
}

/// The account exists but may not use the app. The session has been cleared.
class AccountRestricted extends SessionOutcome {
  const AccountRestricted(this.status, {this.message});
  final AccountStatus status;

  /// Server message (for example the admin's rejection reason), if any.
  final String? message;

  @override
  List<Object?> get props => [status, message];
}

/// First-time Google user whose role is `new`.
class RoleSelectionRequired extends SessionOutcome {
  const RoleSelectionRequired(this.user);
  final AppUser user;

  @override
  List<Object?> get props => [user];
}
