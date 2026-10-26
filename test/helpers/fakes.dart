// TEST DOUBLES ONLY. Nothing here is used by the production code path.
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:lungsense_pro/core/storage/token_storage.dart';
import 'package:lungsense_pro/features/authentication/domain/entities/app_user.dart';

/// In-memory [TokenStorage] for tests.
class InMemoryTokenStorage implements TokenStorage {
  String? access;
  String? refresh;
  DateTime? expiresAt;
  int clearCount = 0;

  @override
  Future<String?> readAccessToken() async => access;

  @override
  Future<String?> readRefreshToken() async => refresh;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    DateTime? accessTokenExpiresAt,
  }) async {
    access = accessToken;
    refresh = refreshToken;
    expiresAt = accessTokenExpiresAt;
  }

  @override
  Future<void> clear() async {
    access = null;
    refresh = null;
    expiresAt = null;
    clearCount++;
  }
}

/// A canned HTTP reply produced by [MockHttpAdapter].
class MockReply {
  const MockReply(this.status, [this.body, this.delay = Duration.zero]);
  final int status;
  final Object? body;
  final Duration delay;
}

typedef MockHandler = FutureOr<MockReply> Function(RequestOptions options);

/// MOCK Dio adapter: answers every request from [handler] and records the
/// requests so tests can assert on paths, headers and bodies. It never
/// touches the network.
class MockHttpAdapter implements HttpClientAdapter {
  MockHttpAdapter(this.handler);
  MockHandler handler;
  final List<RequestOptions> requests = [];

  int count(String path) => requests.where((r) => r.path == path).length;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final reply = await handler(options);
    if (reply.delay > Duration.zero) await Future<void>.delayed(reply.delay);
    return ResponseBody.fromString(
      reply.body == null ? '' : jsonEncode(reply.body),
      reply.status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Dio mockDio(MockHttpAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'http://mock.local'))
    ..httpClientAdapter = adapter;
  return dio;
}

Map<String, dynamic> tokenJson({
  String access = 'access-1',
  String refresh = 'refresh-1',
}) => {
  'access_token': access,
  'refresh_token': refresh,
  'token_type': 'bearer',
  'expires_in': 3600,
  'user_id': 'u-1',
  'email': 'dr.rao@example.com',
};

Map<String, dynamic> meJson({
  String role = 'doctor',
  String status = 'active',
}) => {
  'id': 'u-1',
  'email': 'dr.rao@example.com',
  'full_name': 'Dr. A. Rao',
  'role': role,
  'account_status': status,
  'doctor_profile': {'license_number': 'KMC-12345', 'specialty': 'Pulmonology'},
  'patient_profile_id': null,
  'patient_study_id': null,
};

const testUser = AppUser(
  id: 'u-1',
  email: 'dr.rao@example.com',
  fullName: 'Dr. A. Rao',
  role: UserRole.doctor,
  accountStatus: AccountStatus.active,
);

AppUser userWith({
  UserRole role = UserRole.doctor,
  AccountStatus status = AccountStatus.active,
}) => AppUser(
  id: 'u-1',
  email: 'dr.rao@example.com',
  fullName: 'Dr. A. Rao',
  role: role,
  accountStatus: status,
);
