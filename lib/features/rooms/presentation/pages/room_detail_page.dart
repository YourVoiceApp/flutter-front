import 'package:flutter/material.dart';

import '../../../shared/presentation/widgets/common_widgets.dart';
import '../../data/room_repository.dart';
import '../../domain/room.dart';
import '../../../voices/domain/voice_job.dart';
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
      backgroundColor: const Color(0xFFF8FAFC),
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
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '내가 공유할 음성',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '학습이 끝난 목소리 중 이 방에서 쓰도록 허용할 항목을 고르세요.',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 280,
                    child: ListView(
                      children: _myVoices.map((v) {
                        final on = chosen.contains(v.id);
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: CheckboxListTile(
                            value: on,
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
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(v.origin.label),
                            secondary: const CircleAvatar(
                              backgroundColor: Color(0xFFEAF0FF),
                              child: Icon(
                                Icons.graphic_eq_rounded,
                                color: Color(0xFF3B6AF5),
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
                          const SnackBar(content: Text('이 방에 공유 목록을 반영했어요.')),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        messenger.showSnackBar(SnackBar(content: Text('$e')));
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFE07C4C),
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: const Text('이 방에 반영'),
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
      backgroundColor: const Color(0xFFF4F7FF),
      appBar: AppBar(
        title: Text(_room.name),
        actions: [
          IconButton(
            tooltip: '초대 정보',
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (c) => AlertDialog(
                  title: const Text('초대 코드'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText(
                        _room.inviteCode,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _room.requiresPassword
                            ? '비밀번호가 켜진 방이에요. 코드와 함께 암호를 전달하세요.'
                            : '코드만 알면 입장할 수 있어요.',
                        style: const TextStyle(color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(c),
                      child: const Text('닫기'),
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
                const Text(
                  '멤버',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final m in _room.memberNames)
                      Chip(
                        avatar: const Icon(Icons.person_rounded, size: 16),
                        label: Text(m),
                        backgroundColor: const Color(0xFFEAF0FF),
                        side: BorderSide.none,
                      ),
                    ActionChip(
                      avatar: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('초대'),
                      backgroundColor: const Color(0xFFFFF4E6),
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
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_room.sharedVoices.isEmpty)
            const WhiteCard(
              child: Text(
                '아직 공유된 음성이 없어요. 아래에서 내 음성을 올려 보세요.',
                style: TextStyle(color: Color(0xFF64748B)),
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
                          color: const Color(0xFFFFF4E6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.record_voice_over_rounded,
                          color: Color(0xFFE07C4C),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              v.voiceTitle,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              '${v.ownerName} · ${v.subtitle ?? ''}',
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => showSharedVoicePlaySheet(context, v),
                        child: const Text('사용'),
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
        backgroundColor: const Color(0xFFE07C4C),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.upload_rounded),
        label: const Text('내 음성 공유'),
      ),
    );
  }
}
