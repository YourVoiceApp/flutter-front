import '../../../app/services/app_services.dart';
import '../../../app/services/authenticated_api_client.dart';
import '../../auth/data/auth_api_client.dart';
import '../../auth/data/auth_service.dart';
import '../../voices/data/voice_library_repository.dart';
import '../../voices/domain/voice_job.dart';
import '../domain/room.dart';
import '../presentation/room_demo_data.dart';

class RoomRepository {
  RoomRepository({
    AuthService? authService,
    AuthenticatedApiClient? apiClient,
    VoiceLibraryRepository? voiceLibraryRepository,
  }) : _authService = authService ?? AppServices.instance.authService,
       _api =
           apiClient ??
           AuthenticatedApiClient(
             authService: authService ?? AppServices.instance.authService,
           ),
       _voiceLibraryRepository =
           voiceLibraryRepository ?? VoiceLibraryRepository();

  final AuthService _authService;
  final AuthenticatedApiClient _api;
  final VoiceLibraryRepository _voiceLibraryRepository;

  Future<bool> get usesRemote async => _authService.hasStoredSession();

  Future<bool> isRoomOwner(Room room) async {
    final uid = await _authService.readSessionUserId();
    if (uid == null || room.ownerId == null) return false;
    return uid == room.ownerId;
  }

  Future<List<Room>> loadRooms() async {
    if (!await usesRemote) return _mockRooms();
    final decoded = await _api.getJsonList('/room');
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(_roomFromJson)
        .toList(growable: false);
  }

  Future<Room> createRoom({
    required String title,
    required bool usePassword,
    String? password,
    int maxParticipants = 3,
  }) async {
    if (!await usesRemote) {
      return Room(
        id: 'new-${DateTime.now().millisecondsSinceEpoch}',
        name: title,
        inviteCode: 'FAM-${DateTime.now().millisecondsSinceEpoch % 10000}',
        joinPolicy: usePassword
            ? RoomJoinPolicy.inviteCodeWithPassword
            : RoomJoinPolicy.inviteCodeOnly,
        maxParticipants: maxParticipants,
        members: const [
          RoomMember(id: 'me', displayName: '나', role: RoomMemberRole.owner),
        ],
      );
    }

    final created = await _api.postJsonObject(
      '/room',
      body: <String, dynamic>{
        'title': title,
        'joinPolicy': usePassword
            ? 'INVITE_CODE_WITH_PASSWORD'
            : 'INVITE_CODE_ONLY',
        'maxParticipants': maxParticipants,
        'password': usePassword ? (password ?? '') : '',
      },
    );
    return _roomFromJson(created);
  }

  Future<Room> updateRoom({
    required String roomId,
    required String title,
    required bool usePassword,
    String? password,
    int maxParticipants = 3,
  }) async {
    if (!await usesRemote) {
      throw UnsupportedError('로그인 후에만 방을 수정할 수 있어요.');
    }
    final updated = await _api.putJsonObject(
      '/room/$roomId',
      body: <String, dynamic>{
        'title': title,
        'joinPolicy': usePassword
            ? 'INVITE_CODE_WITH_PASSWORD'
            : 'INVITE_CODE_ONLY',
        'maxParticipants': maxParticipants,
        'password': usePassword ? (password ?? '') : '',
      },
    );
    return _roomFromJson(updated);
  }

  Future<void> deleteRoom(String roomId) async {
    if (!await usesRemote) {
      throw UnsupportedError('로그인 후에만 방을 삭제할 수 있어요.');
    }
    await _api.deleteNoContent('/room/$roomId');
  }

