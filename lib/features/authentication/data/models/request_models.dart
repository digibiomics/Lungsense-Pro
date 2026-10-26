import '../../domain/entities/registration.dart';

/// JSON bodies exactly as documented. No extra fields are added.
abstract final class RequestModels {
  static Map<String, dynamic> doctorProfile(
    DoctorProfileInput p, {
    required bool includeCredentialNotes,
  }) => {
    'license_number': p.licenseNumber.trim(),
    'specialty': p.specialty.trim(),
    'institution': p.institution.trim(),
    'city': p.city.trim(),
    'country': p.country.trim(),
    'phone': p.phone.trim(),
    if (includeCredentialNotes) 'credential_notes': p.credentialNotes.trim(),
  };

  /// `POST /api/v1/auth/register`.
  static Map<String, dynamic> register(RegistrationRequest r) => {
    'email': r.email,
    'password': r.password,
    'full_name': r.fullName,
    'account_type': r.accountType.apiValue,
    if (r.accountType == AccountType.doctor)
      'doctor_profile': doctorProfile(
        r.doctorProfile!,
        includeCredentialNotes: true,
      ),
  };

  /// `POST /api/v1/users/me/account-type` (documented without
  /// `credential_notes`).
  static Map<String, dynamic> accountType(AccountTypeRequest r) => {
    'account_type': r.accountType.apiValue,
    'full_name': r.fullName.trim(),
    if (r.accountType == AccountType.doctor)
      'doctor_profile': doctorProfile(
        r.doctorProfile!,
        includeCredentialNotes: false,
      ),
  };

  /// `POST /api/v1/auth/reset-password`. The confirm-password field is
  /// client-side only and never sent.
  static Map<String, dynamic> resetPassword({
    required String email,
    required String otpCode,
    required String newPassword,
  }) => {'email': email, 'otp_code': otpCode, 'new_password': newPassword};
}
