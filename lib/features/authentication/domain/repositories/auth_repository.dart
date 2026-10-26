import '../entities/app_user.dart';

/// Authentication and session operations. Every method throws a
/// `Failure` (core/errors) on error.
abstract interface class AuthRepository {
  /// `POST /auth/login`, stores the tokens, then `GET /users/me`.
  /// Tokens are cleared again if the profile cannot be loaded.
  Future<AppUser> signIn({required String email, required String password});

  /// Restores the stored session: refresh, then `GET /users/me`.
  /// Returns null when no refresh token is stored.
  Future<AppUser?> restoreSession();

  /// `GET /users/me` with the current session.
  Future<AppUser> getCurrentUser();

  /// Clears the local Pro session. The backend documents no logout endpoint.
  Future<void> signOut();

  /// `POST /auth/resend-confirmation`. 202 means accepted, not delivered.
  Future<void> resendConfirmation(String email);

  /// Emits whenever the session is cleared because a refresh was rejected.
  Stream<void> get sessionExpired;
}
