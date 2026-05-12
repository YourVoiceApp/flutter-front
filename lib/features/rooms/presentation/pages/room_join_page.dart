import 'package:flutter/material.dart';

import '../../../../app/theme/yeolpumta_theme.dart';
import '../../../shared/presentation/widgets/common_widgets.dart';
import '../../data/room_repository.dart';
import '../../domain/room.dart';

/// 전체 방 목록에서 roomId 기준으로 입장합니다.
class RoomJoinPage extends StatefulWidget {
  const RoomJoinPage({super.key});

  @override
  State<RoomJoinPage> createState() => _RoomJoinPageState();
}

class _RoomJoinPageState extends State<RoomJoinPage> {
  final _roomRepository = RoomRepository();
  List<Room> _discoverRooms = const [];
  bool _discoverLoading = true;
  bool _joining = false;

  @override
  void initState() {
    super.initState();
    _loadDiscoverRooms();
  }

  Future<void> _loadDiscoverRooms() async {
    setState(() => _discoverLoading = true);
    try {
      final page = await _roomRepository.discoverRooms(size: 20);
      if (!mounted) return;
      setState(() {
        _discoverRooms = page.content;
        _discoverLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _discoverLoading = false);
      showToast(context, '방 목록을 불러오지 못했어요. ($e)');
    }
  }

  Future<void> _joinRoom(Room room) async {
    final navigator = Navigator.of(context);
    String? password;

    if (room.requiresPassword) {
      password = await showDialog<String>(
        context: context,
        builder: (_) => _RoomPasswordDialog(roomName: room.name),
      );
      if (!mounted) return;
      if ((password ?? '').trim().isEmpty) return;
    }

    final remote = await _roomRepository.usesRemote;
    if (!mounted) return;
    if (!remote) {
      showToast(context, '「${room.name}」방에 들어왔어요. (UI 데모)');
      navigator.pop<Room>(room);
      return;
    }

    setState(() => _joining = true);
    try {
      final joined = await _roomRepository.joinRoom(
        roomId: room.id,
        password: room.requiresPassword ? password : null,
      );
      if (!mounted) return;
      showToast(context, '「${joined.name}」방에 들어왔어요.');
      navigator.pop<Room>(joined);
    } catch (e) {
      if (!mounted) return;
      showToast(context, '$e');
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YeolpumtaTheme.bg,
      appBar: AppBar(
        title: const Text('방 입장'),
        actions: [
          IconButton(
            tooltip: '새로고침',
            onPressed: _discoverLoading ? null : _loadDiscoverRooms,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDiscoverRooms,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.all(16),
          children: [
            WhiteCard(
              child: Text(
                '전체 방 목록에서 방을 선택해요. 공개방은 바로 입장하고, 비밀번호방은 암호를 입력해 들어갈 수 있어요.',
                style: TextStyle(
                  color: YeolpumtaTheme.textSecondary,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                sectionTitle('전체 방'),
                const Spacer(),
                if (_discoverLoading || _joining)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: YeolpumtaTheme.accent,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (_discoverLoading)
              const WhiteCard(child: Center(child: CircularProgressIndicator()))
            else if (_discoverRooms.isEmpty)
              WhiteCard(
                child: Text(
                  '아직 발견할 수 있는 방이 없어요.',
                  style: TextStyle(
                    color: YeolpumtaTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
              )
            else
              ..._discoverRooms.map(
                (room) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _DiscoverRoomTile(
                    room: room,
                    disabled: _joining,
                    onTap: () => _joinRoom(room),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DiscoverRoomTile extends StatelessWidget {
  const _DiscoverRoomTile({
    required this.room,
    required this.disabled,
    required this.onTap,
  });

  final Room room;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final requiresPassword = room.requiresPassword;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: disabled ? null : onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: YeolpumtaTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: YeolpumtaTheme.outline),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: YeolpumtaTheme.accentSoft,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    requiresPassword
                        ? Icons.lock_outline_rounded
                        : Icons.public_rounded,
                    color: YeolpumtaTheme.accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        room.name,
                        style: TextStyle(
                          color: YeolpumtaTheme.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '멤버 ${room.memberCount}/${room.maxParticipants}명 · ${requiresPassword ? '비밀번호방' : '공개방'}',
                        style: TextStyle(
                          color: YeolpumtaTheme.textSecondary,
                          fontSize: 12,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  requiresPassword ? '암호 입력' : '입장',
                  style: TextStyle(
                    color: YeolpumtaTheme.accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoomPasswordDialog extends StatefulWidget {
  const _RoomPasswordDialog({required this.roomName});

  final String roomName;

  @override
  State<_RoomPasswordDialog> createState() => _RoomPasswordDialogState();
}

class _RoomPasswordDialogState extends State<_RoomPasswordDialog> {
  late final TextEditingController _passwordCtrl;

  @override
  void initState() {
    super.initState();
    _passwordCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.pop(context, _passwordCtrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: YeolpumtaTheme.surface,
      surfaceTintColor: Colors.transparent,
      title: Text(
        '비밀번호 입장',
        style: TextStyle(
          color: YeolpumtaTheme.textPrimary,
          fontWeight: FontWeight.w800,
        ),
      ),
      content: TextField(
        controller: _passwordCtrl,
        obscureText: true,
        autofocus: true,
        decoration: fieldDecoration(
          hint: '「${widget.roomName}」 방 비밀번호',
          icon: Icons.lock_outline_rounded,
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('취소', style: TextStyle(color: YeolpumtaTheme.accent)),
        ),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(
            backgroundColor: YeolpumtaTheme.accent,
            foregroundColor: Colors.white,
          ),
          child: const Text('입장'),
        ),
      ],
    );
  }
}
