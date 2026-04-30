import 'package:flutter/material.dart';

import '../../../../app/theme/yeolpumta_theme.dart';
import '../../domain/voice_job.dart';
import '../../../shared/presentation/widgets/voice_cute_leading_art.dart';

/// 출처별 색·아이콘 (목록·마이페이지 공통)
class VoiceOriginStyle {
  const VoiceOriginStyle({
    required this.tint,
    required this.accent,
    required this.icon,
  });

  final Color tint;
  final Color accent;
  final IconData icon;

  static VoiceOriginStyle of(VoiceOrigin o) {
    switch (o) {
      case VoiceOrigin.uploaded:
        return const VoiceOriginStyle(
          tint: YeolpumtaTheme.accentSoft,
          accent: YeolpumtaTheme.accent,
          icon: Icons.mic_rounded,
        );
      case VoiceOrigin.sharedRoom:
        return VoiceOriginStyle(
          tint: const Color(0xFFFFF4E5),
          accent: const Color(0xFFFF9500),
          icon: Icons.groups_rounded,
        );
      case VoiceOrigin.purchased:
        return VoiceOriginStyle(
          tint: const Color(0xFFE8F4FF),
          accent: const Color(0xFF007AFF),
          icon: Icons.shopping_bag_outlined,
        );
    }
  }
}

class VoiceOriginChip extends StatelessWidget {
  const VoiceOriginChip({super.key, required this.origin});

  final VoiceOrigin origin;

  @override
  Widget build(BuildContext context) {
    final s = VoiceOriginStyle.of(origin);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: s.tint,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: s.accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          VoiceOriginCuteGlyph(origin: origin, size: 13, color: s.accent),
          const SizedBox(width: 4),
          Text(
            origin.shortLabel,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: s.accent,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// 음성 탭·마이페이지 공통 카드
class VoiceJobListCard extends StatelessWidget {
  const VoiceJobListCard({
    super.key,
    required this.job,
    required this.folderLabel,
    required this.showFolderLine,
    required this.onAdvance,
    required this.onDelete,
    required this.onMove,
    required this.onRename,
    this.showMenu = true,
    this.onCardTap,
  });

  final VoiceJob job;
  final String folderLabel;
  final bool showFolderLine;
  final VoidCallback onAdvance;
  final VoidCallback onDelete;
  final VoidCallback onMove;
  final VoidCallback onRename;
  final bool showMenu;

  /// 카드 본문 탭(메뉴·다음 단계 버튼과 별개)
  final VoidCallback? onCardTap;

  @override
  Widget build(BuildContext context) {
    final status = job.status;
    final originStyle = VoiceOriginStyle.of(job.origin);
    final (IconData stIcon, Color stColor) = switch (status) {
      VoiceJobStatus.uploaded => (
          Icons.cloud_upload_outlined,
          const Color(0xFF8E8E93),
        ),
      VoiceJobStatus.training => (
          Icons.auto_awesome_motion_rounded,
          YeolpumtaTheme.accent,
        ),
      VoiceJobStatus.completed => (
          Icons.check_circle_rounded,
          const Color(0xFF34C759),
        ),
    };

    return Material(
      color: YeolpumtaTheme.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onCardTap,
        child: Stack(
          children: [
            Positioned(
              right: -6,
              bottom: -10,
              child: const VoiceCardSoftDecoration(),
            ),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 5,
                    color: originStyle.accent,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 14, 8, 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          VoiceCuteLeadingAvatar(origin: job.origin),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        job.fileName,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: YeolpumtaTheme.textPrimary,
                                          height: 1.25,
                                        ),
                                      ),
                                    ),
                                    Icon(stIcon, color: stColor, size: 20),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    VoiceOriginChip(origin: job.origin),
                                    _StatusPill(status: status),
                                  ],
                                ),
                                if (showFolderLine) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.folder_outlined,
                                        size: 14,
                                        color: YeolpumtaTheme.textSecondary
                                            .withValues(alpha: 0.85),
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          folderLabel,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: YeolpumtaTheme.textSecondary
                                                .withValues(alpha: 0.92),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    if (status != VoiceJobStatus.completed) ...[
                                      TextButton(
                                        onPressed: onAdvance,
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          foregroundColor: YeolpumtaTheme.accent,
                                        ),
                                        child: const Text(
                                          '다음 단계(데모)',
                                          style: TextStyle(fontSize: 13),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                if (status == VoiceJobStatus.training) ...[
                                  const SizedBox(height: 10),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: 0.62,
                                      minHeight: 4,
                                      backgroundColor: YeolpumtaTheme.divider,
                                      color: YeolpumtaTheme.accent,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '학습 진행 중… (UI만 표시)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: YeolpumtaTheme.textSecondary
                                          .withValues(alpha: 0.9),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (showMenu)
                            PopupMenuButton<String>(
                              icon: const Icon(
                                Icons.more_horiz_rounded,
                                color: YeolpumtaTheme.textSecondary,
                              ),
                              onSelected: (v) {
                                if (v == 'rename') onRename();
                                if (v == 'move') onMove();
                                if (v == 'delete') onDelete();
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(
                                  value: 'rename',
                                  child: Text('이름 바꾸기'),
                                ),
                                PopupMenuItem(
                                  value: 'move',
                                  child: Text('다른 폴더로'),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text(
                                    '삭제',
                                    style: TextStyle(color: Colors.redAccent),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final VoiceJobStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: YeolpumtaTheme.bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: YeolpumtaTheme.textSecondary,
        ),
      ),
    );
  }
}
