import 'dart:typed_data';

import '../../../app/services/app_services.dart';
import '../../../app/services/authenticated_api_client.dart';
import '../../auth/data/auth_api_client.dart';
import '../../auth/data/auth_service.dart';
import '../../voices/data/voice_library_repository.dart';
import '../../voices/domain/voice_folder.dart';
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

  Future<RoomBrowsePage> discoverRooms({int page = 0, int size = 20}) async {
    if (!await usesRemote) {
      final rooms = _mockRooms();
      return RoomBrowsePage(
        content: rooms,
        totalElements: rooms.length,
        totalPages: 1,
        page: 0,
        size: rooms.length,
        first: true,
        last: true,
      );
    }
    final decoded = await _api.getJsonObject(
      '/room/discover',
      queryParameters: <String, String?>{
        'page': '$page',
        'size': '${size.clamp(1, 50)}',
      },
    );
    final content = (decoded['content'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(_roomFromJson)
        .toList(growable: false);
    return RoomBrowsePage(
      content: content,
      totalElements:
          (decoded['totalElements'] as num?)?.toInt() ?? content.length,
      totalPages: (decoded['totalPages'] as num?)?.toInt() ?? 1,
      page: (decoded['page'] as num?)?.toInt() ?? page,
      size: (decoded['size'] as num?)?.toInt() ?? size,
      first: decoded['first'] as bool? ?? page == 0,
      last: decoded['last'] as bool? ?? true,
    );
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
        joinPolicy: usePassword
            ? RoomJoinPolicy.passwordProtected
            : RoomJoinPolicy.public,
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
        'joinPolicy': usePassword ? 'PASSWORD_PROTECTED' : 'PUBLIC',
        'maxParticipants': maxParticipants,
        if (usePassword) 'password': password ?? '',
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
        'joinPolicy': usePassword ? 'PASSWORD_PROTECTED' : 'PUBLIC',
        'maxParticipants': maxParticipants,
        if (usePassword) 'password': password ?? '',
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
    } on AuthApiException catch (e) {
      // 404만 목록 없음으로 처리하고, 그 외 실패는 디버깅·복구를 위해 전파합니다.
      if (e.statusCode != 404) rethrow;
    }
    return result;
  }

  Future<Room> joinRoom({required String roomId, String? password}) async {
    if (!await usesRemote) {
      throw UnsupportedError('로그인이 필요해요.');
    }
    final trimmedRoomId = roomId.trim();
    if (trimmedRoomId.isEmpty) {
      throw ArgumentError('입장할 방을 선택해 주세요.');
    }

    final body = <String, dynamic>{
      'roomId': int.tryParse(trimmedRoomId) ?? trimmedRoomId,
      if (password != null && password.trim().isNotEmpty)
        'password': password.trim(),
    };
    final joined = await _api.postJsonObject('/room/join', body: body);
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

    /// 음성별 방에 보일 이름(voiceKey 등 external id 키). 비어 있거나 키 없으면 라이브러리 파일명 사용.
    Map<String, String>? shareDisplayTitlesByExternalVoiceId,
  }) async {
    if (!await usesRemote) {
      final voices = await loadSharableVoices();
      final titleFor = shareDisplayTitlesByExternalVoiceId ?? {};
      final selected = voices
          .where((voice) => selectedVoiceIds.contains(voice.id))
          .map(
            (voice) => RoomSharedVoice(
              id: voice.id,
              externalVoiceId: voice.id,
              voiceTitle: () {
                final t = titleFor[voice.id]?.trim() ?? '';
                return t.isEmpty ? voice.fileName : t;
              }(),
              ownerName: '나',
              subtitle: voice.origin.label,
              accessScope: accessScopeForSelection,
              ownershipId: voice.ownershipId,
            ),
          )
          .toList(growable: false);
      return room.copyWith(sharedVoices: selected);
    }

    final sharable = await loadSharableVoices();
    final fileNameById = {for (final v in sharable) v.id: v.fileName};

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

    for (final share in toRemove) {
      await _api.deleteNoContent('/room/${room.id}/voice-shares/${share.id}');
    }

    /// `PUT …/voice-shares/{shareId}` — `accessScope` + 방 표시 이름 `shareDisplayTitle`
    for (final share in existingShares) {
      if (!selectedVoiceIds.contains(share.externalVoiceId)) continue;
      final desiredTitle = _resolveShareDisplayTitle(
        voiceId: share.externalVoiceId,
        customTitles: shareDisplayTitlesByExternalVoiceId,
        fileNameById: fileNameById,
      );
      final scopeChanged = share.accessScope != accessScopeForSelection;
      final titleChanged = desiredTitle.trim() != share.voiceTitle.trim();
      if (!scopeChanged && !titleChanged) continue;

      await _api.putJsonObject(
        '/room/${room.id}/voice-shares/${share.id}',
        body: <String, dynamic>{
          'accessScope': wireScope,
          'shareDisplayTitle': desiredTitle,
        },
      );
    }

    if (toAdd.isNotEmpty) {
      final titleMap = <String, String>{
        for (final id in toAdd)
          id: _resolveShareDisplayTitle(
            voiceId: id,
            customTitles: shareDisplayTitlesByExternalVoiceId,
            fileNameById: fileNameById,
          ),
      };
      await _api.postJsonList(
        '/room/${room.id}/voice-shares',
        body: <String, dynamic>{
          'externalVoiceIds': toAdd,
          'accessScope': wireScope,
          'shareDisplayTitlesByExternalVoiceId': titleMap,
        },
      );
    }

    /// POST 직후 `GET …/voice-shares` 가 아직 빈 목록을 줄 때가 있어, 반영까지 폴링합니다.
    return _reloadRoomDetailWhenSharesInclude(
      room,
      mustIncludeVoiceKeys: toAdd,
    );
  }

  /// 공유 레코드 한 건 수정: `PUT /room/{roomId}/voice-shares/{shareId}`
  Future<Room> updateRoomSharedVoice({
    required Room room,
    required String shareRecordId,
    required RoomVoiceAccessScope accessScope,
    required String shareDisplayTitle,
  }) async {
    if (!await usesRemote) {
      final t = shareDisplayTitle.trim();
      final nextVoices = room.sharedVoices
          .map((v) {
            if (v.id != shareRecordId) return v;
            return v.copyWith(
              voiceTitle: t.isEmpty ? v.voiceTitle : t,
              accessScope: accessScope,
              subtitle: switch (accessScope) {
                RoomVoiceAccessScope.listenOnly => '듣기 전용',
                RoomVoiceAccessScope.downloadAllowed => '다운로드 허용',
              },
            );
          })
          .toList(growable: false);
      return room.copyWith(sharedVoices: nextVoices);
    }

    final t = shareDisplayTitle.trim();
    if (t.isEmpty) throw ArgumentError('방에 보일 이름을 입력해 주세요.');

    await _api.putJsonObject(
      '/room/${room.id}/voice-shares/$shareRecordId',
      body: <String, dynamic>{
        'accessScope': _accessScopeToWire(accessScope),
        'shareDisplayTitle': t,
      },
    );
    return loadRoomDetail(room);
  }

  /// [mustIncludeVoiceKeys] 가 비면 한 번만 [loadRoomDetail] 합니다.
  Future<Room> _reloadRoomDetailWhenSharesInclude(
    Room room, {
    List<String> mustIncludeVoiceKeys = const [],
  }) async {
    if (mustIncludeVoiceKeys.isEmpty) {
      return loadRoomDetail(room);
    }

    final required = mustIncludeVoiceKeys.toSet();
    const maxAttempts = 10;
    const delayBetween = Duration(milliseconds: 280);

    Room? lastDetail;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      lastDetail = await loadRoomDetail(room);
      final present = lastDetail.sharedVoices
          .map((v) => v.externalVoiceId)
          .toSet();
      if (required.every(present.contains)) {
        return lastDetail;
      }
      if (attempt < maxAttempts - 1) {
        await Future<void>.delayed(delayBetween);
      }
    }
    return lastDetail!;
  }

  /// 다운로드 허용 공유를 내 라이브러리에 추가합니다.
  /// 서버: `POST /room/{roomId}/voice-shares/{shareId}/claim`
  Future<VoiceJob> claimRoomSharedVoice({
    required String roomId,
    required String shareId,
  }) async {
    if (!await usesRemote) {
      throw UnsupportedError('로그인 후에만 공유 음성을 내 음성에 추가할 수 있어요.');
    }
    final response = await _api.postJsonObject(
      '/room/$roomId/voice-shares/$shareId/claim',
      successCodes: const {200},
    );
    return _ownedVoiceFromJson(response);
  }

  /// 레거시 방 공유 음성 합성. 신규 명세에서는 claim 후 `POST /voices/{ownershipId}/text-to-speech` 를 사용합니다.
  Future<VoiceSynthesisResult> synthesizeRoomSharedSpeech({
    required String roomId,
    required String shareId,
    required String text,
  }) async {
    if (!await usesRemote) {
      throw UnsupportedError('로그인 후에만 방 공유 음성 합성을 할 수 있어요.');
    }
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('읽을 문장을 입력해 주세요.');
    }
    final response = await _api.postJsonObject(
      '/room/$roomId/voice-shares/$shareId/text-to-speech',
      body: <String, dynamic>{'text': trimmed},
      successCodes: const {200, 201},
    );
    return VoiceSynthesisResult(
      speechRequestId: (response['speechRequestId'] as num?)?.toInt() ?? 0,
      generatedAudioId: (response['generatedAudioId'] as num?)?.toInt() ?? 0,
      streamUrl: response['streamUrl'] as String? ?? '',
      downloadUrl: response['downloadUrl'] as String? ?? '',
    );
  }

  /// [VoiceLibraryRepository.fetchGeneratedAudioStream] 과 동일한 스트림 URL.
  Future<Uint8List> fetchGeneratedAudioStream(int generatedAudioId) {
    return _voiceLibraryRepository.fetchGeneratedAudioStream(generatedAudioId);
  }

  /// 합성 API JSON 응답 기준으로 스트림 바이트 로드 (`generatedAudioId` 또는 `streamUrl`).
  Future<Uint8List> fetchSynthesizedAudioBytes(VoiceSynthesisResult result) {
    return _voiceLibraryRepository.fetchSynthesisPlayback(result);
  }

  /// 보유 음성과 동일 — `POST /voices/{ownershipId}/text-to-speech`
  Future<VoiceSynthesisResult> synthesizeOwnedVoiceSpeech({
    required int ownershipId,
    required String text,
  }) {
    return _voiceLibraryRepository.synthesizeSpeechWithOwnershipId(
      ownershipId: ownershipId,
      text: text,
    );
  }

  /// 다운로드 허용 권한용 — 합성 결과 파일 형태 (`GET …/download`).
  Future<Uint8List> fetchGeneratedAudioDownload(int generatedAudioId) {
    return _voiceLibraryRepository.fetchGeneratedAudioDownload(
      generatedAudioId,
    );
  }

  List<Room> _mockRooms() {
    return kMockJoinedRooms
        .map(
          (demo) => Room(
            id: demo.id,
            name: demo.name,
            joinPolicy: demo.requirePassword
                ? RoomJoinPolicy.passwordProtected
                : RoomJoinPolicy.public,
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

String _resolveShareDisplayTitle({
  required String voiceId,
  Map<String, String>? customTitles,
  required Map<String, String> fileNameById,
}) {
  final raw = customTitles?[voiceId]?.trim();
  if (raw != null && raw.isNotEmpty) return raw;
  final name = fileNameById[voiceId]?.trim();
  if (name != null && name.isNotEmpty) return name;
  return voiceId;
}

int? _parseWireInt(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v.trim());
  return null;
}

Room _roomFromJson(Map<String, dynamic> json) {
  final name = json['name'] as String?;
  final title = json['title'] as String?;
  final resolvedName = (name != null && name.isNotEmpty) ? name : (title ?? '');
  return Room(
    id: '${json['id']}',
    name: resolvedName,
    ownerId: (json['ownerId'] as num?)?.toInt(),
    joinPolicy: _joinPolicyFromWire(json['joinPolicy'] as String?),
    maxParticipants: (json['maxParticipants'] as num?)?.toInt() ?? 0,
    activeMemberCount: (json['activeMemberCount'] as num?)?.toInt(),
    createdAt:
        DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    updatedAt:
        DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
  );
}

String _canonicalShareVoiceExternalId(Map<String, dynamic> json) {
  String pick(Object? raw) {
    if (raw == null) return '';
    final s = raw.toString().trim();
    if (s.isEmpty || s.toLowerCase() == 'null') return '';
    return s;
  }

  final fromKey = pick(json['voiceKey']);
  if (fromKey.isNotEmpty) return fromKey;
  final fromExternal = pick(json['externalVoiceId']);
  if (fromExternal.isNotEmpty) return fromExternal;
  return '';
}

RoomSharedVoice _sharedVoiceFromJson(Map<String, dynamic> json) {
  final accessScope = _accessScopeFromWire(json['accessScope'] as String?);
  final canonicalId = _canonicalShareVoiceExternalId(json);
  final shareRowId = '${json['id']}';
  final rawRoomId = json['roomId'];
  final roomIdStr = rawRoomId == null
      ? null
      : rawRoomId.toString().trim().isEmpty
      ? null
      : rawRoomId.toString().trim();
  final rawVk = json['voiceKey'];
  final vkTrimmed = rawVk?.toString().trim() ?? '';
  final voiceKeyStr = vkTrimmed.isEmpty ? null : vkTrimmed;

  return RoomSharedVoice(
    id: shareRowId,
    externalVoiceId: canonicalId.isNotEmpty ? canonicalId : shareRowId,
    voiceTitle: json['voiceTitle'] as String? ?? '공유 음성',
    ownerName: json['ownerName'] as String? ?? '공유 음성',
    ownershipId:
        _parseWireInt(json['ownershipId']) ??
        _parseWireInt(json['voiceOwnershipId']),
    accessScope: accessScope,
    sharedAt:
        DateTime.tryParse(json['sharedAt'] as String? ?? '') ?? DateTime.now(),
    roomId: roomIdStr,
    voiceKey: voiceKeyStr,
    subtitle: switch (accessScope) {
      RoomVoiceAccessScope.listenOnly => '듣기 전용',
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
    'PASSWORD_PROTECTED' => RoomJoinPolicy.passwordProtected,
    _ => RoomJoinPolicy.public,
  };
}

RoomVoiceAccessScope _accessScopeFromWire(String? wire) {
  return switch ((wire ?? '').toUpperCase()) {
    'LISTEN_ONLY' => RoomVoiceAccessScope.listenOnly,

    /// 서버/구버전 데이터 호환: 합성 권한은 앱에서 지원하지 않아 듣기 전용으로 취급
    'SYNTHESIS_ALLOWED' => RoomVoiceAccessScope.listenOnly,
    'DOWNLOAD_ALLOWED' => RoomVoiceAccessScope.downloadAllowed,
    _ => RoomVoiceAccessScope.listenOnly,
  };
}

String _accessScopeToWire(RoomVoiceAccessScope scope) {
  return switch (scope) {
    RoomVoiceAccessScope.listenOnly => 'LISTEN_ONLY',
    RoomVoiceAccessScope.downloadAllowed => 'DOWNLOAD_ALLOWED',
  };
}

String _ownedVoiceFolderId(Object? rawFolderId) {
  if (rawFolderId == null) return VoiceFolder.uncategorizedId;
  final value = rawFolderId.toString().trim();
  if (value.isEmpty || value == '0' || value.toLowerCase() == 'null') {
    return VoiceFolder.uncategorizedId;
  }
  return value;
}

VoiceJob _ownedVoiceFromJson(Map<String, dynamic> json) {
  final acquiredBy = (json['acquiredBy'] as String? ?? '').toUpperCase();
  return VoiceJob(
    id: json['voiceKey'] as String? ?? json['externalVoiceId'] as String? ?? '',
    fileName: json['title'] as String? ?? '공유 음성',
    status: VoiceJobStatus.completed,
    createdAt:
        DateTime.tryParse(json['acquiredAt'] as String? ?? '') ??
        DateTime.now(),
    folderId: _ownedVoiceFolderId(json['folderId']),
    ownershipId:
        _parseWireInt(json['ownershipId']) ?? _parseWireInt(json['id']),
    origin: acquiredBy == 'ROOM_SHARED'
        ? VoiceOrigin.sharedRoom
        : VoiceOrigin.uploaded,
  );
}
