enum RoomMemberRole {
  owner,
  member,
}

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
    required this.ownerName,
    this.subtitle,
  });

  final String id;
  final String voiceTitle;
  final String ownerName;
  final String? subtitle;
}

class Room {
  const Room({
    required this.id,
    required this.name,
    required this.inviteCode,
    this.requiresPassword = false,
    this.members = const [],
    this.sharedVoices = const [],
  });

  final String id;
  final String name;
  final String inviteCode;
  final bool requiresPassword;
  final List<RoomMember> members;
  final List<RoomSharedVoice> sharedVoices;

  int get memberCount => members.length;

  List<String> get memberNames =>
      members.map((member) => member.displayName).toList(growable: false);

  Room copyWith({
    String? name,
    bool? requiresPassword,
    List<RoomMember>? members,
    List<RoomSharedVoice>? sharedVoices,
  }) {
    return Room(
      id: id,
      name: name ?? this.name,
      inviteCode: inviteCode,
      requiresPassword: requiresPassword ?? this.requiresPassword,
      members: members ?? this.members,
      sharedVoices: sharedVoices ?? this.sharedVoices,
    );
  }
}
