import 'package:flutter/material.dart';

import '../../../../app/theme/yeolpumta_theme.dart';
import '../../../shared/presentation/widgets/common_widgets.dart';
import '../../../voices/domain/voice_job.dart';
import '../../data/room_repository.dart';
import '../../domain/room.dart';
import '../widgets/shared_voice_play_sheet.dart';

typedef RoomUpdated = void Function(Room room);

/// 방 안: 멤버 · 공유 음성 · 내 음성 올리기 (UI)
class RoomDetailPage extends StatefulWidget {
  const RoomDetailPage({
    super.key,
    required this.initialRoom,
    this.onRoomUpdated,
  });

  final Room initialRoom;
  final RoomUpdated? onRoomUpdated;

  @override
  State<RoomDetailPage> createState() => _RoomDetailPageState();
}

class _RoomDetailPageState extends State<RoomDetailPage> {
  final _roomRepository = RoomRepository();
  late Room _room;
  List<VoiceJob> _myVoices = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _room = widget.initialRoom;
    _load();
  }

  void _notifyParent() {
    widget.onRoomUpdated?.call(_room);
  }

  Future<void> _load() async {
    try {
      final detail = await _roomRepository.loadRoomDetail(_room);
      final myVoices = await _roomRepository.loadSharableVoices();
      if (!mounted) return;
      setState(() {
        _room = detail;
        _myVoices = myVoices;
        _loading = false;
      });
      _notifyParent();
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _shareVoiceSheet() {
    final chosen = <String>{
      for (final v in _room.sharedVoices) v.externalVoiceId,
    };

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: YeolpumtaTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 12,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                    '내가 공유할 음성',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: YeolpumtaTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '학습이 끝난 목소리 중 이 방에서 쓰도록 허용할 항목을 고르세요.',
                    style: TextStyle(
                      color: YeolpumtaTheme.textSecondary,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 280,
                    child: ListView(
                      children: _myVoices.map((v) {
                        final on = chosen.contains(v.id);
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          color: YeolpumtaTheme.surface,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: const BorderSide(
                              color: YeolpumtaTheme.outline,
                            ),
                          ),
                          child: CheckboxListTile(
                            value: on,
                            activeColor: YeolpumtaTheme.accent,
                            onChanged: (c) {
                              setModalState(() {
                                if (c == true) {
                                  chosen.add(v.id);
                                } else {
                                  chosen.remove(v.id);
                                }
                              });
                            },
                            title: Text(
                              v.fileName,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: YeolpumtaTheme.textPrimary,
                              ),
                            ),
                            subtitle: Text(
                              v.origin.label,
                              style: TextStyle(
                                color: YeolpumtaTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            secondary: CircleAvatar(
                              backgroundColor: YeolpumtaTheme.accentSoft,
                              child: Icon(
                                Icons.graphic_eq_rounded,
                                color: YeolpumtaTheme.accent,
                                size: 20,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () async {
                      final navigator = Navigator.of(ctx);
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        final updated = await _roomRepository.syncSharedVoices(
                          room: _room,
                          selectedVoiceIds: chosen,
                        );
                        if (!mounted) return;
                        setState(() => _room = updated);
                        _notifyParent();
                        navigator.pop();
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('이 방에 공유 목록을 반영했어요.'),
                          ),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        messenger.showSnackBar(SnackBar(content: Text('$e')));
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: YeolpumtaTheme.accent,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      '이 방에 반영',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YeolpumtaTheme.bg,
      appBar: AppBar(
        title: Text(_room.name),
        actions: [
          IconButton(
            tooltip: '초대 정보',
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (c) => AlertDialog(
                  backgroundColor: YeolpumtaTheme.surface,
                  surfaceTintColor: Colors.transparent,
                  title: Text(
                    '초대 코드',
                    style: TextStyle(
                      color: YeolpumtaTheme.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText(
                        _room.inviteCode,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: YeolpumtaTheme.accent,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _room.requiresPassword
                            ? '비밀번호가 켜진 방이에요. 코드와 함께 암호를 전달하세요.'
                            : '코드만 알면 입장할 수 있어요.',
                        style: TextStyle(
                          color: YeolpumtaTheme.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(c),
                      child: Text(
                        '닫기',
                        style: TextStyle(
                          color: YeolpumtaTheme.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.ios_share_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: WhiteCard(
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
          WhiteCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '멤버',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: YeolpumtaTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final m in _room.memberNames)
                      Chip(
                        avatar: Icon(
                          Icons.person_rounded,
                          size: 16,
                          color: YeolpumtaTheme.accent,
                        ),
                        label: Text(m),
                        backgroundColor: YeolpumtaTheme.accentSoft,
                        side: BorderSide(
                          color: YeolpumtaTheme.accent.withValues(alpha: 0.2),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                      ),
                    ActionChip(
                      avatar: Icon(
                        Icons.add_rounded,
                        size: 18,
                        color: YeolpumtaTheme.accent,
                      ),
                      label: Text(
                        '초대',
                        style: TextStyle(
                          color: YeolpumtaTheme.accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      backgroundColor: YeolpumtaTheme.surface,
                      side: const BorderSide(color: YeolpumtaTheme.outline),
                      onPressed: () =>
                          showToast(context, '초대 코드 입장 API는 아직 문서에 없습니다.'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              sectionTitle('공유된 음성'),
              const Spacer(),
              Text(
                '${_room.sharedVoices.length}개',
                style: TextStyle(
                  color: YeolpumtaTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_room.sharedVoices.isEmpty)
            WhiteCard(
              child: Text(
                '아직 공유된 음성이 없어요. 아래에서 내 음성을 올려 보세요.',
                style: TextStyle(
                  color: YeolpumtaTheme.textSecondary,
                  height: 1.4,
                ),
              ),
            )
          else
            ..._room.sharedVoices.map(
              (v) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: WhiteCard(
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: YeolpumtaTheme.accentSoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.record_voice_over_rounded,
                          color: YeolpumtaTheme.accent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              v.voiceTitle,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: YeolpumtaTheme.textPrimary,
                              ),
                            ),
                            Text(
                              '${v.ownerName} · ${v.subtitle ?? ''}',
                              style: TextStyle(
                                color: YeolpumtaTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => showSharedVoicePlaySheet(context, v),
                        child: Text(
                          '사용',
                          style: TextStyle(
                            color: YeolpumtaTheme.accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _shareVoiceSheet,
        backgroundColor: YeolpumtaTheme.accent,
        foregroundColor: Colors.white,
        elevation: 2,
        highlightElevation: 4,
        icon: const Icon(Icons.upload_rounded),
        label: const Text(
          '내 음성 공유',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
