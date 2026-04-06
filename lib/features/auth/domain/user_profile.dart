/// 로컬에 저장되는 사용자 프로필 (데모 — 비밀번호는 평문 저장하지 말고 서버 연동 시 해시)
class UserProfile {
  const UserProfile({
    required this.email,
    required this.nickname,
    this.statusMessage = '',
    required this.createdAt,
  });

  final String email;
  final String nickname;

  /// 한 줄 소개 등
  final String statusMessage;
  final DateTime createdAt;

  UserProfile copyWith({
    String? email,
    String? nickname,
    String? statusMessage,
    DateTime? createdAt,
  }) {
    return UserProfile(
      email: email ?? this.email,
      nickname: nickname ?? this.nickname,
      statusMessage: statusMessage ?? this.statusMessage,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
