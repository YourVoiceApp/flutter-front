/// Cached user profile restored from the backend after sign-in.
class UserProfile {
  const UserProfile({
    required this.email,
    required this.nickname,
    this.statusMessage = '',
    required this.createdAt,
    this.hasPassword = true,
  });

  final String email;
  final String nickname;

  /// 한 줄 소개 등
  final String statusMessage;
  final DateTime createdAt;
  final bool hasPassword;

  UserProfile copyWith({
    String? email,
    String? nickname,
    String? statusMessage,
    DateTime? createdAt,
    bool? hasPassword,
  }) {
    return UserProfile(
      email: email ?? this.email,
      nickname: nickname ?? this.nickname,
      statusMessage: statusMessage ?? this.statusMessage,
      createdAt: createdAt ?? this.createdAt,
      hasPassword: hasPassword ?? this.hasPassword,
    );
  }
}
