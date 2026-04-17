import 'package:flutter/material.dart';

import '../../../shared/presentation/widgets/common_widgets.dart';
import '../../data/room_repository.dart';
import '../../domain/room.dart';
import 'room_create_page.dart';
import 'room_detail_page.dart';
import 'room_join_page.dart';

/// 가족·지인과 음성을 나누는 '방' 목록 (UI 데모)
class RoomHubPage extends StatefulWidget {
  const RoomHubPage({super.key, this.embeddedInMainShell = false});

  /// 메인 탭에 넣을 때 상단 앱바는 바깥 셸이 담당
  final bool embeddedInMainShell;

  @override
  State<RoomHubPage> createState() => _RoomHubPageState();
}

class _RoomHubPageState extends State<RoomHubPage> {
  final _roomRepository = RoomRepository();
  List<Room> _rooms = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    final rooms = await _roomRepository.loadRooms();
    if (!mounted) return;
    setState(() {
      _rooms = rooms;
      _loading = false;
    });
  }

  void _openRoom(Room room) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => RoomDetailPage(
          initialRoom: room,
          onRoomUpdated: (updated) {
            setState(() {
              final i = _rooms.indexWhere((r) => r.id == updated.id);
              if (i >= 0) _rooms[i] = updated;
            });
          },
        ),
      ),
    );
  }

  Future<void> _openJoinFlow() async {
    final navigator = Navigator.of(context);
    final joined = await navigator.push<Room>(
      MaterialPageRoute(
        builder: (_) =>
            RoomJoinPage(existingCodes: {for (final r in _rooms) r.inviteCode}),
      ),
    );
    if (!mounted || joined == null) return;
    if (_rooms.every((r) => r.id != joined.id)) {
      setState(() => _rooms = [joined, ..._rooms]);
    }
    _openRoom(joined);
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.embeddedInMainShell
        ? const Color(0xFFF2F3F5)
        : const Color(0xFFF4F7FF);
    final bottomPad = widget.embeddedInMainShell ? 24.0 : 100.0;

    return Scaffold(
      backgroundColor: bg,
      appBar: widget.embeddedInMainShell
          ? null
          : AppBar(title: const Text('가족 · 공유 방')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPad),
        children: [
          _heroCard(context),
          const SizedBox(height: 20),
          sectionTitle('참여 중인 방'),
          const SizedBox(height: 10),
          if (_loading)
            const WhiteCard(child: Center(child: CircularProgressIndicator()))
          else if (_rooms.isEmpty)
            const WhiteCard(
              child: Text(
                '아직 방이 없어요. 아래에서 만들거나 입장해 보세요.',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
            )
          else
            ..._rooms.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _RoomEntryTile(room: r, onTap: () => _openRoom(r)),
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () async {
                    final created = await Navigator.of(context).push<Room>(
                      MaterialPageRoute(builder: (_) => const RoomCreatePage()),
                    );
                    if (!context.mounted || created == null) return;
                    setState(() => _rooms = [created, ..._rooms]);
                    _openRoom(created);
                  },
                  icon: const Icon(Icons.add_home_rounded),
                  label: const Text('방 만들기'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFE07C4C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _openJoinFlow,
                  icon: const Icon(Icons.login_rounded),
                  label: const Text('입장하기'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFC2410C),
                    side: const BorderSide(color: Color(0xFFFDBA74)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Widget _heroCard(BuildContext context) {
  return Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFFFFF4E6), Color(0xFFFFE8D6)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFFDBA74)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x12000000),
          blurRadius: 12,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.family_restroom_rounded,
                color: Color(0xFFC2410C),
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                '같은 방에 초대된 사람들만,\n서로 학습해 둔 목소리를 골라 쓸 수 있어요.',
                style: TextStyle(
                  color: Color(0xFF7C2D12),
                  fontSize: 15,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          '방장이 방을 만들면 초대 코드가 생기고, 비밀번호를 켜 두면 코드 + 암호로만 들어올 수 있어요. (지금은 화면만 연결됨)',
          style: TextStyle(color: Color(0xFF9A3412), fontSize: 13, height: 1.4),
        ),
      ],
    ),
  );
}

class _RoomEntryTile extends StatelessWidget {
  const _RoomEntryTile({required this.room, required this.onTap});

  final Room room;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4E6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.meeting_room_rounded,
                  color: Color(0xFFE07C4C),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '코드 ${room.inviteCode} · 멤버 ${room.memberNames.length}명 · 공유 음성 ${room.sharedVoices.length}개',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                      ),
                    ),
                    if (room.requiresPassword)
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Row(
                          children: [
                            Icon(
                              Icons.lock_outline_rounded,
                              size: 14,
                              color: Color(0xFFEA580C),
                            ),
                            SizedBox(width: 4),
                            Text(
                              '비밀번호 필요',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFFEA580C),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
            ],
          ),
        ),
      ),
    );
  }
}
