/// 음성 파일을 묶는 폴더 (예: 동물, 친구)
class VoiceFolder {
  const VoiceFolder({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  /// 미분류 — 삭제 불가, 삭제 시 다른 폴더의 파일만 이쪽으로 이동
  static const String uncategorizedId = 'folder-uncategorized';

  final String id;
  final String name;
  final DateTime createdAt;

  bool get isUncategorized => id == uncategorizedId;
}
