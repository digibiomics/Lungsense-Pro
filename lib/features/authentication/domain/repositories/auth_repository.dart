import '../entities/app_user.dart';
import '../entities/registration.dart';

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

  /// `POST /auth/register` (expects 201). Does not sign the user in.
  Future<void> register(RegistrationRequest request);

  /// `POST /auth/forgot-password` (202, same answer for unknown emails).
  Future<void> requestPasswordReset(String email);

  /// `POST /auth/reset-password` with `email`, `otp_code`, `new_password`.
  Future<void> resetPassword({
    required String email,
    required String otpCode,
    required String newPassword,
  });

  /// `POST /users/me/account-type` for a first-time Google user.
  Future<AppUser> setAccountType(AccountTypeRequest request);

  /// Emits whenever the session is cleared because a refresh was rejected.
  Stream<void> get sessionExpired;
}
