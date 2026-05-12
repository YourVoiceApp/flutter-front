/// UI 데모용 불변 데이터 (저장·네트워크 없음)
class RoomDemo {
  const RoomDemo({
    required this.id,
    required this.name,
    this.requirePassword = false,
    this.memberNames = const [],
    this.sharedVoices = const [],
  });

  final String id;
  final String name;
  final bool requirePassword;
  final List<String> memberNames;
  final List<SharedVoiceDemo> sharedVoices;

  RoomDemo copyWith({
    String? name,
    List<String>? memberNames,
    List<SharedVoiceDemo>? sharedVoices,
    bool? requirePassword,
  }) {
    return RoomDemo(
      id: id,
      name: name ?? this.name,
      requirePassword: requirePassword ?? this.requirePassword,
      memberNames: memberNames ?? this.memberNames,
      sharedVoices: sharedVoices ?? this.sharedVoices,
    );
  }
}

class SharedVoiceDemo {
  const SharedVoiceDemo({
    required this.id,
    required this.voiceTitle,
    required this.ownerName,
    this.subtitle,
  });

  final String id;
  final String voiceTitle;
  final String ownerName;
  final String? subtitle;
}

/// 참여 중인 방 예시
final List<RoomDemo> kMockJoinedRooms = [
  RoomDemo(
    id: 'r1',
    name: '우리 가족 방',
    requirePassword: true,
    memberNames: ['엄마', '아빠', '나'],
    sharedVoices: [
      SharedVoiceDemo(
        id: 'v1',
        voiceTitle: '엄마 안내 음성',
        ownerName: '엄마',
        subtitle: '학습 완료 · 가게 안내용',
      ),
      SharedVoiceDemo(
        id: 'v2',
        voiceTitle: '아빠 저녁 멘트',
        ownerName: '아빠',
        subtitle: '학습 완료',
      ),
    ],
  ),
  RoomDemo(
    id: 'r2',
    name: '사촌 모임',
    memberNames: ['민수', '서연', '지후'],
    sharedVoices: [
      SharedVoiceDemo(
        id: 'v3',
        voiceTitle: '축하 멘트',
        ownerName: '민수',
        subtitle: '학습 완료',
      ),
    ],
  ),
];

/// 내가 공유할 수 있다고 가정하는 학습 음성 (데모)
const List<SharedVoiceDemo> kMockMyVoicesForShare = [
  SharedVoiceDemo(
    id: 'mine1',
    voiceTitle: 'kim_voice_v1',
    ownerName: '나',
    subtitle: '내 계정 · 학습 완료',
  ),
  SharedVoiceDemo(
    id: 'mine2',
    voiceTitle: '회의 녹음 요약 보이스',
    ownerName: '나',
    subtitle: '학습 완료',
  ),
];
