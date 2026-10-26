import 'package:flutter_test/flutter_test.dart';
import 'package:lungsense_pro/features/authentication/domain/entities/app_user.dart';
import 'package:lungsense_pro/features/authentication/domain/entities/session_outcome.dart';

import '../helpers/fakes.dart';

void main() {
  group('role and status mapping', () {
    test('roles', () {
      expect(UserRole.fromApi('patient'), UserRole.patient);
      expect(UserRole.fromApi('DOCTOR'), UserRole.doctor);
      expect(UserRole.fromApi('admin'), UserRole.admin);
      expect(UserRole.fromApi('new'), UserRole.newUser);
      expect(UserRole.fromApi(null), UserRole.unknown);
    });

    test('statuses', () {
      expect(AccountStatus.fromApi('active'), AccountStatus.active);
      expect(
        AccountStatus.fromApi('pending_approval'),
        AccountStatus.pendingApproval,
      );
      expect(AccountStatus.fromApi('rejected'), AccountStatus.rejected);
      expect(AccountStatus.fromApi('suspended'), AccountStatus.suspended);
      expect(AccountStatus.fromApi('deactivated'), AccountStatus.deactivated);
      expect(AccountStatus.fromApi(''), AccountStatus.unknown);
    });

    test('403 detail codes', () {
      expect(
        AccountStatus.fromErrorCode('account_pending_approval'),
        AccountStatus.pendingApproval,
      );
      expect(
        AccountStatus.fromErrorCode('account_rejected'),
        AccountStatus.rejected,
      );
      expect(
        AccountStatus.fromErrorCode('account_suspended'),
        AccountStatus.suspended,
      );
      expect(
        AccountStatus.fromErrorCode('account_deactivated'),
        AccountStatus.deactivated,
      );
      expect(AccountStatus.fromErrorCode('wrong_role'), isNull);
      expect(AccountStatus.fromErrorCode(null), isNull);
    });
  });

  group('SessionOutcome.fromUser', () {
    test('active roles are authenticated', () {
      for (final r in [UserRole.patient, UserRole.doctor, UserRole.admin]) {
        expect(
          SessionOutcome.fromUser(userWith(role: r)),
          isA<Authenticated>(),
        );
      }
    });

    test('non-active statuses are restricted', () {
      for (final s in [
        AccountStatus.pendingApproval,
        AccountStatus.rejected,
        AccountStatus.suspended,
        AccountStatus.deactivated,
        AccountStatus.unknown,
      ]) {
        expect(
          SessionOutcome.fromUser(userWith(status: s)),
          AccountRestricted(s),
        );
      }
    });

    test('new role requires account-type selection', () {
      expect(
        SessionOutcome.fromUser(userWith(role: UserRole.newUser)),
        isA<RoleSelectionRequired>(),
      );
    });

    test('unknown role is refused', () {
      expect(
        SessionOutcome.fromUser(userWith(role: UserRole.unknown)),
        const AccountRestricted(AccountStatus.unknown),
      );
    });
  });
}
