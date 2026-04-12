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
}