  Future<Room> loadRoomDetail(Room room) async {
    if (!await usesRemote) return room;
    Map<String, dynamic> detailJson;
    try {
      detailJson = await _api.getJsonObject('/room/${room.id}');
    } on AuthApiException catch (e) {
      if (e.statusCode == 404) return room;
      rethrow;
    }
    var result = _roomFromJson(detailJson);
    try {
      final members = await _api.getJsonList('/room/${room.id}/members');
      result = result.copyWith(
        members: members
            .whereType<Map<String, dynamic>>()
            .map(_memberFromJson)
            .toList(growable: false),
      );
    } on AuthApiException catch (_) {
      // Optional endpoint — list/detail may omit members.
    }
    try {
      final shares = await _api.getJsonList('/room/${room.id}/voice-shares');
      result = result.copyWith(
        sharedVoices: shares
            .whereType<Map<String, dynamic>>()
            .map(_sharedVoiceFromJson)
            .toList(growable: false),
      );
    } on AuthApiException catch (_) {
      // Optional endpoint.
    }
    return result;
  }

  Future<Room> joinRoom({
    required String inviteCode,
    String? password,
  }) async {
    if (!await usesRemote) {
      throw UnsupportedError('로그인이 필요해요.');
    }
    final joined = await _api.postJsonObject(
      '/room/join',
      body: <String, dynamic>{
        'inviteCode': inviteCode,
        'password': password ?? '',
      },
    );
    return _roomFromJson(joined);
  }

  Future<List<VoiceJob>> loadSharableVoices() async {
    final snapshot = await _voiceLibraryRepository.load();
    return snapshot.jobs
        .where((job) => job.status == VoiceJobStatus.completed)
        .toList(growable: false);
  }

  Future<Room> syncSharedVoices({
    required Room room,
    required Set<String> selectedVoiceIds,
    RoomVoiceAccessScope accessScopeForSelection =
        RoomVoiceAccessScope.listenOnly,
  }) async {
    if (!await usesRemote) {
      final voices = await loadSharableVoices();
      final selected = voices
          .where((voice) => selectedVoiceIds.contains(voice.id))
          .map(
            (voice) => RoomSharedVoice(
              id: voice.id,
              externalVoiceId: voice.id,
              voiceTitle: voice.fileName,
              ownerName: '나',
              subtitle: voice.origin.label,
              accessScope: accessScopeForSelection,
            ),
          )
          .toList(growable: false);
      return room.copyWith(sharedVoices: selected);
    }

    final existing = await _api.getJsonList('/room/${room.id}/voice-shares');
    final existingShares = existing
        .whereType<Map<String, dynamic>>()
        .map(_sharedVoiceFromJson)
        .toList(growable: false);
    final existingByExternalId = {
      for (final share in existingShares) share.externalVoiceId: share,
    };

    final wireScope = _accessScopeToWire(accessScopeForSelection);

    final toRemove = existingShares
        .where((share) => !selectedVoiceIds.contains(share.externalVoiceId))
        .toList(growable: false);
    final toAdd = selectedVoiceIds
        .where((id) => !existingByExternalId.containsKey(id))
        .toList(growable: false);
    final toUpdateScope = existingShares
        .where(
          (share) =>
              selectedVoiceIds.contains(share.externalVoiceId) &&
              share.accessScope != accessScopeForSelection,
        )
        .toList(growable: false);

    for (final share in toRemove) {
      await _api.deleteNoContent('/room/${room.id}/voice-shares/${share.id}');
    }

    for (final share in toUpdateScope) {
      await _api.putJsonObject(
        '/room/${room.id}/voice-shares/${share.id}',
        body: <String, dynamic>{'accessScope': wireScope},
      );
    }

    if (toAdd.isNotEmpty) {
      await _api.postJsonList(
        '/room/${room.id}/voice-shares',
        body: <String, dynamic>{
          'externalVoiceIds': toAdd,
          'accessScope': wireScope,
        },
      );
    }

    return loadRoomDetail(room);
  }

