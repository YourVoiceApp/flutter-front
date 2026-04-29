import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../app/services/app_services.dart';
import '../../../app/services/authenticated_api_client.dart';
import '../../auth/data/auth_service.dart';
import '../domain/voice_folder.dart';
import '../domain/voice_job.dart';
import '../domain/voice_upload_request.dart';

const _prefsKey = 'voice_library_v1';

class VoiceLibrarySnapshot {
  const VoiceLibrarySnapshot({required this.folders, required this.jobs});

  final List<VoiceFolder> folders;
  final List<VoiceJob> jobs;

  static VoiceLibrarySnapshot seed() {
    return VoiceLibrarySnapshot(
      folders: [
        VoiceFolder(
          id: VoiceFolder.uncategorizedId,
          name: '미분류',
          createdAt: DateTime(2026, 1, 1),
        ),
        VoiceFolder(
          id: 'folder-animal',
          name: '동물',
          createdAt: DateTime(2026, 1, 2),
        ),
        VoiceFolder(
          id: 'folder-friend',
          name: '친구',
          createdAt: DateTime(2026, 1, 2),
        ),
      ],
      jobs: seedVoiceJobs(),
    );
  }

  Map<String, dynamic> toJson() => {
    'folders': folders.map(_folderToJson).toList(),
    'jobs': jobs.map(_jobToJson).toList(),
  };

  static VoiceLibrarySnapshot fromJson(Map<String, dynamic> json) {
    final fl = (json['folders'] as List<dynamic>? ?? [])
        .map((e) => _folderFromJson(e as Map<String, dynamic>))
        .toList();
    final js = (json['jobs'] as List<dynamic>? ?? [])
        .map((e) => _jobFromJson(e as Map<String, dynamic>))
        .toList();
    return VoiceLibrarySnapshot(folders: fl, jobs: js);
  }

  static Map<String, dynamic> _folderToJson(VoiceFolder f) => {
    'id': f.id,
    'name': f.name,
    'createdAt': f.createdAt.toIso8601String(),
    'parentId': f.parentId,
  };

  static VoiceFolder _folderFromJson(Map<String, dynamic> m) => VoiceFolder(
    id: m['id'] as String,
    name: m['name'] as String,
    createdAt:
        DateTime.tryParse(m['createdAt'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0),
    parentId: m['parentId'] as String?,
  );

  static Map<String, dynamic> _jobToJson(VoiceJob j) => {
    'id': j.id,
    'fileName': j.fileName,
    'status': j.status.name,
    'createdAt': j.createdAt.toIso8601String(),
    'folderId': j.folderId,
    'ownershipId': j.ownershipId,
    'origin': j.origin.name,
  };

  static VoiceJob _jobFromJson(Map<String, dynamic> m) {
    final statusName = m['status'] as String? ?? 'uploaded';
    final status = VoiceJobStatus.values.firstWhere(
      (e) => e.name == statusName,
      orElse: () => VoiceJobStatus.uploaded,
    );
    final originName = m['origin'] as String? ?? VoiceOrigin.uploaded.name;
    final origin = VoiceOrigin.values.firstWhere(
      (e) => e.name == originName,
      orElse: () => VoiceOrigin.uploaded,
    );
    return VoiceJob(
      id: m['id'] as String,
      fileName: m['fileName'] as String,
      status: status,
      createdAt:
          DateTime.tryParse(m['createdAt'] as String? ?? '') ?? DateTime.now(),
      folderId: m['folderId'] as String? ?? VoiceFolder.uncategorizedId,
      ownershipId: (m['ownershipId'] as num?)?.toInt(),
      origin: origin,
    );
  }
}

class VoiceSynthesisResult {
  const VoiceSynthesisResult({
    required this.speechRequestId,
    required this.generatedAudioId,
    required this.streamUrl,
    required this.downloadUrl,
  });

  final int speechRequestId;
  final int generatedAudioId;
  final String streamUrl;
  final String downloadUrl;
}

class VoiceFolderCreateResult {
  const VoiceFolderCreateResult({
    required this.snapshot,
    required this.folderId,
  });

  final VoiceLibrarySnapshot snapshot;
  final String folderId;
}

class VoiceFolderContents {
  const VoiceFolderContents({
    required this.folders,
    required this.jobs,
    required this.totalVoiceCount,
  });

