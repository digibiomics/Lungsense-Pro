/// Client-side checks only. The backend remains the authority on rules
/// (password policy, doctor profile requirements).
abstract final class Validators {
  static final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  static final _phone = RegExp(r'^\+?[0-9 ()\-]{6,20}$');

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Enter your email address.';
    if (!_email.hasMatch(v)) return 'Enter a valid email address.';
    return null;
  }

  static String? requiredPassword(String? value) =>
      (value == null || value.isEmpty) ? 'Enter your password.' : null;

  static String? newPassword(String? value) =>
      (value == null || value.isEmpty) ? 'Choose a password.' : null;

  static FormFieldValidatorFn required(String message) =>
      (String? v) => (v == null || v.trim().isEmpty) ? message : null;

  static String? phone(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Enter a phone number.';
    if (!_phone.hasMatch(v)) return 'Enter a valid phone number.';
    return null;
  }

  static String? otp(String? value) {
    final v = value?.trim() ?? '';
    if (!RegExp(r'^\d{6}$').hasMatch(v)) return 'Enter the 6-digit code.';
    return null;
  }
}

typedef FormFieldValidatorFn = String? Function(String? value);
