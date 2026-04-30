import 'package:flutter/material.dart';

import '../../../../app/theme/yeolpumta_theme.dart';
import '../../../onboarding/data/onboarding_prefs.dart';
import '../../../onboarding/presentation/widgets/spotlight_coach_overlay.dart';
import '../../../shared/presentation/widgets/common_widgets.dart';
import '../../../shared/presentation/widgets/voice_cute_leading_art.dart';
import '../../../voices/domain/voice_job.dart';
import '../../data/room_repository.dart';
import '../../domain/room.dart';
import '../widgets/room_share_voices_sheet.dart';
import '../widgets/shared_voice_play_sheet.dart';

typedef RoomUpdated = void Function(Room room);

class _RoomEditResult {
  const _RoomEditResult({
    required this.title,
    required this.usePassword,
    required this.password,
    required this.maxParticipants,
  });

  final String title;
  final bool usePassword;
  final String password;
  final int maxParticipants;
}

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
  final GlobalKey _detailStackKey = GlobalKey();
  final GlobalKey _shareFabKey = GlobalKey();
  late Room _room;
  List<VoiceJob> _myVoices = const [];
  bool _loading = true;
  bool _isOwner = false;
  bool _shareFabCoach = false;
  Rect? _shareFabHole;

  @override
  void initState() {
    super.initState();
    _room = widget.initialRoom;
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrapShareFabCoach());
  }

  Future<void> _bootstrapShareFabCoach() async {
    final done = await OnboardingPrefs.isRoomShareFabDone();
    if (!mounted) return;
    setState(() => _shareFabCoach = !done);
    if (!done) _scheduleFabMeasure();
  }

  void _scheduleFabMeasure() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureShareFabHole());
  }

  void _measureShareFabHole() {
    if (!_shareFabCoach || _loading) return;
    final fabCtx = _shareFabKey.currentContext;
    final stackCtx = _detailStackKey.currentContext;
    if (fabCtx == null || stackCtx == null) return;
    final fabBox = fabCtx.findRenderObject() as RenderBox?;
    final stackBox = stackCtx.findRenderObject() as RenderBox?;
    if (fabBox == null ||
        stackBox == null ||
        !fabBox.hasSize ||
        !stackBox.hasSize) {
      return;
    }
    final topLeft =
        stackBox.globalToLocal(fabBox.localToGlobal(Offset.zero));
    const pad = 8.0;
    if (!mounted) return;
    setState(() {
      _shareFabHole = Rect.fromLTWH(
        topLeft.dx - pad,
        topLeft.dy - pad,
        fabBox.size.width + pad * 2,
        fabBox.size.height + pad * 2,
      );
    });
  }

  Future<void> _finishShareFabCoachIfNeeded() async {
    if (!_shareFabCoach) return;
    await OnboardingPrefs.setRoomShareFabDone();
    if (!mounted) return;
    setState(() {
      _shareFabCoach = false;
      _shareFabHole = null;
    });
  }

  Future<void> _onShareFabPressed() async {
    await _finishShareFabCoachIfNeeded();
    _shareVoiceSheet();
  }

  void _notifyParent() {
    widget.onRoomUpdated?.call(_room);
  }

  Future<void> _load() async {
    try {
      final remote = await _roomRepository.usesRemote;
      final detail = await _roomRepository.loadRoomDetail(_room);
      final myVoices = await _roomRepository.loadSharableVoices();
      if (!mounted) return;
      final owner = remote && await _roomRepository.isRoomOwner(detail);
      setState(() {
        _room = detail;
        _myVoices = myVoices;
        _loading = false;
        _isOwner = owner;
      });
      _notifyParent();
      if (_shareFabCoach) _scheduleFabMeasure();
    } catch (_) {
      if (!mounted) return;
      var owner = false;
      try {
        if (await _roomRepository.usesRemote) {
          owner = await _roomRepository.isRoomOwner(_room);
        }
      } catch (_) {}
      setState(() {
        _loading = false;
        _isOwner = owner;
      });
    }
  }

  Future<void> _editRoom() async {
    final nameCtrl = TextEditingController(text: _room.name);
    final passCtrl = TextEditingController();
    final maxCtrl = TextEditingController(
      text: '${_room.maxParticipants > 0 ? _room.maxParticipants : 3}',
    );
    var usePass = _room.requiresPassword;

    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);

    _RoomEditResult? result;
    try {
      result = await showDialog<_RoomEditResult>(
        context: context,
        builder: (ctx) {
          return StatefulBuilder(
            builder: (ctx, setLocal) {
              return AlertDialog(
                backgroundColor: YeolpumtaTheme.surface,
                surfaceTintColor: Colors.transparent,
                title: Text(
                  '방 정보 수정',
                  style: TextStyle(
                    color: YeolpumtaTheme.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: nameCtrl,
                        decoration: fieldDecoration(
                          hint: '방 이름',
                          icon: Icons.meeting_room_outlined,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          '비밀번호로 입장만 허용',
                          style: TextStyle(
                            color: YeolpumtaTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        value: usePass,
                        activeThumbColor: YeolpumtaTheme.accent,
                        activeTrackColor: YeolpumtaTheme.accent.withValues(
                          alpha: 0.35,
                        ),
                        onChanged: (v) => setLocal(() => usePass = v),
                      ),
                      if (usePass) ...[
                        const SizedBox(height: 8),
                        TextField(
                          controller: passCtrl,
                          obscureText: true,
                          decoration: fieldDecoration(
                            hint: _room.requiresPassword
                                ? '새 비밀번호 (4자 이상)'
                                : '방 비밀번호',
                            icon: Icons.password_rounded,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      TextField(
                        controller: maxCtrl,
                        keyboardType: TextInputType.number,
                        decoration: fieldDecoration(
                          hint: '최대 참가 인원',
                          icon: Icons.group_outlined,
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(
                      '취소',
                      style: TextStyle(
                        color: YeolpumtaTheme.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  FilledButton(
                    onPressed: () {
                      final name = nameCtrl.text.trim();
                      if (name.isEmpty) {
                        messenger
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            const SnackBar(content: Text('방 이름을 입력해 주세요.')),
                          );
                        return;
                      }
                      if (usePass && passCtrl.text.trim().length < 4) {
                        messenger
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            const SnackBar(
                              content: Text('비밀번호는 4자 이상 입력해 주세요.'),
                            ),
                          );
                        return;
                      }
                      final maxVal =
                          int.tryParse(maxCtrl.text.trim()) ??
                          (_room.maxParticipants > 0 ? _room.maxParticipants : 3);
                      if (maxVal < 1) {
                        messenger
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            const SnackBar(
                              content: Text('최대 인원은 1 이상이어야 해요.'),
                            ),
                          );
                        return;
                      }
                      Navigator.pop(
                        ctx,
                        _RoomEditResult(
                          title: name,
                          usePassword: usePass,
                          password: passCtrl.text.trim(),
                          maxParticipants: maxVal,
                        ),
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: YeolpumtaTheme.accent,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('저장'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      nameCtrl.dispose();
      passCtrl.dispose();
      maxCtrl.dispose();
    }

    if (result == null || !mounted) return;

    try {
      final updated = await _roomRepository.updateRoom(
        roomId: _room.id,
        title: result.title,
        usePassword: result.usePassword,
        password: result.usePassword ? result.password : null,
        maxParticipants: result.maxParticipants,
      );
      if (!mounted) return;
      setState(() => _room = updated);
      _notifyParent();
      showToast(context, '방 정보를 저장했어요.');
    } catch (e) {
      if (!mounted) return;
      showToast(context, '$e');
    }
  }

  Future<void> _deleteRoom() async {
    final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: YeolpumtaTheme.surface,
            surfaceTintColor: Colors.transparent,
            title: Text(
              '방 삭제',
              style: TextStyle(
                color: YeolpumtaTheme.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            content: Text(
              '「${_room.name}」방을 삭제할까요? 이 작업은 되돌릴 수 없어요.',
              style: TextStyle(
                color: YeolpumtaTheme.textSecondary,
                height: 1.45,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  '취소',
                  style: TextStyle(
                    color: YeolpumtaTheme.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                ),
                child: const Text('삭제'),
              ),
            ],
          ),
        ) ??
        false;

    if (!ok || !mounted) return;

    try {
      await _roomRepository.deleteRoom(_room.id);
      if (!mounted) return;
      Navigator.of(context).pop<String>(_room.id);
    } catch (e) {
      if (!mounted) return;
      showToast(context, '$e');
    }
  }

  Future<void> _shareVoiceSheet() async {
    final updated = await showRoomShareVoicesSheet(
      context: context,
      room: _room,
      myVoices: _myVoices,
      roomRepository: _roomRepository,
    );
    if (!mounted || updated == null) return;
    setState(() => _room = updated);
    _notifyParent();
    showToast(context, '이 방에 공유 목록을 반영했어요.');
  }

  Future<void> _editSharedVoice(RoomSharedVoice v) async {
    final result = await showDialog<_EditSharedVoiceOutcome>(
      context: context,
      builder: (ctx) => _EditRoomSharedVoiceDialog(voice: v),
    );
    if (!mounted || result == null) return;

    try {
      final updated = await _roomRepository.updateRoomSharedVoice(
        room: _room,
        shareRecordId: v.id,
        accessScope: result.scope,
        shareDisplayTitle: result.shareDisplayTitle,
      );
      if (!mounted) return;
      setState(() => _room = updated);
      _notifyParent();
      showToast(context, '공유 정보를 저장했어요.');
    } catch (e) {
      if (!mounted) return;
      showToast(context, '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      key: _detailStackKey,
      fit: StackFit.expand,
      children: [
        Scaffold(
      backgroundColor: YeolpumtaTheme.bg,
      appBar: AppBar(
        title: Text(_room.name),
        actions: [
          if (_isOwner && !_loading)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (value) {
                if (value == 'edit') {
                  _editRoom();
                } else if (value == 'delete') {
                  _deleteRoom();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Text(
                    '방 정보 수정',
                    style: TextStyle(color: YeolpumtaTheme.textPrimary),
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    '방 삭제',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
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
      body: RefreshIndicator(
        onRefresh: () async => _load(),
        child: ListView(
          physics: (_shareFabCoach && _shareFabHole != null)
              ? const NeverScrollableScrollPhysics()
              : const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
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
                      onPressed: () => showToast(
                        context,
                        '친구에게 초대 코드를 알려 주면, 방 탭에서 「방 입장」으로 들어올 수 있어요.',
                      ),
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
                      VoiceCuteLeadingAvatar(
                        origin: VoiceOrigin.sharedRoom,
                        size: 44,
                        borderRadius: 12,
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
                      IconButton(
                        tooltip: '공유 이름·권한 수정',
                        icon: Icon(
                          Icons.edit_outlined,
                          color: YeolpumtaTheme.textSecondary,
                        ),
                        onPressed: () => _editSharedVoice(v),
                      ),
                      TextButton(
                        onPressed: () => showSharedVoicePlaySheet(
                          context,
                          roomId: _room.id,
                          voice: v,
                        ),
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: _shareFabKey,
        onPressed: _onShareFabPressed,
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
    ),
        if (_shareFabCoach && _shareFabHole != null && !_loading)
          Positioned.fill(
            child: SpotlightCoachOverlay(
              holeRect: _shareFabHole!,
              title: '내 음성 넘겨주기',
              body: '이 방 사람들이 쓸 수 있게 내 음성을 골라요.',
              tapHint: '👉 아래 긴 버튼을 눌러봐',
              holeRadius: 22,
            ),
          ),
      ],
    );
  }
}

class _EditSharedVoiceOutcome {
  const _EditSharedVoiceOutcome({
    required this.shareDisplayTitle,
    required this.scope,
  });

  final String shareDisplayTitle;
  final RoomVoiceAccessScope scope;
}

class _EditRoomSharedVoiceDialog extends StatefulWidget {
  const _EditRoomSharedVoiceDialog({required this.voice});

  final RoomSharedVoice voice;

  @override
  State<_EditRoomSharedVoiceDialog> createState() =>
      _EditRoomSharedVoiceDialogState();
}

class _EditRoomSharedVoiceDialogState extends State<_EditRoomSharedVoiceDialog> {
  late final TextEditingController _titleCtrl;
  late RoomVoiceAccessScope _scope;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.voice.voiceTitle);
    _scope = widget.voice.accessScope;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  static String _scopeLabel(RoomVoiceAccessScope s) {
    return switch (s) {
      RoomVoiceAccessScope.listenOnly => '듣기만',
      RoomVoiceAccessScope.downloadAllowed => '내려받기',
    };
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: YeolpumtaTheme.surface,
      surfaceTintColor: Colors.transparent,
      title: Text(
        '공유 음성 수정',
        style: TextStyle(
          color: YeolpumtaTheme.textPrimary,
          fontWeight: FontWeight.w800,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '방에 표시되는 이름과 권한을 바꿀 수 있어요.',
              style: TextStyle(
                color: YeolpumtaTheme.textSecondary,
                fontSize: 13,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                labelText: '방 표시 이름',
                filled: true,
                fillColor: YeolpumtaTheme.bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '공유 권한',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: YeolpumtaTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            DecoratedBox(
              decoration: BoxDecoration(
                color: YeolpumtaTheme.bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: YeolpumtaTheme.divider),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<RoomVoiceAccessScope>(
                    value: _scope,
                    isExpanded: true,
                    items: [
                      for (final opt in RoomVoiceAccessScope.values)
                        DropdownMenuItem(
                          value: opt,
                          child: Text(_scopeLabel(opt)),
                        ),
                    ],
                    onChanged: (next) {
                      if (next == null) return;
                      setState(() => _scope = next);
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            '취소',
            style: TextStyle(color: YeolpumtaTheme.accent),
          ),
        ),
        FilledButton(
          onPressed: () {
            final raw = _titleCtrl.text.trim();
            final titleSend =
                raw.isEmpty ? widget.voice.voiceTitle : raw;
            Navigator.pop(
              context,
              _EditSharedVoiceOutcome(
                shareDisplayTitle: titleSend,
                scope: _scope,
              ),
            );
          },
          child: const Text('저장'),
        ),
      ],
    );
  }
}