  final List<VoiceFolder> folders;
  final List<VoiceJob> jobs;
  final int totalVoiceCount;
}

/// 로컬 JSON 저장 — 폴더·음성 CRUD
class VoiceLibraryRepository {
  VoiceLibraryRepository({
    AuthService? authService,
    AuthenticatedApiClient? apiClient,
  }) : _authService = authService ?? AppServices.instance.authService,
       _api =
           apiClient ??
           AuthenticatedApiClient(
             authService: authService ?? AppServices.instance.authService,
           );

  final _uuid = const Uuid();
  final AuthService _authService;
  final AuthenticatedApiClient _api;

  Future<VoiceLibrarySnapshot> load() async {
    if (await _authService.hasStoredSession()) {
      try {
        return await _loadRemote();
      } catch (_) {
        // Fall back to local demo data so guest / offline browsing still works.
      }
    }
    return _loadLocal();
  }

  Future<VoiceLibrarySnapshot> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) {
      final seed = VoiceLibrarySnapshot.seed();
      await save(seed);
      return seed;
    }
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      var snap = VoiceLibrarySnapshot.fromJson(map);
      snap = _ensureUncategorized(snap);
      return snap;
    } catch (_) {
      final seed = VoiceLibrarySnapshot.seed();
      await save(seed);
      return seed;
    }
  }

  Future<VoiceLibrarySnapshot> _loadRemote() async {
    final foldersById = <String, VoiceFolder>{
      VoiceFolder.uncategorizedId: VoiceFolder(
        id: VoiceFolder.uncategorizedId,
        name: '미분류',
        createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      ),
    };
    final jobsById = <String, VoiceJob>{};
    final pendingScopeIds = <String?>[null];
    final visitedScopeKeys = <String>{};

    while (pendingScopeIds.isNotEmpty) {
      final scopeId = pendingScopeIds.removeLast();
      final scopeKey = scopeId ?? '__root__';
      if (!visitedScopeKeys.add(scopeKey)) continue;

      final contents = await _loadRemoteFolderContents(scopeId);
      for (final folder in contents.folders) {
        foldersById[folder.id] = folder;
        pendingScopeIds.add(folder.id);
      }
      for (final job in contents.jobs) {
        jobsById[job.id] = job;
      }
    }

    return _ensureUncategorized(
      VoiceLibrarySnapshot(
        folders: foldersById.values.toList(growable: false),
        jobs: jobsById.values.toList(growable: false),
      ),
    );
  }

  VoiceLibrarySnapshot _ensureUncategorized(VoiceLibrarySnapshot s) {
    final has = s.folders.any((f) => f.id == VoiceFolder.uncategorizedId);
    if (has) return s;
    return VoiceLibrarySnapshot(
      folders: [
        VoiceFolder(
          id: VoiceFolder.uncategorizedId,
          name: '미분류',
          createdAt: DateTime.now(),
        ),
        ...s.folders,
      ],
      jobs: s.jobs
          .map(
            (j) => j.folderId.isEmpty
                ? j.copyWith(folderId: VoiceFolder.uncategorizedId)
                : j,
          )
          .toList(),
    );
  }

  Future<void> save(VoiceLibrarySnapshot snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(snapshot.toJson()));
  }

  Future<VoiceLibrarySnapshot> refreshFolderContents(
    VoiceLibrarySnapshot current, {
    String? folderId,
  }) async {
    if (!await _authService.hasStoredSession()) {
      return current;
    }
    final normalizedScopeId = _normalizeParentFolderId(folderId);
    final contents = await _loadRemoteFolderContents(normalizedScopeId);
    return _mergeRemoteFolderContents(current, normalizedScopeId, contents);
  }

  Future<VoiceFolderCreateResult> createFolder(
    VoiceLibrarySnapshot current,
    String name, {
    String? parentFolderId,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('폴더 이름이 비었어요');
    }
    final normalizedParentId = _normalizeParentFolderId(parentFolderId);
    if (await _authService.hasStoredSession()) {
      final created = await _api.postJsonObject(
        '/voice-folders',
        body: <String, dynamic>{
          'name': trimmed,
          'parentFolderId': _serializeRemoteParentId(normalizedParentId),
        },
      );
      final snapshot = await _loadRemote();
      final folderId =
          _usableCreatedFolderId(created) ??
          _findCreatedFolder(snapshot, trimmed, normalizedParentId)?.id;
      if (folderId == null || folderId.isEmpty) {
        throw StateError('생성한 폴더 id를 찾을 수 없어요.');
      }
      return VoiceFolderCreateResult(snapshot: snapshot, folderId: folderId);
    }
    final folder = VoiceFolder(
      id: 'folder-${_uuid.v4()}',
      name: trimmed,
      createdAt: DateTime.now(),
      parentId: normalizedParentId,
    );
    final next = VoiceLibrarySnapshot(
      folders: [...current.folders, folder],
      jobs: current.jobs,
    );
    await save(next);
    return VoiceFolderCreateResult(snapshot: next, folderId: folder.id);
  }

  Future<VoiceLibrarySnapshot> renameFolder(
    VoiceLibrarySnapshot current,
    String folderId,
    String newName,
  ) async {
    if (await _authService.hasStoredSession()) {
      if (folderId == VoiceFolder.uncategorizedId) {
        throw StateError('미분류 폴더는 이름을 바꿀 수 없어요');
      }
      final trimmed = newName.trim();
      if (trimmed.isEmpty) throw ArgumentError('이름이 비었어요');
      final folder = _findFolder(current, folderId);
      await _api.putJsonObject(
        '/voice-folders/$folderId',
        body: <String, dynamic>{
          'name': trimmed,
          'parentFolderId': _serializeRemoteParentId(folder.parentId),
        },
      );
      return _loadRemote();
    }
    final trimmed = newName.trim();
    if (trimmed.isEmpty) throw ArgumentError('이름이 비었어요');
    final folders = current.folders
        .map(
          (f) => f.id == folderId
              ? VoiceFolder(
                  id: f.id,
                  name: trimmed,
                  createdAt: f.createdAt,
                  parentId: f.parentId,
                )
              : f,
        )
        .toList();
    final next = VoiceLibrarySnapshot(folders: folders, jobs: current.jobs);
    await save(next);
    return next;
  }

  /// 미분류는 삭제 불가. 해당 폴더 파일은 미분류로 이동.
  Future<VoiceLibrarySnapshot> deleteFolder(
    VoiceLibrarySnapshot current,
    String folderId,
  ) async {
    final hasChildren = current.folders.any((f) => f.parentId == folderId);
    if (hasChildren) {
      throw StateError('하위 폴더가 있으면 삭제할 수 없어요');
    }
    if (await _authService.hasStoredSession()) {
      if (folderId == VoiceFolder.uncategorizedId) {
        throw StateError('미분류 폴더는 삭제할 수 없어요');
      }
      await _api.deleteNoContent('/voice-folders/$folderId');
      return _loadRemote();
    }
    if (folderId == VoiceFolder.uncategorizedId) {
      throw StateError('미분류 폴더는 삭제할 수 없어요');
    }
    final folders = current.folders.where((f) => f.id != folderId).toList();
    final jobs = current.jobs
        .map(
          (j) => j.folderId == folderId
              ? j.copyWith(folderId: VoiceFolder.uncategorizedId)
              : j,
        )
        .toList();
    final next = VoiceLibrarySnapshot(folders: folders, jobs: jobs);
    await save(next);
    return next;
  }

  Future<VoiceLibrarySnapshot> addJob(
    VoiceLibrarySnapshot current,
    VoiceJob job,
  ) async {
    final next = VoiceLibrarySnapshot(
      folders: current.folders,
      jobs: [job, ...current.jobs],
    );
    await save(next);
    return next;
  }

  Future<VoiceLibrarySnapshot> uploadVoice(
    VoiceLibrarySnapshot current,
    VoiceUploadRequest request,
  ) async {
    if (await _authService.hasStoredSession()) {
      final created = await _api.postMultipartObject(
        '/voices/cloned-voice',
        queryParameters: <String, String?>{
          'name': request.name,
          if (request.description != null && request.description!.isNotEmpty)
            'description': request.description,
        },
        fields: <String, String>{
          'name': request.name,
          if (request.description != null && request.description!.isNotEmpty)
            'description': request.description!,
        },
        files: [
          MultipartPayloadFile(
            fieldName: 'files',
            filename: request.filename,
            bytes: request.bytes,
          ),
        ],
      );

      final voiceKey =
          created['voiceKey'] as String? ??
          created['externalVoiceId'] as String? ??
          '';
      if (voiceKey.isEmpty) {
        throw StateError('업로드 응답에 voiceKey가 없어요.');
      }

      if (request.folderId != VoiceFolder.uncategorizedId) {
        await _api.patchJsonList(
          '/voices/folder',
          body: <String, dynamic>{
            'externalVoiceIds': [voiceKey],
            'folderId': int.tryParse(request.folderId),
          },
        );
      }
      return _loadRemote();
    }

    final localJob = VoiceJob(
      id: 'job-${_uuid.v4()}',
      fileName: request.filename,
      status: VoiceJobStatus.uploaded,
      createdAt: DateTime.now(),
      folderId: request.folderId,
      origin: VoiceOrigin.uploaded,
    );
    return addJob(current, localJob);
  }

  Future<VoiceLibrarySnapshot> updateJob(
    VoiceLibrarySnapshot current,
    VoiceJob job,
  ) async {
    final jobs = current.jobs.map((j) => j.id == job.id ? job : j).toList();
    final next = VoiceLibrarySnapshot(folders: current.folders, jobs: jobs);
    await save(next);
    return next;
  }

  Future<VoiceLibrarySnapshot> deleteJob(
    VoiceLibrarySnapshot current,
    String jobId,
  ) async {
    if (await _authService.hasStoredSession()) {
      VoiceJob? target;
      for (final job in current.jobs) {
        if (job.id == jobId) {
          target = job;
          break;
        }
      }
      final ownershipId = target?.ownershipId;
      if (ownershipId == null) {
        throw StateError('삭제 대상 음성의 ownershipId가 없어요.');
      }
      await _api.deleteNoContent('/voices/$ownershipId');
      return _loadRemote();
    }
    final jobs = current.jobs.where((j) => j.id != jobId).toList();
    final next = VoiceLibrarySnapshot(folders: current.folders, jobs: jobs);
    await save(next);
    return next;
  }

  Future<VoiceSynthesisResult> synthesizeSpeech({
    required VoiceJob job,
    required String text,
  }) async {
    final ownershipId = job.ownershipId;
    if (ownershipId == null) {
      throw StateError('이 음성은 TTS에 필요한 ownershipId가 없어요.');
    }

    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('읽을 문장을 입력해 주세요.');
    }

    final response = await _api.postJsonObject(
      '/voices/$ownershipId/text-to-speech',
      body: <String, dynamic>{'text': trimmed},
    );

    return VoiceSynthesisResult(
      speechRequestId: (response['speechRequestId'] as num?)?.toInt() ?? 0,
      generatedAudioId: (response['generatedAudioId'] as num?)?.toInt() ?? 0,
      streamUrl: response['streamUrl'] as String? ?? '',
      downloadUrl: response['downloadUrl'] as String? ?? '',
    );
  }

  Future<Uint8List> fetchGeneratedAudioBytes(int generatedAudioId) async {
    return _api.getBytes('/voices/generated-audios/$generatedAudioId/stream');
  }

  Future<VoiceLibrarySnapshot> moveJobToFolder(
    VoiceLibrarySnapshot current,
    String jobId,
    String folderId,
  ) async {
    if (await _authService.hasStoredSession()) {
      final targetFolderId = folderId == VoiceFolder.uncategorizedId
          ? null
          : int.tryParse(folderId);
      await _api.patchJsonList(
        '/voices/folder',
        body: <String, dynamic>{
          'externalVoiceIds': [jobId],
          'folderId': targetFolderId,
        },
      );
      return _loadRemote();
    }
    final exists = current.folders.any((f) => f.id == folderId);
    if (!exists) throw ArgumentError('폴더를 찾을 수 없어요');
    final jobs = current.jobs
        .map((j) => j.id == jobId ? j.copyWith(folderId: folderId) : j)
        .toList();
    final next = VoiceLibrarySnapshot(folders: current.folders, jobs: jobs);
    await save(next);
    return next;
  }

  VoiceFolder _findFolder(VoiceLibrarySnapshot current, String folderId) {
    for (final folder in current.folders) {
      if (folder.id == folderId) return folder;
    }
    throw StateError('폴더를 찾을 수 없어요');
  }

  VoiceFolder? _findCreatedFolder(
    VoiceLibrarySnapshot snapshot,
    String name,
    String? parentId,
  ) {
    final matches =
        snapshot.folders
            .where((f) => f.name == name && f.parentId == parentId)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return matches.isEmpty ? null : matches.first;
  }

  String? _normalizeParentFolderId(String? folderId) {
    if (folderId == null || folderId.isEmpty) return null;
    if (folderId == VoiceFolder.uncategorizedId) return null;
    return folderId;
  }

  Object? _serializeRemoteParentId(String? parentId) {
    final normalized = _normalizeParentFolderId(parentId);
    if (normalized == null) return '';
    return normalized;
  }

  Future<VoiceFolderContents> _loadRemoteFolderContents(
    String? folderId,
  ) async {
    final response = await _api.getJsonObject(
      '/voice-folders/contents',
      queryParameters: <String, String?>{
        'parentId': _normalizeParentFolderId(folderId),
      },
    );
    return VoiceFolderContents(
      folders: _remoteFoldersFromJson(response['folders']),
      jobs: (response['voices'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(_remoteVoiceFromJson)
          .toList(growable: false),
      totalVoiceCount: (response['totalVoiceCount'] as num?)?.toInt() ?? 0,
    );
  }

  VoiceLibrarySnapshot _mergeRemoteFolderContents(
    VoiceLibrarySnapshot current,
    String? folderId,
    VoiceFolderContents contents,
  ) {
    final foldersById = <String, VoiceFolder>{
      for (final folder in current.folders)
        if (folder.parentId != folderId || folder.isUncategorized)
          folder.id: folder,
    };
    for (final folder in contents.folders) {
      foldersById[folder.id] = folder;
    }

    final jobsById = <String, VoiceJob>{
      for (final job in current.jobs)
        if (!_jobBelongsToScope(job, folderId)) job.id: job,
    };
    for (final job in contents.jobs) {
      jobsById[job.id] = job;
    }

    return _ensureUncategorized(
      VoiceLibrarySnapshot(
        folders: foldersById.values.toList(growable: false),
        jobs: jobsById.values.toList(growable: false),
      ),
    );
  }

  bool _jobBelongsToScope(VoiceJob job, String? folderId) {
    final normalizedScopeId = _normalizeParentFolderId(folderId);
    if (normalizedScopeId == null) {
      return job.folderId == VoiceFolder.uncategorizedId;
    }
    return job.folderId == normalizedScopeId;
  }
}

List<VoiceFolder> _remoteFoldersFromJson(dynamic raw, {String? parentId}) {
  if (raw is! List<dynamic>) return const <VoiceFolder>[];

  final folders = <VoiceFolder>[];
  for (final item in raw.whereType<Map<String, dynamic>>()) {
    final folder = _remoteFolderFromJson(item, fallbackParentId: parentId);
    folders.add(folder);
    final nested =
        item['children'] ??
        item['childFolders'] ??
        item['subFolders'] ??
        item['subfolders'];
    folders.addAll(_remoteFoldersFromJson(nested, parentId: folder.id));
  }
  return folders;
}

VoiceFolder _remoteFolderFromJson(
  Map<String, dynamic> json, {
  String? fallbackParentId,
}) {
  final rawParent = _normalizeRemoteParentId(
    json['parentFolderId'] ??
        json['parentId'] ??
        (json['parentFolder'] as Map<String, dynamic>?)?['id'] ??
        (json['parent'] as Map<String, dynamic>?)?['id'],
  );
  return VoiceFolder(
    id: _extractRemoteFolderId(json) ?? '',
    name: json['name'] as String? ?? '폴더',
    createdAt:
        DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    parentId: rawParent ?? fallbackParentId,
  );
}

String? _extractRemoteFolderId(Map<String, dynamic> json) {
  final raw = json['id'] ?? json['folderId'];
  if (raw == null) return null;
  return '$raw';
}

String? _usableCreatedFolderId(Map<String, dynamic> json) {
  final id = _extractRemoteFolderId(json);
  if (id == null || id.isEmpty || id == '0') return null;
  return id;
}

String? _normalizeRemoteParentId(Object? rawParentId) {
  if (rawParentId == null) return null;
  if (rawParentId is String) {
    final trimmed = rawParentId.trim();
    if (trimmed.isEmpty || trimmed == '0' || trimmed.toLowerCase() == 'null') {
      return null;
    }
    return trimmed;
  }
  if (rawParentId is num && rawParentId == 0) {
    return null;
  }
  return '$rawParentId';
}

String _normalizeRemoteVoiceFolderId(Object? rawFolderId) {
  final normalized = _normalizeRemoteParentId(rawFolderId);
  return normalized ?? VoiceFolder.uncategorizedId;
}

VoiceJob _remoteVoiceFromJson(Map<String, dynamic> json) {
  final acquiredBy = (json['acquiredBy'] as String? ?? '').toUpperCase();
  return VoiceJob(
    id: json['voiceKey'] as String? ?? json['externalVoiceId'] as String? ?? '',
    fileName: json['title'] as String? ?? '이름 없는 음성',
    status: VoiceJobStatus.completed,
    createdAt:
        DateTime.tryParse(json['acquiredAt'] as String? ?? '') ??
        DateTime.now(),
    folderId: _normalizeRemoteVoiceFolderId(json['folderId']),
    ownershipId: (json['ownershipId'] as num?)?.toInt(),
    origin: switch (acquiredBy) {
      'CREATED' => VoiceOrigin.uploaded,
      'ROOM_SHARED' => VoiceOrigin.sharedRoom,
      _ => VoiceOrigin.purchased,
    },
  );
}
