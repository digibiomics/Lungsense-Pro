import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lungsense_pro/core/storage/token_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('saves under Pro-namespaced keys and reads back', () async {
    final s = SecureTokenStorage();
    await s.saveTokens(
      accessToken: 'a',
      refreshToken: 'r',
      accessTokenExpiresAt: DateTime.utc(2026, 1, 1),
    );
    const raw = FlutterSecureStorage();
    final all = await raw.readAll();
    expect(all.keys, everyElement(startsWith('lungsense_pro.auth.')));
    expect(all[SecureTokenStorage.refreshKey], 'r');
    expect(await s.readAccessToken(), 'a');
    expect(await s.readRefreshToken(), 'r');
  });

  test('a fresh instance loads the persisted access token', () async {
    await SecureTokenStorage().saveTokens(accessToken: 'a', refreshToken: 'r');
    expect(await SecureTokenStorage().readAccessToken(), 'a');
  });

  test('clear removes everything', () async {
    final s = SecureTokenStorage();
    await s.saveTokens(accessToken: 'a', refreshToken: 'r');
    await s.clear();
    expect(await s.readAccessToken(), isNull);
    expect(await s.readRefreshToken(), isNull);
    expect(await const FlutterSecureStorage().readAll(), isEmpty);
  });

  test('does not touch keys outside its namespace (e.g. Wellness)', () async {
    FlutterSecureStorage.setMockInitialValues({'wellness.refresh_token': 'w'});
    final s = SecureTokenStorage();
    await s.saveTokens(accessToken: 'a', refreshToken: 'r');
    await s.clear();
    expect(await const FlutterSecureStorage().readAll(), {
      'wellness.refresh_token': 'w',
    });
  });
}
