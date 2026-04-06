import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../domain/voice_folder.dart';
import '../domain/voice_job.dart';

const _prefsKey = 'voice_library_v1';

class VoiceLibrarySnapshot {
  const VoiceLibrarySnapshot({
    required this.folders,
    required this.jobs,
  });

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
      };

  static VoiceJob _jobFromJson(Map<String, dynamic> m) {
    final statusName = m['status'] as String? ?? 'uploaded';
    final status = VoiceJobStatus.values.firstWhere(
      (e) => e.name == statusName,
      orElse: () => VoiceJobStatus.uploaded,
    );
    return VoiceJob(
      id: m['id'] as String,
      fileName: m['fileName'] as String,
      status: status,
      createdAt: DateTime.tryParse(m['createdAt'] as String? ?? '') ??
          DateTime.now(),
      folderId: m['folderId'] as String? ?? VoiceFolder.uncategorizedId,
    );
  }
}

/// 로컬 JSON 저장 — 폴더·음성 CRUD
class VoiceLibraryRepository {
  VoiceLibraryRepository();

  final _uuid = const Uuid();

  Future<VoiceLibrarySnapshot> load() async {
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
    if (folderId == VoiceFolder.uncategorizedId) {
      throw StateError('미분류 폴더는 삭제할 수 없어요');
    }
    final folders =
        current.folders.where((f) => f.id != folderId).toList();
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

  Future<VoiceLibrarySnapshot> updateJob(
    VoiceLibrarySnapshot current,
    VoiceJob job,
  ) async {
    final jobs =
        current.jobs.map((j) => j.id == job.id ? job : j).toList();
    final next = VoiceLibrarySnapshot(folders: current.folders, jobs: jobs);
    await save(next);
    return next;
  }

  Future<VoiceLibrarySnapshot> deleteJob(
    VoiceLibrarySnapshot current,
    String jobId,
  ) async {
    final jobs = current.jobs.where((j) => j.id != jobId).toList();
    final next = VoiceLibrarySnapshot(folders: current.folders, jobs: jobs);
    await save(next);
    return next;
  }

  Future<VoiceLibrarySnapshot> moveJobToFolder(
    VoiceLibrarySnapshot current,
    String jobId,
    String folderId,
  ) async {
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
