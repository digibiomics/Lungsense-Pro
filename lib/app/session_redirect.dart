import '../core/routing/routes.dart';
import '../features/authentication/domain/entities/app_user.dart';
import '../features/authentication/domain/entities/session_outcome.dart';
import '../features/authentication/presentation/cubit/session_cubit.dart';

/// Route guard. Returns the location to redirect to, or null to stay.
///
/// Access is derived only from the backend-validated [SessionState]; typing
/// a protected path or pressing back cannot bypass it. The backend still
/// enforces authorization on every request.
String? sessionRedirect(SessionState state, String location) {
  String? only(String target) => location == target ? null : target;

  return switch (state) {
    SessionChecking() || SessionRestoreFailed() => only(Routes.splash),
    SessionResolved(:final outcome) => switch (outcome) {
      SignedOut() => Routes.public.contains(location) ? null : Routes.welcome,
      AccountRestricted() => only(Routes.accountStatus),
      RoleSelectionRequired() => only(Routes.roleSelection),
      Authenticated(:final user) => _home(user, location),
    },
  };
}

String? _home(AppUser user, String location) {
  final home = homeFor(user.role);
  if (home == null) return Routes.welcome;
  return location == home || location.startsWith('$home/') ? null : home;
}

String? homeFor(UserRole role) => switch (role) {
  UserRole.patient => Routes.patientHome,
  UserRole.doctor => Routes.doctorDashboard,
  UserRole.admin => Routes.adminHome,
  _ => null,
};
