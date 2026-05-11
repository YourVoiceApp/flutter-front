class AuthUser {
  const AuthUser({
    required this.id,
    required this.nickName,
    required this.email,
    required this.hasPassword,
  });

  final int id;
  final String nickName;
  final String email;
  final bool hasPassword;

  /// 소셜만 가입(`hasPassword == false`)이고 서버 닉네임이 비었거나 너무 짧을 때 프로필 설정 화면으로 보냄.
  bool get needsSocialNicknameSetup {
    if (hasPassword) return false;
    final n = nickName.trim();
    return n.isEmpty || n.length < 2;
  }
}
