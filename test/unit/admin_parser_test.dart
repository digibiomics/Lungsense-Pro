import 'package:flutter_test/flutter_test.dart';
import 'package:lungsense_pro/core/errors/failure.dart';
import 'package:lungsense_pro/features/admin/data/models/doctor_application_model.dart';
import 'package:lungsense_pro/features/authentication/domain/entities/app_user.dart';

// The list response schema is UNCONFIRMED (KI-02); these tests pin the
// tolerant-but-strict behaviour, not the backend's real shape.
void main() {
  final item = {
    'id': 'd-1',
    'email': 'dr@example.com',
    'full_name': 'Dr. One',
    'account_status': 'pending_approval',
    'created_at': '2026-10-20T10:00:00Z',
    'doctor_profile': {'license_number': 'L-1', 'specialty': 'Chest'},
  };

  test('accepts a bare array', () {
    final list = DoctorApplicationModel.listFromJson([item]);
    expect(list.single.userId, 'd-1');
    expect(list.single.status, AccountStatus.pendingApproval);
    expect(list.single.doctorProfile?.licenseNumber, 'L-1');
    expect(list.single.submittedAt, DateTime.utc(2026, 10, 20, 10));
  });

  test('accepts a wrapped array and user_id', () {
    for (final key in ['items', 'doctors', 'results', 'data']) {
      final list = DoctorApplicationModel.listFromJson({
        key: [
          {'user_id': 'd-2', 'email': 'x@example.com'},
        ],
      });
      expect(list.single.userId, 'd-2');
    }
  });

  test('unknown shapes fail loudly instead of looking empty', () {
    Matcher fails = throwsA(isA<Failure>());
    expect(() => DoctorApplicationModel.listFromJson({'x': []}), fails);
    expect(() => DoctorApplicationModel.listFromJson('nope'), fails);
    expect(
      () => DoctorApplicationModel.listFromJson([
        {'email': 'no-id@example.com'},
      ]),
      fails,
    );
  });
}
