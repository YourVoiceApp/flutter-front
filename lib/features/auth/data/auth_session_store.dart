import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists refresh/access tokens across app restarts.
///
/// On mobile/desktop we prefer secure storage. On web we fall back to browser
/// preferences so the login flow can still be exercised comfortably during
/// day-to-day development.
class AuthSessionStore {
  AuthSessionStore({AuthSessionStorageBackend? backend})
    : _backend = backend ?? createAuthSessionStorageBackend();

  static const _accessKey = 'auth_access_token_v1';
  static const _refreshKey = 'auth_refresh_token_v1';
  static const _userIdKey = 'auth_user_id_v1';

  final AuthSessionStorageBackend _backend;

  Future<void> save({
    String? accessToken,
    String? refreshToken,
    int? userId,
  }) async {
    if (accessToken != null) {
      await _backend.write(_accessKey, accessToken);
    }
    if (refreshToken != null) {
      await _backend.write(_refreshKey, refreshToken);
    }
    if (userId != null) {
      await _backend.write(_userIdKey, userId.toString());
    }
  }

  Future<void> clear() async {
    await _backend.delete(_accessKey);
    await _backend.delete(_refreshKey);
    await _backend.delete(_userIdKey);
  }

  Future<String?> readAccessToken() {
    return _backend.read(_accessKey);
  }

  Future<String?> readRefreshToken() {
    return _backend.read(_refreshKey);
  }

  Future<int?> readUserId() async {
    final raw = await _backend.read(_userIdKey);
    if (raw == null || raw.isEmpty) return null;
    return int.tryParse(raw);
  }
}

abstract interface class AuthSessionStorageBackend {
  Future<void> write(String key, String value);
  Future<String?> read(String key);
  Future<void> delete(String key);
}

AuthSessionStorageBackend createAuthSessionStorageBackend() {
  if (kIsWeb) {
    return SharedPrefsAuthSessionStorageBackend();
  }
  return SecureAuthSessionStorageBackend();
}

class SecureAuthSessionStorageBackend implements AuthSessionStorageBackend {
  SecureAuthSessionStorageBackend({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<void> write(String key, String value) {
    return _storage.write(key: key, value: value);
  }

  @override
  Future<String?> read(String key) {
    return _storage.read(key: key);
  }

  @override
  Future<void> delete(String key) {
    return _storage.delete(key: key);
  }
}

class SharedPrefsAuthSessionStorageBackend
    implements AuthSessionStorageBackend {
  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  @override
  Future<void> write(String key, String value) async {
    final prefs = await _prefs;
    await prefs.setString(key, value);
  }

  @override
  Future<String?> read(String key) async {
    final prefs = await _prefs;
    return prefs.getString(key);
  }

  @override
  Future<void> delete(String key) async {
    final prefs = await _prefs;
    await prefs.remove(key);
  }
}
