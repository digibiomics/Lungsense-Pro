import 'package:flutter_test/flutter_test.dart';
import 'package:lungsense_pro/features/authentication/data/models/request_models.dart';
import 'package:lungsense_pro/features/authentication/domain/entities/registration.dart';

const _profile = DoctorProfileInput(
  licenseNumber: ' KMC-1 ',
  specialty: 'Pulmonology',
  institution: 'City Hospital',
  city: 'Srinagar',
  country: 'India',
  phone: '+91 1',
  credentialNotes: 'MD',
);

void main() {
  test('patient register body has exactly the documented fields', () {
    final body = RequestModels.register(
      const RegistrationRequest(
        email: 'a@example.com',
        password: 'P#1',
        fullName: 'Asha',
        accountType: AccountType.patient,
      ),
    );
    expect(body, {
      'email': 'a@example.com',
      'password': 'P#1',
      'full_name': 'Asha',
      'account_type': 'patient',
    });
  });

  test('doctor register includes credential_notes and trims fields', () {
    final body = RequestModels.register(
      const RegistrationRequest(
        email: 'd@example.com',
        password: 'P#1',
        fullName: 'Dr. D',
        accountType: AccountType.doctor,
        doctorProfile: _profile,
      ),
    );
    final dp = body['doctor_profile'] as Map;
    expect(dp['license_number'], 'KMC-1');
    expect(dp['credential_notes'], 'MD');
    expect(dp.keys, hasLength(7));
  });

  test('account-type body omits credential_notes (not in its contract)', () {
    final body = RequestModels.accountType(
      const AccountTypeRequest(
        accountType: AccountType.doctor,
        fullName: ' Dr. D ',
        doctorProfile: _profile,
      ),
    );
    expect(body['account_type'], 'doctor');
    expect(body['full_name'], 'Dr. D');
    expect(
      (body['doctor_profile'] as Map).containsKey('credential_notes'),
      isFalse,
    );
    expect(
      RequestModels.accountType(
        const AccountTypeRequest(
          accountType: AccountType.patient,
          fullName: 'P',
        ),
      ),
      {'account_type': 'patient', 'full_name': 'P'},
    );
  });

  test('reset body never carries a confirm-password field', () {
    expect(
      RequestModels.resetPassword(
        email: 'a@example.com',
        otpCode: '123456',
        newPassword: 'N#1',
      ),
      {'email': 'a@example.com', 'otp_code': '123456', 'new_password': 'N#1'},
    );
  });
}
