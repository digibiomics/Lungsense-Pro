import '../../../../core/errors/failure.dart';
import '../../domain/entities/app_user.dart';

const _malformed = Failure(
  kind: FailureKind.unknown,
  message: 'Unexpected response from the server.',
);

Map<String, dynamic> _asMap(Object? json) {
  if (json is Map<String, dynamic>) return json;
  if (json is Map) return json.cast<String, dynamic>();
  throw _malformed;
}

String? _str(Object? v) => switch (v) {
  null => null,
  final String s => s,
  final num n => n.toString(),
  _ => null,
};

/// Token response of `/auth/login`, `/auth/refresh` and `/auth/google/token`.
class TokenResponseModel {
  const TokenResponseModel({
    required this.accessToken,
    required this.refreshToken,
    this.tokenType,
    this.expiresIn,
    this.userId,
    this.email,
  });

  factory TokenResponseModel.fromJson(Object? json) {
    final map = _asMap(json);
    final access = _str(map['access_token']);
    final refresh = _str(map['refresh_token']);
    if (access == null ||
        access.isEmpty ||
        refresh == null ||
        refresh.isEmpty) {
      throw _malformed;
    }
    final expires = map['expires_in'];
    return TokenResponseModel(
      accessToken: access,
      refreshToken: refresh,
      tokenType: _str(map['token_type']),
      expiresIn: expires is num ? expires.toInt() : null,
      userId: _str(map['user_id']),
      email: _str(map['email']),
    );
  }

  final String accessToken;
  final String refreshToken;
  final String? tokenType;

  /// Seconds; documented as 3600.
  final int? expiresIn;
  final String? userId;
  final String? email;

  DateTime? expiresAt(DateTime now) =>
      expiresIn == null ? null : now.add(Duration(seconds: expiresIn!));
}

/// `GET /api/v1/users/me`. Only the documented fields are read; anything
/// else in the payload is ignored.
abstract final class UserModel {
  static AppUser fromJson(Object? json) {
    final map = _asMap(json);
    final id = _str(map['id']);
    final email = _str(map['email']);
    if (id == null || email == null) throw _malformed;

    final dp = map['doctor_profile'];
    return AppUser(
      id: id,
      email: email,
      fullName: _str(map['full_name']),
      role: UserRole.fromApi(_str(map['role'])),
      accountStatus: AccountStatus.fromApi(_str(map['account_status'])),
      doctorProfile: dp is Map
          ? _doctorProfile(dp.cast<String, dynamic>())
          : null,
      patientProfileId: _str(map['patient_profile_id']),
      patientStudyId: _str(map['patient_study_id']),
    );
  }

  static DoctorProfile _doctorProfile(Map<String, dynamic> m) => DoctorProfile(
    licenseNumber: _str(m['license_number']),
    specialty: _str(m['specialty']),
    institution: _str(m['institution']),
    city: _str(m['city']),
    country: _str(m['country']),
    phone: _str(m['phone']),
    credentialNotes: _str(m['credential_notes']),
  );
}
