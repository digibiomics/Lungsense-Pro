import '../../../../core/errors/failure.dart';
import '../entities/app_user.dart';
import '../entities/registration.dart';
import '../entities/session_outcome.dart';
import '../repositories/auth_repository.dart';

/// Turns a 403 account-status failure into [AccountRestricted]; returns null
/// for every other failure (including `wrong_role`).
AccountRestricted? restrictionFromFailure(Failure f) {
  if (f.kind != FailureKind.forbidden) return null;
  final status = AccountStatus.fromErrorCode(f.code);
  return status == null ? null : AccountRestricted(status, message: f.message);
}

/// Email sign-in followed by profile-based routing. Users who may not enter
/// (pending, rejected, suspended, deactivated) are signed out again, as the
/// backend flow requires.
class SignInWithEmail {
  const SignInWithEmail(this._repo);
  final AuthRepository _repo;

  Future<SessionOutcome> call({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _repo.signIn(email: email.trim(), password: password);
      return await _settle(_repo, user);
    } on Failure catch (f) {
      final restricted = restrictionFromFailure(f);
      if (restricted == null) rethrow;
      await _repo.signOut();
      return restricted;
    }
  }
}

/// Runs on app launch. Network and server failures are rethrown with the
/// stored session kept, so the user can retry; rejected sessions are cleared.
class RestoreSession {
  const RestoreSession(this._repo);
  final AuthRepository _repo;

  Future<SessionOutcome> call() async {
    try {
      final user = await _repo.restoreSession();
      if (user == null) return const SignedOut();
      return await _settle(_repo, user);
    } on Failure catch (f) {
      final restricted = restrictionFromFailure(f);
      if (restricted != null) {
        await _repo.signOut();
        return restricted;
      }
      if (f.kind == FailureKind.badRequest ||
          f.kind == FailureKind.unauthorized ||
          f.kind == FailureKind.validation) {
        await _repo.signOut();
        return const SignedOut();
      }
      rethrow;
    }
  }
}

/// Re-reads `users/me` during a session (pull to refresh) and re-applies the
/// access policy, so a status change made by an admin takes effect.
class RefreshProfile {
  const RefreshProfile(this._repo);
  final AuthRepository _repo;

  Future<SessionOutcome> call() async {
    try {
      final user = await _repo.getCurrentUser();
      return await _settle(_repo, user);
    } on Failure catch (f) {
      final restricted = restrictionFromFailure(f);
      if (restricted == null) rethrow;
      await _repo.signOut();
      return restricted;
    }
  }
}

class SignOut {
  const SignOut(this._repo);
  final AuthRepository _repo;

  Future<void> call() => _repo.signOut();
}

class ResendConfirmation {
  const ResendConfirmation(this._repo);
  final AuthRepository _repo;

  Future<void> call(String email) => _repo.resendConfirmation(email.trim());
}

class RegisterAccount {
  const RegisterAccount(this._repo);
  final AuthRepository _repo;

  Future<void> call(RegistrationRequest r) => _repo.register(
    RegistrationRequest(
      email: r.email.trim(),
      password: r.password,
      fullName: r.fullName.trim(),
      accountType: r.accountType,
      doctorProfile: r.doctorProfile,
    ),
  );
}

class RequestPasswordReset {
  const RequestPasswordReset(this._repo);
  final AuthRepository _repo;

  Future<void> call(String email) => _repo.requestPasswordReset(email.trim());
}

class ResetPassword {
  const ResetPassword(this._repo);
  final AuthRepository _repo;

  Future<void> call({
    required String email,
    required String otpCode,
    required String newPassword,
  }) => _repo.resetPassword(
    email: email.trim(),
    otpCode: otpCode.trim(),
    newPassword: newPassword,
  );
}

/// Assigns patient/doctor to a first-time Google user, then applies the same
/// access policy as sign-in (a new doctor is pending and gets signed out).
class CompleteAccountType {
  const CompleteAccountType(this._repo);
  final AuthRepository _repo;

  Future<SessionOutcome> call(AccountTypeRequest request) async {
    try {
      final user = await _repo.setAccountType(request);
      return await _settle(_repo, user);
    } on Failure catch (f) {
      final restricted = restrictionFromFailure(f);
      if (restricted == null) rethrow;
      await _repo.signOut();
      return restricted;
    }
  }
}

Future<SessionOutcome> _settle(AuthRepository repo, AppUser user) async {
  final outcome = SessionOutcome.fromUser(user);
  if (outcome is AccountRestricted) await repo.signOut();
  return outcome;
}
