import 'package:flutter/material.dart';

import '../../../../app/theme/yeolpumta_theme.dart';
import '../../../onboarding/data/onboarding_prefs.dart';
import '../../../onboarding/presentation/widgets/spotlight_coach_overlay.dart';
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
  final GlobalKey _hubStackKey = GlobalKey();
  final GlobalKey _roomActionsKey = GlobalKey();
  List<Room> _rooms = const [];
  bool _loading = true;
  bool _hubCoach = false;
  Rect? _hubHole;

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  Future<void> _syncHubCoachAfterLoad() async {
    final done = await OnboardingPrefs.isRoomHubIntroDone();
    if (!mounted) return;
    if (done) {
      setState(() {
        _hubCoach = false;
        _hubHole = null;
      });
      return;
    }
    if (_rooms.isNotEmpty) {
      await OnboardingPrefs.setRoomHubIntroDone();
      if (!mounted) return;
      setState(() {
        _hubCoach = false;
        _hubHole = null;
      });
      return;
    }
    setState(() => _hubCoach = true);
    _scheduleHubMeasure();
  }

  void _scheduleHubMeasure() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureHubHole());
  }

  void _measureHubHole() {
    if (!_hubCoach) return;
    final rowCtx = _roomActionsKey.currentContext;
    final stackCtx = _hubStackKey.currentContext;
    if (rowCtx == null || stackCtx == null) return;
    final rowBox = rowCtx.findRenderObject() as RenderBox?;
    final stackBox = stackCtx.findRenderObject() as RenderBox?;
    if (rowBox == null ||
        stackBox == null ||
        !rowBox.hasSize ||
        !stackBox.hasSize) {
      return;
    }
    final topLeft =
        stackBox.globalToLocal(rowBox.localToGlobal(Offset.zero));
    const pad = 8.0;
    if (!mounted) return;
    setState(() {
      _hubHole = Rect.fromLTWH(
        topLeft.dx - pad,
        topLeft.dy - pad,
        rowBox.size.width + pad * 2,
        rowBox.size.height + pad * 2,
      );
    });
  }

  Future<void> _finishHubCoachIfNeeded() async {
    if (!_hubCoach) return;
    await OnboardingPrefs.setRoomHubIntroDone();
    if (!mounted) return;
    setState(() {
      _hubCoach = false;
      _hubHole = null;
    });
  }

  Future<void> _loadRooms() async {
    final rooms = await _roomRepository.loadRooms();
    if (!mounted) return;
    setState(() {
      _rooms = rooms;
      _loading = false;
    });
    await _syncHubCoachAfterLoad();
  }

  void _openRoom(Room room) {
    Navigator.of(context)
        .push<String?>(
      MaterialPageRoute<String?>(
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
    )
        .then((deletedId) {
      if (!mounted || deletedId == null) return;
      setState(() {
        _rooms = _rooms.where((r) => r.id != deletedId).toList();
      });
    });
  }

  Future<void> _openJoinFlow() async {
    await _finishHubCoachIfNeeded();
    if (!mounted) return;
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
    final bottomPad = widget.embeddedInMainShell ? 24.0 : 100.0;

    return Scaffold(
      backgroundColor: YeolpumtaTheme.bg,
      appBar: widget.embeddedInMainShell
          ? null
          : AppBar(title: const Text('함께')),
      body: Stack(
        key: _hubStackKey,
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: ListView(
              physics: (_hubCoach && _hubHole != null)
                  ? const NeverScrollableScrollPhysics()
                  : null,
              padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPad),
              children: [
                _heroCard(context),
                const SizedBox(height: 20),
                sectionTitle('참여 중인 방'),
                const SizedBox(height: 10),
                if (_loading)
                  const WhiteCard(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_rooms.isEmpty)
                  WhiteCard(
                    child: Text(
                      '아직 방이 없어요. 아래에서 만들거나 입장해 보세요.',
                      style: TextStyle(
                        color: YeolpumtaTheme.textSecondary,
                        fontSize: 15,
                        height: 1.4,
                      ),
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
                  key: _roomActionsKey,
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () async {
                          final nav = Navigator.of(context);
                          await _finishHubCoachIfNeeded();
                          if (!mounted) return;
                          final created = await nav.push<Room>(
                            MaterialPageRoute(
                              builder: (_) => const RoomCreatePage(),
                            ),
                          );
                          if (!mounted || created == null) return;
                          setState(() => _rooms = [created, ..._rooms]);
                          _openRoom(created);
                        },
                        icon: const Icon(Icons.add_home_rounded),
                        label: const Text('방 만들기'),
                        style: FilledButton.styleFrom(
                          backgroundColor: YeolpumtaTheme.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _openJoinFlow,
                        icon: Icon(
                          Icons.login_rounded,
                          color: YeolpumtaTheme.accent,
                        ),
                        label: Text(
                          '입장하기',
                          style: TextStyle(
                            color: YeolpumtaTheme.accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: YeolpumtaTheme.outline,
                            width: 1,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          backgroundColor: YeolpumtaTheme.surface,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_hubCoach && _hubHole != null)
            Positioned.fill(
              child: SpotlightCoachOverlay(
                holeRect: _hubHole!,
                title: '방 만들기 · 입장',
                body: '새 방을 만들거나, 코드로 들어올 수 있어요.',
                tapHint: '👉 마음에 드는 쪽을 눌러봐',
                holeRadius: 16,
              ),
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
      gradient: LinearGradient(
        colors: [
          YeolpumtaTheme.accentSoft,
          YeolpumtaTheme.accentSoft.withValues(alpha: 0.45),
          Colors.white.withValues(alpha: 0.92),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: YeolpumtaTheme.accent.withValues(alpha: 0.2),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 14,
          offset: const Offset(0, 4),
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
                color: YeolpumtaTheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: YeolpumtaTheme.outline),
              ),
              child: Icon(
                Icons.family_restroom_rounded,
                color: YeolpumtaTheme.accent,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '같은 방에 초대된 사람들만,\n서로 학습해 둔 목소리를 골라 쓸 수 있어요.',
                style: TextStyle(
                  color: YeolpumtaTheme.textPrimary,
                  fontSize: 15,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          '방장이 방을 만들면 초대 코드가 생기고, 비밀번호를 켜 두면 코드 + 암호로만 들어올 수 있어요. (지금은 화면만 연결됨)',
          style: TextStyle(
            color: YeolpumtaTheme.textSecondary,
            fontSize: 13,
            height: 1.45,
          ),
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
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: YeolpumtaTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: YeolpumtaTheme.outline),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: YeolpumtaTheme.accentSoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.meeting_room_rounded,
                    color: YeolpumtaTheme.accent,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        room.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: YeolpumtaTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '코드 ${room.inviteCode} · 멤버 ${room.memberNames.length}명 · 공유 음성 ${room.sharedVoices.length}개',
                        style: TextStyle(
                          color: YeolpumtaTheme.textSecondary,
                          fontSize: 12,
                          height: 1.25,
                        ),
                      ),
                      if (room.requiresPassword)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(
                            children: [
                              Icon(
                                Icons.lock_outline_rounded,
                                size: 14,
                                color: YeolpumtaTheme.accent,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '비밀번호 필요',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: YeolpumtaTheme.accent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: YeolpumtaTheme.textSecondary.withValues(alpha: 0.8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
