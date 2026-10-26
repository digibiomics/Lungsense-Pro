import '../../../../core/errors/failure.dart';
import '../entities/app_user.dart';
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

Future<SessionOutcome> _settle(AuthRepository repo, AppUser user) async {
  final outcome = SessionOutcome.fromUser(user);
  if (outcome is AccountRestricted) await repo.signOut();
  return outcome;
}
