import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the LungSense Pro session tokens.
///
/// Abstract so tests can use an in-memory fake. The production
/// implementation is [SecureTokenStorage] (Keychain / Keystore-backed).
abstract interface class TokenStorage {
  Future<String?> readAccessToken();
  Future<String?> readRefreshToken();

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    DateTime? accessTokenExpiresAt,
  });

  Future<void> clear();
}

/// Secure-storage implementation. Keys are namespaced with `lungsense_pro.`
/// so a Pro session can never be confused with a LungSense Wellness session,
/// even if both apps ever shared a keychain group.
class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _ns = 'lungsense_pro.auth';
  static const accessKey = '$_ns.access_token';
  static const refreshKey = '$_ns.refresh_token';
  static const expiresKey = '$_ns.access_expires_at';

  // In-memory copy avoids a platform-channel read on every request.
  String? _access;
  bool _loaded = false;

  Future<void> _load() async {
    if (_loaded) return;
    _access = await _storage.read(key: accessKey);
    _loaded = true;
  }

  @override
  Future<String?> readAccessToken() async {
    await _load();
    return _access;
  }

  @override
  Future<String?> readRefreshToken() => _storage.read(key: refreshKey);

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    DateTime? accessTokenExpiresAt,
  }) async {
    _access = accessToken;
    _loaded = true;
    await _storage.write(key: accessKey, value: accessToken);
    await _storage.write(key: refreshKey, value: refreshToken);
    if (accessTokenExpiresAt != null) {
      await _storage.write(
        key: expiresKey,
        value: accessTokenExpiresAt.toUtc().toIso8601String(),
      );
    } else {
      await _storage.delete(key: expiresKey);
    }
  }

  @override
  Future<void> clear() async {
    _access = null;
    _loaded = true;
    await _storage.delete(key: accessKey);
    await _storage.delete(key: refreshKey);
    await _storage.delete(key: expiresKey);
  }
}
