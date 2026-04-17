import 'package:flutter/material.dart';

import '../../../shared/presentation/widgets/common_widgets.dart';
<<<<<<< Updated upstream
import '../room_demo_data.dart';

/// 방 개설 (초대 코드 생성 · 비밀번호 선택) — UI만
=======
import '../../data/room_repository.dart';
import '../../domain/room.dart';

/// 방 개설
>>>>>>> Stashed changes
class RoomCreatePage extends StatefulWidget {
  const RoomCreatePage({super.key});

  @override
  State<RoomCreatePage> createState() => _RoomCreatePageState();
}

class _RoomCreatePageState extends State<RoomCreatePage> {
  final _nameCtrl = TextEditingController(text: '우리 가족 방');
  final _passCtrl = TextEditingController();
<<<<<<< Updated upstream
  bool _usePassword = false;
=======
  final _roomRepository = RoomRepository();
  bool _usePassword = false;
  bool _busy = false;
>>>>>>> Stashed changes

  @override
  void dispose() {
    _nameCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

<<<<<<< Updated upstream
  String _genInviteCode() {
    final x = DateTime.now().millisecondsSinceEpoch % 0x10000;
    return 'FAM-${x.toRadixString(16).toUpperCase().padLeft(4, '0')}';
  }

  void _create() {
=======
  Future<void> _create() async {
>>>>>>> Stashed changes
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      showToast(context, '방 이름을 입력해 주세요.');
      return;
    }
    if (_usePassword && _passCtrl.text.trim().length < 4) {
      showToast(context, '비밀번호는 4자 이상(데모)으로 입력해 주세요.');
      return;
    }

<<<<<<< Updated upstream
    final room = RoomDemo(
      id: 'new-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      inviteCode: _genInviteCode(),
      requirePassword: _usePassword,
      memberNames: const ['나'],
      sharedVoices: const [],
    );

    showToast(context, '방이 만들어졌어요. 초대 코드를 공유해 보세요. (UI 데모)');
    Navigator.of(context).pop<RoomDemo>(room);
=======
    setState(() => _busy = true);
    try {
      final room = await _roomRepository.createRoom(
        title: name,
        usePassword: _usePassword,
        password: _passCtrl.text.trim(),
        maxParticipants: 3,
      );
      if (!mounted) return;
      showToast(context, '방이 만들어졌어요. 초대 코드를 공유해 보세요.');
      Navigator.of(context).pop<Room>(room);
    } catch (e) {
      if (!mounted) return;
      showToast(context, '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
>>>>>>> Stashed changes
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
<<<<<<< Updated upstream
      appBar: AppBar(
        title: const Text('방 만들기'),
      ),
=======
      appBar: AppBar(title: const Text('방 만들기')),
>>>>>>> Stashed changes
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          WhiteCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '가족이나 지인만 들어올 수 있게 방을 열고, 초대 코드를 나눠 주세요.',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameCtrl,
                  decoration: fieldDecoration(
                    hint: '방 이름 (예: 우리 가족 방)',
                    icon: Icons.meeting_room_outlined,
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('비밀번호로 입장만 허용'),
                  subtitle: const Text(
                    '초대 코드와 함께 암호를 아는 사람만 입장 (데모)',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: _usePassword,
                  activeThumbColor: const Color(0xFFE07C4C),
                  onChanged: (v) => setState(() => _usePassword = v),
                ),
                if (_usePassword) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passCtrl,
                    obscureText: true,
                    decoration: fieldDecoration(
                      hint: '방 비밀번호',
                      icon: Icons.password_rounded,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
<<<<<<< Updated upstream
            onPressed: _create,
=======
            onPressed: _busy ? null : _create,
>>>>>>> Stashed changes
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE07C4C),
              minimumSize: const Size.fromHeight(52),
            ),
<<<<<<< Updated upstream
            child: const Text('방 만들기'),
=======
            child: _busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('방 만들기'),
>>>>>>> Stashed changes
          ),
        ],
      ),
    );
  }
}
