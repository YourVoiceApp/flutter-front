import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/user_profile.dart';

const _prefsKey = 'user_profile_account_v1';

/// Local cache for profile data returned from `/me`.
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

  Future<void> saveProfile({
    required String email,
    required String nickname,
    required bool hasPassword,
  }) async {
    final existing = await _readRaw();
    await _writeRaw({
      'email': email,
      'nickname': nickname,
      'statusMessage': existing?['statusMessage'] as String? ?? '',
      'createdAt': existing?['createdAt'] as String? ??
          DateTime.now().toIso8601String(),
      'hasPassword': hasPassword,
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
      hasPassword: m['hasPassword'] as bool? ?? true,
    );
  }

  Future<void> updateProfile(UserProfile profile) async {
    final m = await _readRaw();
    if (m == null) return;
    m['email'] = profile.email;
    m['nickname'] = profile.nickname;
    m['statusMessage'] = profile.statusMessage;
    m['hasPassword'] = profile.hasPassword;
    await _writeRaw(m);
  }
}
