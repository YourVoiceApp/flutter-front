import 'dart:convert';
<<<<<<< Updated upstream
=======
import 'dart:typed_data';
>>>>>>> Stashed changes

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

<<<<<<< Updated upstream
import '../domain/voice_folder.dart';
import '../domain/voice_job.dart';
=======
import '../../../app/services/app_services.dart';
import '../../../app/services/authenticated_api_client.dart';
import '../../auth/data/auth_service.dart';
import '../domain/voice_folder.dart';
import '../domain/voice_job.dart';
import '../domain/voice_upload_request.dart';
>>>>>>> Stashed changes

const _prefsKey = 'voice_library_v1';

class VoiceLibrarySnapshot {
<<<<<<< Updated upstream
  const VoiceLibrarySnapshot({
    required this.folders,
    required this.jobs,
  });
=======
  const VoiceLibrarySnapshot({required this.folders, required this.jobs});
>>>>>>> Stashed changes

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
<<<<<<< Updated upstream
        'folders': folders.map(_folderToJson).toList(),
        'jobs': jobs.map(_jobToJson).toList(),
      };
=======
    'folders': folders.map(_folderToJson).toList(),
    'jobs': jobs.map(_jobToJson).toList(),
  };
>>>>>>> Stashed changes

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
<<<<<<< Updated upstream
        'id': f.id,
        'name': f.name,
        'createdAt': f.createdAt.toIso8601String(),
      };

  static VoiceFolder _folderFromJson(Map<String, dynamic> m) => VoiceFolder(
        id: m['id'] as String,
        name: m['name'] as String,
        createdAt: DateTime.tryParse(m['createdAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );

  static Map<String, dynamic> _jobToJson(VoiceJob j) => {
        'id': j.id,
        'fileName': j.fileName,
        'status': j.status.name,
        'createdAt': j.createdAt.toIso8601String(),
        'folderId': j.folderId,
        'origin': j.origin.name,
      };
=======
    'id': f.id,
    'name': f.name,
    'createdAt': f.createdAt.toIso8601String(),
  };

  static VoiceFolder _folderFromJson(Map<String, dynamic> m) => VoiceFolder(
    id: m['id'] as String,
    name: m['name'] as String,
    createdAt:
        DateTime.tryParse(m['createdAt'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0),
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
>>>>>>> Stashed changes

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
<<<<<<< Updated upstream
      createdAt: DateTime.tryParse(m['createdAt'] as String? ?? '') ??
          DateTime.now(),
      folderId: m['folderId'] as String? ?? VoiceFolder.uncategorizedId,
=======
      createdAt:
          DateTime.tryParse(m['createdAt'] as String? ?? '') ?? DateTime.now(),
      folderId: m['folderId'] as String? ?? VoiceFolder.uncategorizedId,
      ownershipId: (m['ownershipId'] as num?)?.toInt(),
>>>>>>> Stashed changes
      origin: origin,
    );
  }
}

<<<<<<< Updated upstream
/// 로컬 JSON 저장 — 폴더·음성 CRUD
class VoiceLibraryRepository {
  VoiceLibraryRepository();

  final _uuid = const Uuid();

  Future<VoiceLibrarySnapshot> load() async {
=======
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
>>>>>>> Stashed changes
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

<<<<<<< Updated upstream
=======
  Future<VoiceLibrarySnapshot> _loadRemote() async {
    final contents = await _api.getJsonObject('/voice-folders/contents');
    final assignedVoices = await _api.getJsonList('/voices');
    final unassignedVoices = await _api.getJsonList('/voices/unassigned');

    final folders = <VoiceFolder>[
      VoiceFolder(
        id: VoiceFolder.uncategorizedId,
        name: '미분류',
        createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      ),
      ...((contents['folders'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(_remoteFolderFromJson)),
    ];

    final mergedById = <String, VoiceJob>{};
    for (final raw in [...assignedVoices, ...unassignedVoices]) {
      if (raw is! Map<String, dynamic>) continue;
      final job = _remoteVoiceFromJson(raw);
      mergedById[job.id] = job;
    }

    return VoiceLibrarySnapshot(
      folders: folders,
      jobs: mergedById.values.toList(growable: false),
    );
  }

>>>>>>> Stashed changes
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

  Future<VoiceLibrarySnapshot> createFolder(
    VoiceLibrarySnapshot current,
    String name,
  ) async {
<<<<<<< Updated upstream
=======
    if (await _authService.hasStoredSession()) {
      final trimmed = name.trim();
      if (trimmed.isEmpty) {
        throw ArgumentError('폴더 이름이 비었어요');
      }
      await _api.postJsonObject(
        '/voice-folders',
        body: <String, dynamic>{'name': trimmed, 'parentFolderId': null},
      );
      return _loadRemote();
    }
>>>>>>> Stashed changes
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('폴더 이름이 비었어요');
    }
    final folder = VoiceFolder(
      id: 'folder-${_uuid.v4()}',
      name: trimmed,
      createdAt: DateTime.now(),
    );
    final next = VoiceLibrarySnapshot(
      folders: [...current.folders, folder],
      jobs: current.jobs,
    );
    await save(next);
    return next;
  }

  Future<VoiceLibrarySnapshot> renameFolder(
    VoiceLibrarySnapshot current,
    String folderId,
    String newName,
  ) async {
<<<<<<< Updated upstream
=======
    if (await _authService.hasStoredSession()) {
      if (folderId == VoiceFolder.uncategorizedId) {
        throw StateError('미분류 폴더는 이름을 바꿀 수 없어요');
      }
      final trimmed = newName.trim();
      if (trimmed.isEmpty) throw ArgumentError('이름이 비었어요');
      await _api.putJsonObject(
        '/voice-folders/$folderId',
        body: <String, dynamic>{'name': trimmed, 'parentFolderId': null},
      );
      return _loadRemote();
    }
>>>>>>> Stashed changes
    final trimmed = newName.trim();
    if (trimmed.isEmpty) throw ArgumentError('이름이 비었어요');
    final folders = current.folders
        .map(
          (f) => f.id == folderId
              ? VoiceFolder(id: f.id, name: trimmed, createdAt: f.createdAt)
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
<<<<<<< Updated upstream
    if (folderId == VoiceFolder.uncategorizedId) {
      throw StateError('미분류 폴더는 삭제할 수 없어요');
    }
    final folders =
        current.folders.where((f) => f.id != folderId).toList();
=======
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
>>>>>>> Stashed changes
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

<<<<<<< Updated upstream
=======
  Future<VoiceLibrarySnapshot> uploadVoice(
    VoiceLibrarySnapshot current,
    VoiceUploadRequest request,
  ) async {
    if (await _authService.hasStoredSession()) {
      final created = await _api.postMultipartObject(
        '/voices/cloned-voice',
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

>>>>>>> Stashed changes
  Future<VoiceLibrarySnapshot> updateJob(
    VoiceLibrarySnapshot current,
    VoiceJob job,
  ) async {
<<<<<<< Updated upstream
    final jobs =
        current.jobs.map((j) => j.id == job.id ? job : j).toList();
=======
    final jobs = current.jobs.map((j) => j.id == job.id ? job : j).toList();
>>>>>>> Stashed changes
    final next = VoiceLibrarySnapshot(folders: current.folders, jobs: jobs);
    await save(next);
    return next;
  }

  Future<VoiceLibrarySnapshot> deleteJob(
    VoiceLibrarySnapshot current,
    String jobId,
  ) async {
<<<<<<< Updated upstream
=======
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
>>>>>>> Stashed changes
    final jobs = current.jobs.where((j) => j.id != jobId).toList();
    final next = VoiceLibrarySnapshot(folders: current.folders, jobs: jobs);
    await save(next);
    return next;
  }

<<<<<<< Updated upstream
=======
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

>>>>>>> Stashed changes
  Future<VoiceLibrarySnapshot> moveJobToFolder(
    VoiceLibrarySnapshot current,
    String jobId,
    String folderId,
  ) async {
<<<<<<< Updated upstream
=======
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
>>>>>>> Stashed changes
    final exists = current.folders.any((f) => f.id == folderId);
    if (!exists) throw ArgumentError('폴더를 찾을 수 없어요');
    final jobs = current.jobs
        .map((j) => j.id == jobId ? j.copyWith(folderId: folderId) : j)
        .toList();
    final next = VoiceLibrarySnapshot(folders: current.folders, jobs: jobs);
    await save(next);
    return next;
  }
}
<<<<<<< Updated upstream
=======

VoiceFolder _remoteFolderFromJson(Map<String, dynamic> json) {
  return VoiceFolder(
    id: '${json['id']}',
    name: json['name'] as String? ?? '폴더',
    createdAt:
        DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
  );
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
    folderId: json['folderId'] == null
        ? VoiceFolder.uncategorizedId
        : '${json['folderId']}',
    ownershipId: (json['ownershipId'] as num?)?.toInt(),
    origin: switch (acquiredBy) {
      'CREATED' => VoiceOrigin.uploaded,
      'ROOM_SHARED' => VoiceOrigin.sharedRoom,
      _ => VoiceOrigin.purchased,
    },
  );
}
>>>>>>> Stashed changes
