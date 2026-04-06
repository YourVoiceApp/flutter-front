import 'voice_folder.dart';

/// UI 데모용 — 음성 파일 하나의 학습 파이프라인
enum VoiceJobStatus {
  uploaded,
  training,
  completed,
}

extension VoiceJobStatusX on VoiceJobStatus {
  String get label {
    switch (this) {
      case VoiceJobStatus.uploaded:
        return '업로드됨';
      case VoiceJobStatus.training:
        return '학습 중';
      case VoiceJobStatus.completed:
        return '완료';
    }
  }
}

class VoiceJob {
  const VoiceJob({
    required this.id,
    required this.fileName,
    required this.status,
    required this.createdAt,
    required this.folderId,
  });

  final String id;
  final String fileName;
  final VoiceJobStatus status;

  /// 업로드(또는 등록) 시각 — 최신순 정렬·날짜 필터에 사용
  final DateTime createdAt;

  /// [VoiceFolder] id
  final String folderId;

  VoiceJob copyWith({
    VoiceJobStatus? status,
    DateTime? createdAt,
    String? folderId,
    String? fileName,
  }) {
    return VoiceJob(
      id: id,
      fileName: fileName ?? this.fileName,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      folderId: folderId ?? this.folderId,
    );
  }
}

/// 첫 실행 시 저장소 시드용 (개발·데모)
List<VoiceJob> seedVoiceJobs() => [
      VoiceJob(
        id: '1',
        fileName: '엄마_안내_01.m4a',
        status: VoiceJobStatus.completed,
        createdAt: DateTime(2026, 4, 1, 10, 30),
        folderId: VoiceFolder.uncategorizedId,
      ),
      VoiceJob(
        id: '2',
        fileName: '녹음_20260405.wav',
        status: VoiceJobStatus.training,
        createdAt: DateTime(2026, 4, 5, 9, 0),
        folderId: 'folder-animal',
      ),
      VoiceJob(
        id: '3',
        fileName: '새녹음_clip.aac',
        status: VoiceJobStatus.uploaded,
        createdAt: DateTime(2026, 4, 5, 14, 20),
        folderId: 'folder-friend',
      ),
    ];

/// 목록 화면용 — 상태로 걸러보기
enum VoiceJobListFilter {
  all,
  uploaded,
  training,
  completed,
}

extension VoiceJobListFilterX on VoiceJobListFilter {
  String get label {
    switch (this) {
      case VoiceJobListFilter.all:
        return '전체';
      case VoiceJobListFilter.uploaded:
        return VoiceJobStatus.uploaded.label;
      case VoiceJobListFilter.training:
        return VoiceJobStatus.training.label;
      case VoiceJobListFilter.completed:
        return VoiceJobStatus.completed.label;
    }
  }

  bool matches(VoiceJob job) {
    switch (this) {
      case VoiceJobListFilter.all:
        return true;
      case VoiceJobListFilter.uploaded:
        return job.status == VoiceJobStatus.uploaded;
      case VoiceJobListFilter.training:
        return job.status == VoiceJobStatus.training;
      case VoiceJobListFilter.completed:
        return job.status == VoiceJobStatus.completed;
    }
  }
}

/// 정렬 — 최근에 올린 순이 기본
enum VoiceJobListSort {
  newest,
  nameAsc,
}

extension VoiceJobListSortX on VoiceJobListSort {
  String get label {
    switch (this) {
      case VoiceJobListSort.newest:
        return '최신순';
      case VoiceJobListSort.nameAsc:
        return '이름순';
    }
  }
}
