import 'package:equatable/equatable.dart';

enum AccountType {
  patient,
  doctor;

  String get apiValue => name;
}

/// Professional details sent as `doctor_profile`.
class DoctorProfileInput extends Equatable {
  const DoctorProfileInput({
    required this.licenseNumber,
    required this.specialty,
    required this.institution,
    required this.city,
    required this.country,
    required this.phone,
    this.credentialNotes = '',
  });

  final String licenseNumber;
  final String specialty;
  final String institution;
  final String city;
  final String country;
  final String phone;

  /// Only sent with `/auth/register`; the account-type contract omits it.
  final String credentialNotes;

  @override
  List<Object?> get props => [
    licenseNumber,
    specialty,
    institution,
    city,
    country,
    phone,
    credentialNotes,
  ];
}

/// Email sign-up request (`POST /auth/register`).
class RegistrationRequest extends Equatable {
  const RegistrationRequest({
    required this.email,
    required this.password,
    required this.fullName,
    required this.accountType,
    this.doctorProfile,
  }) : assert(
         accountType != AccountType.doctor || doctorProfile != null,
         'doctor registration needs a doctor profile',
       );

  final String email;
  final String password;
  final String fullName;
  final AccountType accountType;
  final DoctorProfileInput? doctorProfile;

  @override
  List<Object?> get props => [email, fullName, accountType, doctorProfile];
}

/// First-time Google user choosing a role (`POST /users/me/account-type`).
class AccountTypeRequest extends Equatable {
  const AccountTypeRequest({
    required this.accountType,
    required this.fullName,
    this.doctorProfile,
  });

  final AccountType accountType;
  final String fullName;
  final DoctorProfileInput? doctorProfile;

  @override
  List<Object?> get props => [accountType, fullName, doctorProfile];
}
