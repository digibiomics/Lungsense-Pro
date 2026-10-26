import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lungsense_pro/core/network/api_endpoints.dart';
import 'package:lungsense_pro/core/network/auth_interceptor.dart';
import 'package:lungsense_pro/features/authentication/data/datasources/auth_remote_data_source.dart';
import 'package:lungsense_pro/features/authentication/data/repositories/auth_repository_impl.dart';

import '../helpers/fakes.dart';

// MockHttpAdapter simulates the backend; no network is used.
void main() {
  late InMemoryTokenStorage storage;
  late MockHttpAdapter http;
  late Dio dio;

  setUp(() {
    storage = InMemoryTokenStorage()
      ..access = 'expired'
      ..refresh = 'r1';
    http = MockHttpAdapter((_) => const MockReply(500));
    dio = mockDio(http);
    final repo = AuthRepositoryImpl(
      remote: AuthRemoteDataSource(dio),
      storage: storage,
    );
    dio.interceptors.add(
      AuthInterceptor(dio: dio, storage: storage, refresher: repo),
    );
  });

  MockReply backend(RequestOptions o) {
    if (o.path == ApiEndpoints.refresh) {
      return MockReply(200, tokenJson(access: 'valid', refresh: 'r2'));
    }
    final auth = o.headers['Authorization'];
    return auth == 'Bearer valid'
        ? MockReply(200, meJson())
        : const MockReply(401, {'detail': 'Token expired'});
  }

  test('401 triggers one refresh and one retry with the new token', () async {
    http.handler = backend;
    final res = await dio.get<Object?>(ApiEndpoints.me);
    expect(res.statusCode, 200);
    expect(http.count(ApiEndpoints.refresh), 1);
    expect(http.count(ApiEndpoints.me), 2);
    expect(http.requests.last.headers['Authorization'], 'Bearer valid');
    expect(storage.refresh, 'r2');
  });

  test('a second 401 after retry is returned, not looped', () async {
    http.handler = (o) => o.path == ApiEndpoints.refresh
        ? MockReply(200, tokenJson(access: 'still-bad'))
        : const MockReply(401);
    await expectLater(
      dio.get<Object?>(ApiEndpoints.me),
      throwsA(
        isA<DioException>().having(
          (e) => e.response?.statusCode,
          'status',
          401,
        ),
      ),
    );
    expect(http.count(ApiEndpoints.refresh), 1);
    expect(http.count(ApiEndpoints.me), 2);
  });

  test('failed refresh clears the session and returns the 401', () async {
    http.handler = (o) => o.path == ApiEndpoints.refresh
        ? const MockReply(401, {'detail': 'Invalid refresh token'})
        : const MockReply(401);
    await expectLater(
      dio.get<Object?>(ApiEndpoints.me),
      throwsA(isA<DioException>()),
    );
    expect(storage.access, isNull);
    expect(storage.refresh, isNull);
    expect(http.count(ApiEndpoints.me), 1);
  });

  test('concurrent 401s share a single refresh', () async {
    http.handler = (o) {
      final r = backend(o);
      return o.path == ApiEndpoints.refresh
          ? MockReply(r.status, r.body, const Duration(milliseconds: 30))
          : r;
    };
    final results = await Future.wait([
      dio.get<Object?>(ApiEndpoints.me),
      dio.get<Object?>(ApiEndpoints.me),
      dio.get<Object?>(ApiEndpoints.me),
    ]);
    expect(results.every((r) => r.statusCode == 200), isTrue);
    expect(http.count(ApiEndpoints.refresh), 1);
  });

  test('public requests carry no token and never refresh on 401', () async {
    http.handler = (_) => const MockReply(401);
    await expectLater(
      dio.post<Object?>(
        ApiEndpoints.login,
        data: {'email': 'a@b.co', 'password': 'x'},
        options: AuthOptions.public(),
      ),
      throwsA(isA<DioException>()),
    );
    expect(http.requests.single.headers.containsKey('Authorization'), isFalse);
    expect(http.count(ApiEndpoints.refresh), 0);
  });

  test('403 is not treated as an expired token', () async {
    http.handler = (_) => const MockReply(403, {
      'detail': {'code': 'wrong_role', 'message': 'Not allowed'},
    });
    await expectLater(
      dio.get<Object?>(ApiEndpoints.adminDoctors),
      throwsA(isA<DioException>()),
    );
    expect(http.count(ApiEndpoints.refresh), 0);
    expect(storage.refresh, 'r1');
  });
}
