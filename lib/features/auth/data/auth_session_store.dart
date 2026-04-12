import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists refresh/access tokens across app restarts.
class AuthSessionStore {
  static const _accessKey = 'auth_access_token_v1';
  static const _refreshKey = 'auth_refresh_token_v1';
  static const _userIdKey = 'auth_user_id_v1';
  static const _storage = FlutterSecureStorage();

  Future<void> save({
    String? accessToken,
    String? refreshToken,
    int? userId,
  }) async {
    if (accessToken != null) {
      await _storage.write(key: _accessKey, value: accessToken);
    }
    if (refreshToken != null) {
      await _storage.write(key: _refreshKey, value: refreshToken);
    }
    if (userId != null) {
      await _storage.write(key: _userIdKey, value: userId.toString());
    }
  }

  Future<void> clear() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
    await _storage.delete(key: _userIdKey);
  }

  Future<String?> readAccessToken() async {
    return _storage.read(key: _accessKey);
  }

  Future<String?> readRefreshToken() async {
    return _storage.read(key: _refreshKey);
  }

  Future<int?> readUserId() async {
    final raw = await _storage.read(key: _userIdKey);
    if (raw == null || raw.isEmpty) return null;
    return int.tryParse(raw);
  }
}
