import 'voice_folder.dart';

/// 음성이 라이브러리에 들어온 경로 (표시·필터용)
enum VoiceOrigin {
  /// 직접 업로드·학습 파이프라인
  uploaded,

  /// 함께(공유방)에서 받음
  sharedRoom,

  /// 마켓 등에서 구매
  purchased,
}

extension VoiceOriginX on VoiceOrigin {
  String get label {
    switch (this) {
      case VoiceOrigin.uploaded:
        return '내 업로드';
      case VoiceOrigin.sharedRoom:
        return '공유방';
      case VoiceOrigin.purchased:
        return '구매';
    }
  }

  String get shortLabel {
    switch (this) {
      case VoiceOrigin.uploaded:
        return '업로드';
      case VoiceOrigin.sharedRoom:
        return '공유';
      case VoiceOrigin.purchased:
        return '구매';
    }
  }
}

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
<<<<<<< Updated upstream
=======
    this.ownershipId,
>>>>>>> Stashed changes
    this.origin = VoiceOrigin.uploaded,
  });

  final String id;
  final String fileName;
  final VoiceJobStatus status;

  /// 업로드(또는 등록) 시각 — 최신순 정렬·날짜 필터에 사용
  final DateTime createdAt;

  /// [VoiceFolder] id
  final String folderId;

<<<<<<< Updated upstream
=======
  /// Backend ownership id used by delete / TTS APIs.
  final int? ownershipId;

>>>>>>> Stashed changes
  /// 획득 경로 — 마이페이지·목록 배지
  final VoiceOrigin origin;

  VoiceJob copyWith({
    VoiceJobStatus? status,
    DateTime? createdAt,
    String? folderId,
    String? fileName,
<<<<<<< Updated upstream
=======
    int? ownershipId,
>>>>>>> Stashed changes
    VoiceOrigin? origin,
  }) {
    return VoiceJob(
      id: id,
      fileName: fileName ?? this.fileName,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      folderId: folderId ?? this.folderId,
<<<<<<< Updated upstream
=======
      ownershipId: ownershipId ?? this.ownershipId,
>>>>>>> Stashed changes
      origin: origin ?? this.origin,
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
        origin: VoiceOrigin.uploaded,
      ),
      VoiceJob(
        id: '2',
        fileName: '녹음_20260405.wav',
        status: VoiceJobStatus.training,
        createdAt: DateTime(2026, 4, 5, 9, 0),
        folderId: 'folder-animal',
        origin: VoiceOrigin.sharedRoom,
      ),
      VoiceJob(
        id: '3',
        fileName: '새녹음_clip.aac',
        status: VoiceJobStatus.uploaded,
        createdAt: DateTime(2026, 4, 5, 14, 20),
        folderId: 'folder-friend',
        origin: VoiceOrigin.purchased,
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
