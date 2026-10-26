import 'package:flutter_test/flutter_test.dart';
import 'package:lungsense_pro/core/errors/failure.dart';
import 'package:lungsense_pro/core/network/api_endpoints.dart';
import 'package:lungsense_pro/core/network/auth_interceptor.dart';
import 'package:lungsense_pro/features/authentication/data/datasources/auth_remote_data_source.dart';
import 'package:lungsense_pro/features/authentication/data/repositories/auth_repository_impl.dart';
import 'package:lungsense_pro/features/authentication/domain/entities/app_user.dart';

import '../helpers/fakes.dart';

// Uses MockHttpAdapter (no network). Verifies the requests the repository
// sends and how it stores/clears tokens.
void main() {
  late InMemoryTokenStorage storage;
  late MockHttpAdapter http;
  late AuthRepositoryImpl repo;

  setUp(() {
    storage = InMemoryTokenStorage();
    http = MockHttpAdapter((_) => const MockReply(500));
    final dio = mockDio(http);
    repo = AuthRepositoryImpl(
      remote: AuthRemoteDataSource(dio),
      storage: storage,
      clock: () => DateTime.utc(2026, 10, 26),
    );
    dio.interceptors.add(
      AuthInterceptor(dio: dio, storage: storage, refresher: repo),
    );
  });

  group('signIn', () {
    test('posts documented body, stores tokens, loads profile', () async {
      http.handler = (o) => switch (o.path) {
        ApiEndpoints.login => MockReply(200, tokenJson()),
        ApiEndpoints.me => MockReply(200, meJson()),
        _ => const MockReply(404),
      };

      final user = await repo.signIn(
        email: 'dr.rao@example.com',
        password: 'Example#123',
      );

      expect(user.role, UserRole.doctor);
      final login = http.requests.first;
      expect(login.method, 'POST');
      expect(login.data, {
        'email': 'dr.rao@example.com',
        'password': 'Example#123',
      });
      expect(login.headers.containsKey('Authorization'), isFalse);
      final me = http.requests.last;
      expect(me.headers['Authorization'], 'Bearer access-1');
      expect(storage.access, 'access-1');
      expect(storage.refresh, 'refresh-1');
      expect(storage.expiresAt, DateTime.utc(2026, 10, 26, 1));
    });

    test('400 propagates and stores nothing', () async {
      http.handler = (_) =>
          const MockReply(400, {'detail': 'Invalid login credentials'});
      await expectLater(
        repo.signIn(email: 'a@b.co', password: 'x'),
        throwsA(
          isA<Failure>()
              .having((f) => f.kind, 'kind', FailureKind.badRequest)
              .having((f) => f.message, 'message', 'Invalid login credentials'),
        ),
      );
      expect(storage.refresh, isNull);
    });

    test('clears tokens when the profile request fails', () async {
      http.handler = (o) => o.path == ApiEndpoints.login
          ? MockReply(200, tokenJson())
          : const MockReply(500);
      await expectLater(
        repo.signIn(email: 'a@b.co', password: 'x'),
        throwsA(isA<Failure>()),
      );
      expect(storage.access, isNull);
      expect(storage.refresh, isNull);
    });
  });

  group('refreshAccessToken', () {
    test('sends refresh_token and saves the returned values', () async {
      storage.refresh = 'old-refresh';
      http.handler = (_) =>
          MockReply(200, tokenJson(access: 'new-a', refresh: 'new-r'));
      expect(await repo.refreshAccessToken(), 'new-a');
      expect(http.requests.single.path, ApiEndpoints.refresh);
      expect(http.requests.single.data, {'refresh_token': 'old-refresh'});
      expect(storage.refresh, 'new-r');
    });

    test('concurrent callers share one refresh request', () async {
      storage.refresh = 'r';
      http.handler = (_) => MockReply(
        200,
        tokenJson(access: 'a2'),
        const Duration(milliseconds: 30),
      );
      final results = await Future.wait([
        repo.refreshAccessToken(),
        repo.refreshAccessToken(),
        repo.refreshAccessToken(),
      ]);
      expect(results, ['a2', 'a2', 'a2']);
      expect(http.count(ApiEndpoints.refresh), 1);
    });

    test('rejected refresh clears the session and emits expiry', () async {
      storage
        ..access = 'a'
        ..refresh = 'r';
      http.handler = (_) => const MockReply(401, {'detail': 'Invalid token'});
      final expired = expectLater(repo.sessionExpired, emits(null));
      await expectLater(repo.refreshAccessToken(), throwsA(isA<Failure>()));
      await expired;
      expect(storage.refresh, isNull);
    });

    test('network failure keeps the session', () async {
      storage.refresh = 'r';
      http.handler = (_) => const MockReply(503);
      await expectLater(repo.refreshAccessToken(), throwsA(isA<Failure>()));
      expect(storage.refresh, 'r');
      expect(storage.clearCount, 0);
    });
  });

  group('restoreSession', () {
    test('returns null without a refresh token and makes no request', () async {
      expect(await repo.restoreSession(), isNull);
      expect(http.requests, isEmpty);
    });

    test('refreshes then fetches the profile', () async {
      storage.refresh = 'r';
      http.handler = (o) => switch (o.path) {
        ApiEndpoints.refresh => MockReply(200, tokenJson(access: 'fresh')),
        ApiEndpoints.me => MockReply(200, meJson(role: 'patient')),
        _ => const MockReply(404),
      };
      final user = await repo.restoreSession();
      expect(user?.role, UserRole.patient);
      expect(http.requests.last.headers['Authorization'], 'Bearer fresh');
    });
  });

  test('signOut clears tokens', () async {
    storage
      ..access = 'a'
      ..refresh = 'r';
    await repo.signOut();
    expect(storage.access, isNull);
    expect(storage.refresh, isNull);
  });

  test('resendConfirmation posts the email without auth', () async {
    storage.access = 'a';
    http.handler = (_) => const MockReply(202);
    await repo.resendConfirmation('dr.rao@example.com');
    final r = http.requests.single;
    expect(r.path, ApiEndpoints.resendConfirmation);
    expect(r.data, {'email': 'dr.rao@example.com'});
    expect(r.headers.containsKey('Authorization'), isFalse);
  });
}
