import 'package:shared_preferences/shared_preferences.dart';

/// Persists API tokens returned after Google idToken exchange (Spring JWT, etc.).
class AuthSessionStore {
  static const _accessKey = 'auth_access_token_v1';
  static const _refreshKey = 'auth_refresh_token_v1';
  static const _userIdKey = 'auth_user_id_v1';

  Future<void> save({
    String? accessToken,
    String? refreshToken,
    int? userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (accessToken != null) {
      await prefs.setString(_accessKey, accessToken);
    }
    if (refreshToken != null) {
      await prefs.setString(_refreshKey, refreshToken);
    }
    if (userId != null) {
      await prefs.setInt(_userIdKey, userId);
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessKey);
    await prefs.remove(_refreshKey);
    await prefs.remove(_userIdKey);
  }

  Future<String?> readAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessKey);
  }

  Future<String?> readRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshKey);
  }

  Future<int?> readUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey);
  }
}
