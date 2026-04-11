import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/user_profile.dart';

const _prefsKey = 'user_profile_account_v1';

/// 프로필 + 데모용 비밀번호 (JSON 내부 필드 — 출시 시 서버/API로 교체)
class UserProfileRepository {
  UserProfileRepository();

  Future<Map<String, dynamic>?> _readRaw() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeRaw(Map<String, dynamic> map) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(map));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }

  /// 가입 또는 전체 덮어쓰기
  Future<void> saveAccount({
    required UserProfile profile,
    required String password,
  }) async {
    await _writeRaw({
      'email': profile.email,
      'nickname': profile.nickname,
      'statusMessage': profile.statusMessage,
      'createdAt': profile.createdAt.toIso8601String(),
      'password': password,
      'oauthProvider': 'password',
    });
  }

  /// After Google Sign-In + backend exchange; keeps local demo profile in sync.
  Future<void> saveGoogleSignInProfile({
    required String email,
    required String nickname,
  }) async {
    final existing = await _readRaw();
    final created = existing?['createdAt'] as String? ??
        DateTime.now().toIso8601String();
    final status = existing?['statusMessage'] as String? ?? '';
    await _writeRaw({
      'email': email,
      'nickname': nickname,
      'statusMessage': status,
      'createdAt': created,
      'password': '__google_oauth__',
      'oauthProvider': 'google',
    });
  }

  Future<UserProfile?> loadProfile() async {
    final m = await _readRaw();
    if (m == null) return null;
    return UserProfile(
      email: m['email'] as String,
      nickname: m['nickname'] as String? ?? '',
      statusMessage: m['statusMessage'] as String? ?? '',
      createdAt: DateTime.tryParse(m['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Future<String?> loadPassword() async {
    final m = await _readRaw();
    return m?['password'] as String?;
  }

  Future<void> updateProfile(UserProfile profile) async {
    final m = await _readRaw();
    if (m == null) return;
    m['nickname'] = profile.nickname;
    m['statusMessage'] = profile.statusMessage;
    await _writeRaw(m);
  }

  Future<void> updatePassword(String newPassword) async {
    final m = await _readRaw();
    if (m == null) return;
    m['password'] = newPassword;
    await _writeRaw(m);
  }

  /// 이메일이 계정과 일치하는지 (비밀번호 찾기용)
  Future<bool> hasEmail(String email) async {
    final p = await loadProfile();
    if (p == null) return false;
    return p.email.toLowerCase() == email.trim().toLowerCase();
  }

  Future<bool> verifyLogin(String email, String password) async {
    final m = await _readRaw();
    if (m == null) return false;
    final e = (m['email'] as String?)?.toLowerCase();
    final pw = m['password'] as String?;
    return e == email.trim().toLowerCase() && pw == password;
  }
}
