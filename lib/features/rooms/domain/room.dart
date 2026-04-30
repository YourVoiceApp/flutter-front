enum RoomJoinPolicy { inviteCodeOnly, inviteCodeWithPassword }

enum RoomVoiceAccessScope { listenOnly, downloadAllowed }

enum RoomMemberRole { owner, member }

class RoomMember {
  const RoomMember({
    required this.id,
    required this.displayName,
    this.role = RoomMemberRole.member,
  });

  final String id;
  final String displayName;
  final RoomMemberRole role;

  bool get isOwner => role == RoomMemberRole.owner;
}

class RoomSharedVoice {
  const RoomSharedVoice({
    required this.id,
    required this.voiceTitle,
    required this.externalVoiceId,
    this.ownerName = '공유 음성',
    this.accessScope = RoomVoiceAccessScope.listenOnly,
    this.sharedAt,
    this.subtitle,
    this.roomId,
    this.voiceKey,
  });

  /// 공유 레코드 id — `DELETE`/`PUT …/voice-shares/{shareId}` 경로용
  final String id;
  final String voiceTitle;
  /// 클론 음성 식별(라이브러리와 동일 키)
  final String externalVoiceId;
  final String ownerName;
  final RoomVoiceAccessScope accessScope;
  final DateTime? sharedAt;
  final String? subtitle;
  /// API `roomId` (있을 때만)
  final String? roomId;
  /// API `voiceKey` (있을 때만, 보통 externalVoiceId 와 동일)
  final String? voiceKey;

  RoomSharedVoice copyWith({
    String? id,
    String? voiceTitle,
    String? externalVoiceId,
    String? ownerName,
    RoomVoiceAccessScope? accessScope,
    DateTime? sharedAt,
    String? subtitle,
    String? roomId,
    String? voiceKey,
  }) {
    return RoomSharedVoice(
      id: id ?? this.id,
      voiceTitle: voiceTitle ?? this.voiceTitle,
      externalVoiceId: externalVoiceId ?? this.externalVoiceId,
      ownerName: ownerName ?? this.ownerName,
      accessScope: accessScope ?? this.accessScope,
      sharedAt: sharedAt ?? this.sharedAt,
      subtitle: subtitle ?? this.subtitle,
      roomId: roomId ?? this.roomId,
      voiceKey: voiceKey ?? this.voiceKey,
    );
  }
}

class Room {
  const Room({
    required this.id,
    required this.name,
    required this.inviteCode,
    this.ownerId,
    this.joinPolicy = RoomJoinPolicy.inviteCodeOnly,
    this.maxParticipants = 0,
    this.createdAt,
    this.updatedAt,
    this.members = const [],
    this.sharedVoices = const [],
  });

  final String id;
  final String name;
  final String inviteCode;
  final int? ownerId;
  final RoomJoinPolicy joinPolicy;
  final int maxParticipants;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<RoomMember> members;
  final List<RoomSharedVoice> sharedVoices;

  bool get requiresPassword =>
      joinPolicy == RoomJoinPolicy.inviteCodeWithPassword;

  int get memberCount => members.length;

  List<String> get memberNames =>
      members.map((member) => member.displayName).toList(growable: false);

  Room copyWith({
    String? name,
    String? inviteCode,
    int? ownerId,
    RoomJoinPolicy? joinPolicy,
    int? maxParticipants,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<RoomMember>? members,
    List<RoomSharedVoice>? sharedVoices,
  }) {
    return Room(
      id: id,
      name: name ?? this.name,
      inviteCode: inviteCode ?? this.inviteCode,
      ownerId: ownerId ?? this.ownerId,
      joinPolicy: joinPolicy ?? this.joinPolicy,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      members: members ?? this.members,
      sharedVoices: sharedVoices ?? this.sharedVoices,
    );
  }
}
