import '../../../../core/errors/failure.dart';
import '../../../authentication/domain/entities/app_user.dart';
import '../../domain/entities/doctor_application.dart';

/// Parser for `GET /api/v1/admin/doctors`.
///
/// UNCONFIRMED CONTRACT (KI-02). Accepted shapes:
/// * a JSON array of items, or
/// * an object holding the array under `items`, `doctors`, `results` or `data`.
/// Each item is read with the documented `users/me` field names (`id` or
/// `user_id`, `email`, `full_name`, `account_status`, `doctor_profile`) plus
/// optional `created_at` and `rejection_reason`. Anything else fails loudly
/// instead of being guessed.
abstract final class DoctorApplicationModel {
  static const _listKeys = ['items', 'doctors', 'results', 'data'];

  static List<DoctorApplication> listFromJson(Object? json) {
    final List<Object?> raw;
    if (json is List) {
      raw = json;
    } else if (json is Map) {
      final key = _listKeys.firstWhere(
        (k) => json[k] is List,
        orElse: () => '',
      );
      if (key.isEmpty) throw _unexpected;
      raw = json[key] as List;
    } else {
      throw _unexpected;
    }
    return raw.map(fromJson).toList();
  }

  static DoctorApplication fromJson(Object? item) {
    if (item is! Map) throw _unexpected;
    final m = item.cast<String, dynamic>();
    final id = _str(m['user_id']) ?? _str(m['id']);
    final email = _str(m['email']);
    if (id == null || email == null) throw _unexpected;
    final dp = m['doctor_profile'];
    final profile = dp is Map ? dp.cast<String, dynamic>() : null;
    return DoctorApplication(
      userId: id,
      email: email,
      fullName: _str(m['full_name']),
      status: AccountStatus.fromApi(_str(m['account_status'])),
      doctorProfile: profile == null
          ? null
          : DoctorProfile(
              licenseNumber: _str(profile['license_number']),
              specialty: _str(profile['specialty']),
              institution: _str(profile['institution']),
              city: _str(profile['city']),
              country: _str(profile['country']),
              phone: _str(profile['phone']),
              credentialNotes: _str(profile['credential_notes']),
            ),
      submittedAt: DateTime.tryParse(_str(m['created_at']) ?? ''),
      rejectionReason: _str(m['rejection_reason']),
    );
  }

  static String? _str(Object? v) => switch (v) {
    final String s => s,
    final num n => n.toString(),
    _ => null,
  };

  static const _unexpected = Failure(
    kind: FailureKind.unknown,
    message: 'The doctor list came back in an unexpected format.',
  );
}
