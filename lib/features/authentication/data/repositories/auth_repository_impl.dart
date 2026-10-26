import 'dart:async';

import '../../../../core/errors/failure.dart';
import '../../../../core/network/auth_interceptor.dart';
import '../../../../core/storage/token_storage.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/auth_models.dart';

class AuthRepositoryImpl implements AuthRepository, SessionRefresher {
  AuthRepositoryImpl({
    required this._remote,
    required this._storage,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final AuthRemoteDataSource _remote;
  final TokenStorage _storage;
  final DateTime Function() _clock;

  final _expired = StreamController<void>.broadcast();
  Completer<String>? _inFlight;

  @override
  Stream<void> get sessionExpired => _expired.stream;

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final tokens = await _remote.login(email, password);
    await _save(tokens);
    try {
      return await _remote.me();
    } on Failure {
      await _storage.clear();
      rethrow;
    }
  }

  @override
  Future<AppUser?> restoreSession() async {
    final refreshToken = await _storage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return null;
    await refreshAccessToken();
    return _remote.me();
  }

  @override
  Future<AppUser> getCurrentUser() => _remote.me();

  @override
  Future<void> signOut() => _storage.clear();

  @override
  Future<void> resendConfirmation(String email) =>
      _remote.resendConfirmation(email);

  /// Single-flight refresh shared by app start-up and the 401 interceptor.
  @override
  Future<String> refreshAccessToken() {
    final running = _inFlight;
    if (running != null) return running.future;

    final completer = Completer<String>();
    _inFlight = completer;
    // Callers may not listen if they were cancelled; avoid unhandled errors.
    completer.future.ignore();
    _doRefresh()
        .then(completer.complete, onError: completer.completeError)
        .whenComplete(() => _inFlight = null);
    return completer.future;
  }

  Future<String> _doRefresh() async {
    final refreshToken = await _storage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      await _expire();
      throw const Failure(kind: FailureKind.unauthorized);
    }
    try {
      final tokens = await _remote.refresh(refreshToken);
      await _save(tokens);
      return tokens.accessToken;
    } on Failure catch (f) {
      // Keep the session on connectivity/server problems so the user can
      // retry; clear it when the server rejects the refresh token or the
      // account (400/401/403/404/422).
      if (_rejectsSession(f)) await _expire();
      rethrow;
    }
  }

  static bool _rejectsSession(Failure f) => switch (f.kind) {
    FailureKind.badRequest ||
    FailureKind.unauthorized ||
    FailureKind.forbidden ||
    FailureKind.notFound ||
    FailureKind.validation => true,
    _ => false,
  };

  Future<void> _expire() async {
    await _storage.clear();
    _expired.add(null);
  }

  Future<void> _save(TokenResponseModel t) => _storage.saveTokens(
    accessToken: t.accessToken,
    refreshToken: t.refreshToken,
    accessTokenExpiresAt: t.expiresAt(_clock()),
  );

  Future<void> dispose() => _expired.close();
}