  List<Room> _mockRooms() {
    return kMockJoinedRooms
        .map(
          (demo) => Room(
            id: demo.id,
            name: demo.name,
            inviteCode: demo.inviteCode,
            joinPolicy: demo.requirePassword
                ? RoomJoinPolicy.inviteCodeWithPassword
                : RoomJoinPolicy.inviteCodeOnly,
            members: [
              for (final name in demo.memberNames)
                RoomMember(id: name, displayName: name),
            ],
            sharedVoices: [
              for (final voice in demo.sharedVoices)
                RoomSharedVoice(
                  id: voice.id,
                  externalVoiceId: voice.id,
                  voiceTitle: voice.voiceTitle,
                  ownerName: voice.ownerName,
                  subtitle: voice.subtitle,
                ),
            ],
          ),
        )
        .toList(growable: false);
  }
}

Room _roomFromJson(Map<String, dynamic> json) {
  final name = json['name'] as String?;
  final title = json['title'] as String?;
  final resolvedName =
      (name != null && name.isNotEmpty) ? name : (title ?? '');
  return Room(
    id: '${json['id']}',
    name: resolvedName,
    inviteCode: '${json['inviteCode'] ?? ''}',
    ownerId: (json['ownerId'] as num?)?.toInt(),
    joinPolicy: _joinPolicyFromWire(json['joinPolicy'] as String?),
    maxParticipants: (json['maxParticipants'] as num?)?.toInt() ?? 0,
    createdAt:
        DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    updatedAt:
        DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
  );
}

RoomSharedVoice _sharedVoiceFromJson(Map<String, dynamic> json) {
  final accessScope = _accessScopeFromWire(json['accessScope'] as String?);
  return RoomSharedVoice(
    id: '${json['id']}',
    externalVoiceId:
        json['externalVoiceId'] as String? ??
        json['voiceKey'] as String? ??
        '${json['id']}',
    voiceTitle: json['voiceTitle'] as String? ?? '공유 음성',
    ownerName: json['ownerName'] as String? ?? '공유 음성',
    accessScope: accessScope,
    sharedAt:
        DateTime.tryParse(json['sharedAt'] as String? ?? '') ?? DateTime.now(),
    subtitle: switch (accessScope) {
      RoomVoiceAccessScope.listenOnly => '듣기 전용',
      RoomVoiceAccessScope.synthesisAllowed => '합성 허용',
      RoomVoiceAccessScope.downloadAllowed => '다운로드 허용',
    },
  );
}

RoomMember _memberFromJson(Map<String, dynamic> json) {
  final role = (json['role'] as String? ?? '').toUpperCase() == 'OWNER'
      ? RoomMemberRole.owner
      : RoomMemberRole.member;
  return RoomMember(
    id: '${json['id']}',
    displayName: json['displayName'] as String? ?? '',
    role: role,
  );
}

RoomJoinPolicy _joinPolicyFromWire(String? wire) {
  return switch ((wire ?? '').toUpperCase()) {
    'INVITE_CODE_WITH_PASSWORD' => RoomJoinPolicy.inviteCodeWithPassword,
    _ => RoomJoinPolicy.inviteCodeOnly,
  };
}

RoomVoiceAccessScope _accessScopeFromWire(String? wire) {
  return switch ((wire ?? '').toUpperCase()) {
    'LISTEN_ONLY' => RoomVoiceAccessScope.listenOnly,
    'SYNTHESIS_ALLOWED' => RoomVoiceAccessScope.synthesisAllowed,
    'DOWNLOAD_ALLOWED' => RoomVoiceAccessScope.downloadAllowed,
    _ => RoomVoiceAccessScope.listenOnly,
  };
}

String _accessScopeToWire(RoomVoiceAccessScope scope) {
  return switch (scope) {
    RoomVoiceAccessScope.listenOnly => 'LISTEN_ONLY',
    RoomVoiceAccessScope.synthesisAllowed => 'SYNTHESIS_ALLOWED',
    RoomVoiceAccessScope.downloadAllowed => 'DOWNLOAD_ALLOWED',
  };
}
