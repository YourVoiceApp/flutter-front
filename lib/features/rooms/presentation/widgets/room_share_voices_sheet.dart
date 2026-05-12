import 'package:flutter/material.dart';

import '../../../../app/theme/yeolpumta_theme.dart';
import '../../../shared/presentation/widgets/voice_cute_leading_art.dart';
import '../../../voices/domain/voice_job.dart';
import '../../data/room_repository.dart';
import '../../domain/room.dart';

/// 방 공유: 권한 + 음성별「공유할 이름 변경」블록 (기본값은 라이브러리 파일명과 동일).
Future<Room?> showRoomShareVoicesSheet({
  required BuildContext context,
  required Room room,
  required List<VoiceJob> myVoices,
  required RoomRepository roomRepository,
}) {
  return showModalBottomSheet<Room?>(
    context: context,
    isScrollControlled: true,
    backgroundColor: YeolpumtaTheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _RoomShareVoicesSheetBody(
      room: room,
      myVoices: myVoices,
      roomRepository: roomRepository,
    ),
  );
}

class _RoomShareVoicesSheetBody extends StatefulWidget {
  const _RoomShareVoicesSheetBody({
    required this.room,
    required this.myVoices,
    required this.roomRepository,
  });

  final Room room;
  final List<VoiceJob> myVoices;
  final RoomRepository roomRepository;

  @override
  State<_RoomShareVoicesSheetBody> createState() =>
      _RoomShareVoicesSheetBodyState();
}

class _RoomShareVoicesSheetBodyState extends State<_RoomShareVoicesSheetBody> {
  late final Set<String> _chosen;
  late final Set<String> _initiallyShared;
  late RoomVoiceAccessScope _shareAccessScope;
  late final Map<String, TextEditingController> _titleCtrls;

  @override
  void initState() {
    super.initState();
    _initiallyShared = {
      for (final v in widget.room.sharedVoices) v.externalVoiceId,
    };
    _chosen = {..._initiallyShared};

    if (widget.room.sharedVoices.isNotEmpty) {
      final scopes = widget.room.sharedVoices.map((v) => v.accessScope).toSet();
      if (scopes.length == 1) {
        _shareAccessScope = scopes.first;
      } else {
        _shareAccessScope = RoomVoiceAccessScope.listenOnly;
      }
    } else {
      _shareAccessScope = RoomVoiceAccessScope.listenOnly;
    }

    final serverTitleByVoice = {
      for (final s in widget.room.sharedVoices) s.externalVoiceId: s.voiceTitle,
    };
    _titleCtrls = {};
    for (final v in widget.myVoices) {
      final fromServer = serverTitleByVoice[v.id];
      final initial = (fromServer != null && fromServer.trim().isNotEmpty)
          ? fromServer
          : v.fileName;
      _titleCtrls[v.id] = TextEditingController(text: initial);
    }
  }

