import 'package:flutter_test/flutter_test.dart';
import 'package:lungsense_pro/core/errors/failure.dart';
import 'package:lungsense_pro/features/authentication/data/models/auth_models.dart';
import 'package:lungsense_pro/features/authentication/domain/entities/app_user.dart';

import '../helpers/fakes.dart';

void main() {
  group('TokenResponseModel', () {
    test('parses the documented login response', () {
      final t = TokenResponseModel.fromJson(tokenJson());
      expect(t.accessToken, 'access-1');
      expect(t.refreshToken, 'refresh-1');
      expect(t.tokenType, 'bearer');
      expect(t.expiresIn, 3600);
      expect(t.userId, 'u-1');
      expect(t.email, 'dr.rao@example.com');
      final now = DateTime.utc(2026, 1, 1);
      expect(t.expiresAt(now), now.add(const Duration(hours: 1)));
    });

    test('missing tokens throw a Failure', () {
      expect(
        () => TokenResponseModel.fromJson({'access_token': 'a'}),
        throwsA(isA<Failure>()),
      );
      expect(
        () => TokenResponseModel.fromJson('not json'),
        throwsA(isA<Failure>()),
      );
    });

    test('numeric user_id is accepted', () {
      final t = TokenResponseModel.fromJson({...tokenJson(), 'user_id': 42});
      expect(t.userId, '42');
    });
  });

  group('UserModel', () {
    test('parses documented users/me fields', () {
      final u = UserModel.fromJson(meJson());
      expect(u.id, 'u-1');
      expect(u.role, UserRole.doctor);
      expect(u.accountStatus, AccountStatus.active);
      expect(u.fullName, 'Dr. A. Rao');
      expect(u.doctorProfile?.licenseNumber, 'KMC-12345');
      expect(u.patientProfileId, isNull);
    });

    test('unknown role and status never become privileged', () {
      final u = UserModel.fromJson(meJson(role: 'superuser', status: 'weird'));
      expect(u.role, UserRole.unknown);
      expect(u.accountStatus, AccountStatus.unknown);
    });

    test('missing id throws', () {
      expect(
        () => UserModel.fromJson({'email': 'a@b.c'}),
        throwsA(isA<Failure>()),
      );
    });
  });
}
