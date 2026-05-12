import 'package:flutter/material.dart';

import '../../../../app/theme/yeolpumta_theme.dart';
import '../../../shared/presentation/widgets/common_widgets.dart';
import '../../data/room_repository.dart';
import '../../domain/room.dart';

/// 방 개설
class RoomCreatePage extends StatefulWidget {
  const RoomCreatePage({super.key});

  @override
  State<RoomCreatePage> createState() => _RoomCreatePageState();
}

class _RoomCreatePageState extends State<RoomCreatePage> {
  final _nameCtrl = TextEditingController(text: '우리 가족 방');
  final _passCtrl = TextEditingController();
  final _roomRepository = RoomRepository();
  bool _usePassword = false;
  bool _busy = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      showToast(context, '방 이름을 입력해 주세요.');
      return;
    }
    if (_usePassword && _passCtrl.text.trim().length < 4) {
      showToast(context, '비밀번호는 4자 이상(데모)으로 입력해 주세요.');
      return;
    }

    setState(() => _busy = true);
    try {
      final room = await _roomRepository.createRoom(
        title: name,
        usePassword: _usePassword,
        password: _passCtrl.text.trim(),
        maxParticipants: 3,
      );
      if (!mounted) return;
      showToast(context, '방이 만들어졌어요.');
      Navigator.of(context).pop<Room>(room);
    } catch (e) {
      if (!mounted) return;
      showToast(context, '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YeolpumtaTheme.bg,
      appBar: AppBar(title: const Text('방 만들기')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          WhiteCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '공개방은 누구나 목록에서 들어올 수 있고, 비밀번호방은 암호를 아는 사람만 입장할 수 있어요.',
                  style: TextStyle(
                    color: YeolpumtaTheme.textSecondary,
                    fontSize: 14,
                    height: 1.45,
                  ),
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
                  title: Text(
                    '비밀번호방으로 만들기',
                    style: TextStyle(
                      color: YeolpumtaTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Text(
                    '전체 방 목록에서 선택한 뒤 암호를 입력해야 입장할 수 있어요.',
                    style: TextStyle(
                      fontSize: 12,
                      color: YeolpumtaTheme.textSecondary,
                      height: 1.35,
                    ),
                  ),
                  value: _usePassword,
                  activeThumbColor: YeolpumtaTheme.accent,
                  activeTrackColor: YeolpumtaTheme.accent.withValues(
                    alpha: 0.35,
                  ),
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
            onPressed: _busy ? null : _create,
            style: FilledButton.styleFrom(
              backgroundColor: YeolpumtaTheme.accent,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    '방 만들기',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
          ),
        ],
      ),
    );
  }
}