  @override
  void dispose() {
    for (final c in _titleCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Map<String, String> _titlesForSelected() {
    return {for (final id in _chosen) id: _titleCtrls[id]?.text.trim() ?? ''};
  }

  int get _pendingUnshareCount =>
      _initiallyShared.where((id) => !_chosen.contains(id)).length;

  Future<bool> _confirmUnshare(VoiceJob voice) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: YeolpumtaTheme.surface,
            surfaceTintColor: Colors.transparent,
            title: Text(
              '공유를 해제할까요?',
              style: TextStyle(
                color: YeolpumtaTheme.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            content: Text(
              '「${voice.fileName}」 음성을 이 방에서 더 이상 사용할 수 없게 됩니다. '
              '이미 내 음성에 추가한 사람의 보유 항목은 유지될 수 있어요.',
              style: TextStyle(
                color: YeolpumtaTheme.textSecondary,
                height: 1.45,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  '취소',
                  style: TextStyle(color: YeolpumtaTheme.accent),
                ),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                ),
                child: const Text('공유 해제'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _setVoiceSelected(VoiceJob voice, bool selected) async {
    if (selected) {
      setState(() => _chosen.add(voice.id));
      return;
    }

    if (_initiallyShared.contains(voice.id)) {
      final ok = await _confirmUnshare(voice);
      if (!ok || !mounted) return;
    }

    setState(() => _chosen.remove(voice.id));
  }

  Future<void> _apply() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final updated = await widget.roomRepository.syncSharedVoices(
        room: widget.room,
        selectedVoiceIds: _chosen,
        accessScopeForSelection: _shareAccessScope,
        shareDisplayTitlesByExternalVoiceId: _titlesForSelected(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(updated);
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final screenH = MediaQuery.sizeOf(context).height;
    // 키보드가 올라오면 예산을 줄이고, 고정 높이로 Expanded가 동작하게 함.
    final sheetHeight = (screenH * 0.92 - viewInsets.bottom).clamp(
      260.0,
      screenH,
    );

    return AnimatedPadding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: SizedBox(
        height: sheetHeight,
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: YeolpumtaTheme.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '음성을 골라 이 방에 공유해요.',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: YeolpumtaTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '체크하면 아래에 「공유할 음성 이름 변경」칸이 열려요. '
                '그대로 두거나 고쳐서 방 사람에게 보여 줄 이름만 정하면 돼요. '
                '칸을 비우면 내 라이브러리에 있는 이름이 그대로 가요.',
                style: TextStyle(
                  color: YeolpumtaTheme.textSecondary,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                '공유 권한',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: YeolpumtaTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<RoomVoiceAccessScope>(
                style: SegmentedButton.styleFrom(
                  backgroundColor: YeolpumtaTheme.iconMutedBg,
                  selectedBackgroundColor: YeolpumtaTheme.accentSoft,
                  selectedForegroundColor: YeolpumtaTheme.accent,
                  foregroundColor: YeolpumtaTheme.textPrimary,
                  side: const BorderSide(color: YeolpumtaTheme.outline),
                ),
                segments: const [
                  ButtonSegment(
                    value: RoomVoiceAccessScope.listenOnly,
                    label: Text('듣기만'),
                    icon: Icon(Icons.hearing_rounded, size: 18),
                  ),
                  ButtonSegment(
                    value: RoomVoiceAccessScope.downloadAllowed,
                    label: Text('내려받기'),
                    icon: Icon(Icons.download_rounded, size: 18),
                  ),
                ],
                selected: {_shareAccessScope},
                onSelectionChanged: (s) {
                  if (s.isEmpty) return;
                  setState(() => _shareAccessScope = s.first);
                },
              ),
              const SizedBox(height: 4),
              Text(
                '선택한 공유에 같은 권한이 적용돼요.',
                style: TextStyle(
                  color: YeolpumtaTheme.textSecondary,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
              if (_pendingUnshareCount > 0) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade100),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: Colors.red.shade700,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '공유 해제 예정 $_pendingUnshareCount개가 있어요. 아래 버튼을 누르면 방 공유 목록에서 삭제됩니다.',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 12,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    for (final v in widget.myVoices)
                      _ShareVoiceRow(
                        job: v,
                        selected: _chosen.contains(v.id),
                        wasShared: _initiallyShared.contains(v.id),
                        titleCtrl: _titleCtrls[v.id]!,
                        onToggle: (on) => _setVoiceSelected(v, on),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _apply,
                style: FilledButton.styleFrom(
                  backgroundColor: YeolpumtaTheme.accent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  _pendingUnshareCount > 0 ? '공유 해제 포함해 반영' : '이 방에 반영',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShareVoiceRow extends StatelessWidget {
  const _ShareVoiceRow({
    required this.job,
    required this.selected,
    required this.wasShared,
    required this.titleCtrl,
    required this.onToggle,
  });

  final VoiceJob job;
  final bool selected;
  final bool wasShared;
  final TextEditingController titleCtrl;
  final Future<void> Function(bool selected) onToggle;

  @override
  Widget build(BuildContext context) {
    final markedForRemoval = wasShared && !selected;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: YeolpumtaTheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: markedForRemoval
              ? Colors.red.shade200
              : YeolpumtaTheme.outline,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CheckboxListTile(
              value: selected,
              dense: true,
              activeColor: YeolpumtaTheme.accent,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onChanged: (c) {
                onToggle(c == true);
              },
              title: Text(
                job.fileName,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: YeolpumtaTheme.textPrimary,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.origin.label,
                    style: TextStyle(
                      color: YeolpumtaTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  if (wasShared && selected) ...[
                    const SizedBox(height: 6),
                    Text(
                      '현재 이 방에 공유 중이에요',
                      style: TextStyle(
                        color: YeolpumtaTheme.accent.withValues(alpha: 0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (markedForRemoval) ...[
                    const SizedBox(height: 6),
                    Text(
                      '공유 해제 예정 · 반영하면 이 방에서 사라져요',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  if (!selected) ...[
                    const SizedBox(height: 6),
                    Text(
                      wasShared ? '다시 체크하면 해제를 취소해요' : '체크하면 공유할 이름을 바꿀 수 있어요',
                      style: TextStyle(
                        color: wasShared
                            ? Colors.red.shade700
                            : YeolpumtaTheme.accent.withValues(alpha: 0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
              secondary: VoiceCuteLeadingAvatar(
                origin: job.origin,
                size: 48,
                borderRadius: 14,
              ),
            ),
            if (selected) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: YeolpumtaTheme.accentSoft.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: YeolpumtaTheme.accent.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.drive_file_rename_outline_rounded,
                              size: 22,
                              color: YeolpumtaTheme.accent,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '공유할 음성 이름 변경',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: YeolpumtaTheme.textPrimary,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '여기 입력한 이름이 방의 공유 목록에 표시돼요. 수정하지 않아도 되고, 비우면「${job.fileName}」(내 음성 이름)으로 보내요.',
                          style: TextStyle(
                            color: YeolpumtaTheme.textSecondary,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: titleCtrl,
                          decoration: InputDecoration(
                            hintText: '방에서 보일 이름 입력',
                            isDense: true,
                            prefixIcon: Icon(
                              Icons.edit_outlined,
                              color: YeolpumtaTheme.accent.withValues(
                                alpha: 0.85,
                              ),
                              size: 22,
                            ),
                            filled: true,
                            fillColor: YeolpumtaTheme.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: YeolpumtaTheme.divider,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: YeolpumtaTheme.divider,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: YeolpumtaTheme.accent,
                                width: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
