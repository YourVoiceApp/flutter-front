enum RoomJoinPolicy { inviteCodeOnly, inviteCodeWithPassword }

enum RoomVoiceAccessScope { listenOnly, synthesisAllowed, downloadAllowed }

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
  });

  final String id;
  final String voiceTitle;
  final String externalVoiceId;
  final String ownerName;
  final RoomVoiceAccessScope accessScope;
  final DateTime? sharedAt;
  final String? subtitle;
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
