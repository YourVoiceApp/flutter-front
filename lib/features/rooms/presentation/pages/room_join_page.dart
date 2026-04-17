import 'package:flutter/material.dart';

import '../../../shared/presentation/widgets/common_widgets.dart';
<<<<<<< Updated upstream
=======
import '../../data/room_repository.dart';
import '../../domain/room.dart';
>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
  int _mode = 0; // 0: 코드만, 1: 코드+비밀번호
=======
  final _roomRepository = RoomRepository();
  int _mode = 0; // 0: 코드만, 1: 코드+비밀번호
  bool _busy = false;
>>>>>>> Stashed changes

  @override
  void dispose() {
    _codeCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

<<<<<<< Updated upstream
  RoomDemo? _matchMockRoom(String code) {
    final c = code.trim().toUpperCase();
    for (final r in kMockJoinedRooms) {
      if (r.inviteCode.toUpperCase() == c) return r;
=======
  Room? _matchMockRoom(String code) {
    final c = code.trim().toUpperCase();
    for (final r in kMockJoinedRooms) {
      if (r.inviteCode.toUpperCase() == c) {
        return Room(
          id: r.id,
          name: r.name,
          inviteCode: r.inviteCode,
          joinPolicy: r.requirePassword
              ? RoomJoinPolicy.inviteCodeWithPassword
              : RoomJoinPolicy.inviteCodeOnly,
          members: [
            for (final name in r.memberNames)
              RoomMember(id: name, displayName: name),
          ],
          sharedVoices: [
            for (final voice in r.sharedVoices)
              RoomSharedVoice(
                id: voice.id,
                externalVoiceId: voice.id,
                voiceTitle: voice.voiceTitle,
                ownerName: voice.ownerName,
                subtitle: voice.subtitle,
              ),
          ],
        );
      }
>>>>>>> Stashed changes
    }
    return null;
  }

<<<<<<< Updated upstream
  void _join() {
    final code = _codeCtrl.text.trim().toUpperCase();
    final pass = _passCtrl.text.trim();
    if (code.length < 6) {
      showToast(context, '초대 코드를 입력해 주세요. (예: FAM-7K2Q)');
=======
  Future<void> _join() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    void showMessage(String message) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }

    final code = _codeCtrl.text.trim().toUpperCase();
    final pass = _passCtrl.text.trim();
    if (code.length < 6) {
      showMessage('초대 코드를 입력해 주세요. (예: FAM-7K2Q)');
>>>>>>> Stashed changes
      return;
    }

    final codesUpper = widget.existingCodes.map((e) => e.toUpperCase()).toSet();
    if (codesUpper.contains(code)) {
<<<<<<< Updated upstream
      showToast(context, '이미 목록에 있는 방 코드예요. (그대로 입장해 볼게요)');
    }

    if (_mode == 1 && pass.length < 4) {
      showToast(context, '비밀번호를 입력해 주세요.');
=======
      showMessage('이미 목록에 있는 방 코드예요. (그대로 입장해 볼게요)');
    }

    if (_mode == 1 && pass.length < 4) {
      showMessage('비밀번호를 입력해 주세요.');
      return;
    }

    if (await _roomRepository.usesRemote) {
      setState(() => _busy = true);
      try {
        final joined = await _roomRepository.joinRoom(
          inviteCode: code,
          password: _mode == 1 ? pass : null,
        );
        if (!mounted) return;
        showMessage('「${joined.name}」방에 들어왔어요.');
        navigator.pop<Room>(joined);
      } catch (e) {
        if (!mounted) return;
        showMessage('$e');
      } finally {
        if (mounted) setState(() => _busy = false);
      }
>>>>>>> Stashed changes
      return;
    }

    final matched = _matchMockRoom(code);
    if (matched != null) {
<<<<<<< Updated upstream
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
=======
      if (matched.requiresPassword && _mode == 0) {
        showMessage('이 방은 비밀번호가 필요해요. 「코드 + 비밀번호」를 선택해 주세요.');
        return;
      }
      if (matched.requiresPassword && pass.length < 4) {
        showMessage('비밀번호를 입력해 주세요. (데모: 아무 값 4자 이상)');
        return;
      }
      showMessage('「${matched.name}」방에 들어왔어요. (UI 데모)');
      navigator.pop<Room>(matched);
>>>>>>> Stashed changes
      return;
    }

    // 알 수 없는 코드 → 새 방으로 가입한 것처럼 데모
<<<<<<< Updated upstream
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
=======
    final synthetic = Room(
      id: 'join-${DateTime.now().millisecondsSinceEpoch}',
      name: '초대받은 방',
      inviteCode: code,
      joinPolicy: _mode == 1
          ? RoomJoinPolicy.inviteCodeWithPassword
          : RoomJoinPolicy.inviteCodeOnly,
      members: const [RoomMember(id: 'me', displayName: '나')],
      sharedVoices: const [],
    );
    showMessage('새 방에 참여했어요. (데모: 목록에 없던 코드도 허용)');
    navigator.pop<Room>(synthetic);
>>>>>>> Stashed changes
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
<<<<<<< Updated upstream
      appBar: AppBar(
        title: const Text('방 입장'),
      ),
=======
      appBar: AppBar(title: const Text('방 입장')),
>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, height: 1.35),
=======
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                    height: 1.35,
                  ),
>>>>>>> Stashed changes
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
<<<<<<< Updated upstream
            onPressed: _join,
=======
            onPressed: _busy ? null : _join,
>>>>>>> Stashed changes
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF3B6AF5),
              minimumSize: const Size.fromHeight(52),
            ),
<<<<<<< Updated upstream
            child: const Text('입장'),
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
                : const Text('입장'),
>>>>>>> Stashed changes
          ),
        ],
      ),
    );
  }
}
