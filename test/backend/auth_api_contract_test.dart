@Tags(['backend'])
library;

// LIVE backend contract tests. They call the real API at API_BASE_URL and
// are skipped by default. Run, against a test environment only:
//
//   flutter test --tags backend --run-skipped \
//     --dart-define=LS_BACKEND_TESTS=true \
//     --dart-define=API_BASE_URL=http://3.108.54.191 \
//     --dart-define=LS_TEST_PATIENT_EMAIL=... \
//     --dart-define=LS_TEST_PATIENT_PASSWORD=...
//
// Never point these at production or commit real credentials.
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lungsense_pro/core/errors/failure.dart';
import 'package:lungsense_pro/core/network/api_client.dart';
import 'package:lungsense_pro/core/network/api_endpoints.dart';
import 'package:lungsense_pro/core/network/error_mapper.dart';
import 'package:lungsense_pro/features/authentication/data/datasources/auth_remote_data_source.dart';
import 'package:lungsense_pro/features/authentication/domain/entities/app_user.dart';

const _enabled = bool.fromEnvironment('LS_BACKEND_TESTS');
const _email = String.fromEnvironment('LS_TEST_PATIENT_EMAIL');
const _password = String.fromEnvironment('LS_TEST_PATIENT_PASSWORD');

void main() {
  final dio = createDio();
  final remote = AuthRemoteDataSource(dio);
  final skipNoCreds = !_enabled || _email.isEmpty || _password.isEmpty
      ? 'needs LS_BACKEND_TESTS and patient test credentials'
      : null;

  test('invalid login is rejected with 400/401', () async {
    await expectLater(
      remote.login('no-such-user@example.invalid', 'Wrong#Password1'),
      throwsA(
        isA<Failure>().having((f) => f.statusCode, 'status', anyOf(400, 401)),
      ),
    );
  }, skip: _enabled ? null : 'LS_BACKEND_TESTS not set');

  test('invalid refresh token is rejected', () async {
    await expectLater(
      remote.refresh('invalid-refresh-token'),
      throwsA(
        isA<Failure>().having((f) => f.statusCode, 'status', anyOf(400, 401)),
      ),
    );
  }, skip: _enabled ? null : 'LS_BACKEND_TESTS not set');

  test('users/me without a token is 401', () async {
    await expectLater(
      remote.me(),
      throwsA(isA<Failure>().having((f) => f.statusCode, 'status', 401)),
    );
  }, skip: _enabled ? null : 'LS_BACKEND_TESTS not set');

  test('patient: login, users/me, refresh, admin is forbidden', () async {
    final tokens = await remote.login(_email, _password);
    expect(tokens.accessToken, isNotEmpty);
    expect(tokens.refreshToken, isNotEmpty);

    final authed = Options(
      headers: {'Authorization': 'Bearer ${tokens.accessToken}'},
    );
    final me = await dio.get<Object?>(ApiEndpoints.me, options: authed);
    expect(me.statusCode, 200);
    final body = me.data! as Map;
    expect(UserRole.fromApi(body['role'] as String?), UserRole.patient);

    final refreshed = await remote.refresh(tokens.refreshToken);
    expect(refreshed.accessToken, isNotEmpty);

    try {
      await dio.get<Object?>(ApiEndpoints.adminDoctors, options: authed);
      fail('patient must not access admin endpoints');
    } on DioException catch (e) {
      expect(ErrorMapper.fromDio(e).statusCode, anyOf(401, 403));
    }
  }, skip: skipNoCreds);
}
