import 'package:flutter/material.dart';

import '../../../../app/theme/yeolpumta_theme.dart';
import '../../../shared/presentation/widgets/common_widgets.dart';
import '../../data/room_repository.dart';
import '../../domain/room.dart';
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
  final _roomRepository = RoomRepository();
  int _mode = 0; // 0: 코드만, 1: 코드+비밀번호
  bool _busy = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

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
    }
    return null;
  }

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
      return;
    }

    final codesUpper = widget.existingCodes.map((e) => e.toUpperCase()).toSet();
    if (codesUpper.contains(code)) {
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
      return;
    }

    final matched = _matchMockRoom(code);
    if (matched != null) {
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
      return;
    }

    // 알 수 없는 코드 → 새 방으로 가입한 것처럼 데모
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YeolpumtaTheme.bg,
      appBar: AppBar(title: const Text('방 입장')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          WhiteCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<int>(
                  style: SegmentedButton.styleFrom(
                    backgroundColor: YeolpumtaTheme.iconMutedBg,
                    selectedBackgroundColor: YeolpumtaTheme.accentSoft,
                    selectedForegroundColor: YeolpumtaTheme.accent,
                    foregroundColor: YeolpumtaTheme.textPrimary,
                    side: const BorderSide(color: YeolpumtaTheme.outline),
                  ),
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
                Text(
                  '데모: 목록에 있는 FAM-7K2Q(우리 가족 방)는 비밀번호가 필요하다고 가정해 두었어요. 「코드 + 비밀번호」로 전환한 뒤 아무 암호 4자 이상을 넣어 보세요.',
                  style: TextStyle(
                    color: YeolpumtaTheme.textSecondary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy ? null : _join,
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
                    '입장',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
          ),
        ],
      ),
    );
  }
}
