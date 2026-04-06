import 'package:flutter/material.dart';

import '../../../shared/presentation/widgets/common_widgets.dart';
import '../room_demo_data.dart';

/// 초대 코드 또는 코드+비밀번호로 입장 — UI만
class RoomJoinPage extends StatefulWidget {
  const RoomJoinPage({super.key, this.existingCodes = const {}});

  /// 이미 목록에 있는 코드 (중복 입장 안내용)
  final Set<String> existingCodes;

  @override
  State<RoomJoinPage> createState() => _RoomJoinPageState();
}

class _RoomJoinPageState extends State<RoomJoinPage> {
  final _codeCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  int _mode = 0; // 0: 코드만, 1: 코드+비밀번호

  @override
  void dispose() {
    _codeCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  RoomDemo? _matchMockRoom(String code) {
    final c = code.trim().toUpperCase();
    for (final r in kMockJoinedRooms) {
      if (r.inviteCode.toUpperCase() == c) return r;
    }
    return null;
  }

  void _join() {
    final code = _codeCtrl.text.trim().toUpperCase();
    final pass = _passCtrl.text.trim();
    if (code.length < 6) {
      showToast(context, '초대 코드를 입력해 주세요. (예: FAM-7K2Q)');
      return;
    }

    final codesUpper = widget.existingCodes.map((e) => e.toUpperCase()).toSet();
    if (codesUpper.contains(code)) {
      showToast(context, '이미 목록에 있는 방 코드예요. (그대로 입장해 볼게요)');
    }

    if (_mode == 1 && pass.length < 4) {
      showToast(context, '비밀번호를 입력해 주세요.');
      return;
    }

    final matched = _matchMockRoom(code);
    if (matched != null) {
      if (matched.requirePassword && _mode == 0) {
        showToast(context, '이 방은 비밀번호가 필요해요. 「코드 + 비밀번호」를 선택해 주세요.');
        return;
      }
      if (matched.requirePassword && pass.length < 4) {
        showToast(context, '비밀번호를 입력해 주세요. (데모: 아무 값 4자 이상)');
        return;
      }
      showToast(context, '「${matched.name}」방에 들어왔어요. (UI 데모)');
      Navigator.of(context).pop<RoomDemo>(matched);
      return;
    }

    // 알 수 없는 코드 → 새 방으로 가입한 것처럼 데모
    final synthetic = RoomDemo(
      id: 'join-${DateTime.now().millisecondsSinceEpoch}',
      name: '초대받은 방',
      inviteCode: code,
      requirePassword: _mode == 1,
      memberNames: const ['나'],
      sharedVoices: const [],
    );
    showToast(context, '새 방에 참여했어요. (데모: 목에 없던 코드도 허용)');
    Navigator.of(context).pop<RoomDemo>(synthetic);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      appBar: AppBar(
        title: const Text('방 입장'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          WhiteCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(
                      value: 0,
                      label: Text('초대 코드'),
                      icon: Icon(Icons.tag_rounded, size: 18),
                    ),
                    ButtonSegment(
                      value: 1,
                      label: Text('코드 + 비밀번호'),
                      icon: Icon(Icons.key_rounded, size: 18),
                    ),
                  ],
                  selected: {_mode},
                  onSelectionChanged: (s) {
                    setState(() => _mode = s.first);
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _codeCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: fieldDecoration(
                    hint: 'FAM-7K2Q',
                    icon: Icons.qr_code_2_rounded,
                  ),
                ),
                if (_mode == 1) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passCtrl,
                    obscureText: true,
                    decoration: fieldDecoration(
                      hint: '방 비밀번호',
                      icon: Icons.lock_outline_rounded,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                const Text(
                  '데모: 목록에 있는 FAM-7K2Q(우리 가족 방)는 비밀번호가 필요하다고 가정해 두었어요. 「코드 + 비밀번호」로 전환한 뒤 아무 암호 4자 이상을 넣어 보세요.',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _join,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF3B6AF5),
              minimumSize: const Size.fromHeight(52),
            ),
            child: const Text('입장'),
          ),
        ],
      ),
    );
  }
}
