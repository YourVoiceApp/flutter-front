import 'package:flutter/material.dart';

import '../../../../app/theme/yeolpumta_theme.dart';
import '../../data/user_profile_repository.dart';
import '../../domain/user_profile.dart';

/// 계정 정보 조회 → 수정 (이메일은 읽기 전용)
class AccountDetailPage extends StatefulWidget {
  const AccountDetailPage({
    super.key,
    required this.profileRepository,
    this.onAccountDeleted,
  });

  final UserProfileRepository profileRepository;
  final VoidCallback? onAccountDeleted;

  @override
  State<AccountDetailPage> createState() => _AccountDetailPageState();
}

class _AccountDetailPageState extends State<AccountDetailPage> {
  UserProfile? _profile;
  bool _loading = true;
  bool _editing = false;
  bool _saving = false;

  final _nicknameCtrl = TextEditingController();
  final _statusCtrl = TextEditingController();

  @override
  void dispose() {
    _nicknameCtrl.dispose();
    _statusCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final p = await widget.profileRepository.loadProfile();
    if (!mounted) return;
    setState(() {
      _profile = p;
      _nicknameCtrl.text = p?.nickname ?? '';
      _statusCtrl.text = p?.statusMessage ?? '';
      _loading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _beginEdit() {
    final p = _profile;
    if (p == null) return;
    setState(() {
      _editing = true;
      _nicknameCtrl.text = p.nickname;
      _statusCtrl.text = p.statusMessage;
    });
  }

  void _cancelEdit() {
    final p = _profile;
    setState(() {
      _editing = false;
      if (p != null) {
        _nicknameCtrl.text = p.nickname;
        _statusCtrl.text = p.statusMessage;
      }
    });
  }

  Future<void> _save() async {
    final p = _profile;
    if (p == null) return;
    final nick = _nicknameCtrl.text.trim();
    if (nick.length < 2 || nick.length > 16) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('닉네임은 2~16자로 입력해 주세요.')),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    await widget.profileRepository.updateProfile(
      p.copyWith(
        nickname: nick,
        statusMessage: _statusCtrl.text.trim(),
      ),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    await _load();
    if (!mounted) return;
    setState(() => _editing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('저장했어요.')),
    );
  }

  Future<void> _confirmDeleteAccount() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('회원 탈퇴'),
        content: const Text(
          '저장된 프로필 정보가 삭제돼요.\n(데모: 음성 라이브러리는 그대로예요.)',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('탈퇴'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await widget.profileRepository.clear();
    if (!mounted) return;
    widget.onAccountDeleted?.call();
  }

  String _dateLabel(DateTime d) {
    return '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YeolpumtaTheme.bg,
      appBar: AppBar(
        title: Text(_editing ? '계정 정보 수정' : '계정 정보'),
        actions: [
          if (!_loading && _profile != null)
            if (_editing)
              TextButton(
                onPressed: _saving ? null : _cancelEdit,
                child: const Text('취소'),
              )
            else
              TextButton(
                onPressed: _beginEdit,
                child: const Text(
                  '수정',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _profile == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      '저장된 계정이 없어요.\n회원가입을 먼저 해 주세요.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.45,
                        color:
                            YeolpumtaTheme.textSecondary.withValues(alpha: 0.95),
                      ),
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  children: [
                    if (!_editing) ...[
                      _DetailTile(
                        label: '이메일',
                        value: _profile!.email,
                        locked: true,
                      ),
                      const SizedBox(height: 12),
                      _DetailTile(
                        label: '닉네임',
                        value: _profile!.nickname,
                      ),
                      const SizedBox(height: 12),
                      _DetailTile(
                        label: '상태 메시지',
                        value: _profile!.statusMessage.isEmpty
                            ? '—'
                            : _profile!.statusMessage,
                        multiline: true,
                      ),
                      const SizedBox(height: 12),
                      _DetailTile(
                        label: '가입일',
                        value: _dateLabel(_profile!.createdAt),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8, left: 4),
                        child: Text(
                          '이메일은 변경할 수 없어요.',
                          style: TextStyle(
                            fontSize: 12,
                            color: YeolpumtaTheme.textSecondary
                                .withValues(alpha: 0.88),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      OutlinedButton(
                        onPressed: _confirmDeleteAccount,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade700,
                          side: BorderSide(color: Colors.red.shade700),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('회원 탈퇴'),
                      ),
                    ] else ...[
                      const Text(
                        '이메일',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: YeolpumtaTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: YeolpumtaTheme.bg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: YeolpumtaTheme.divider),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.lock_outline_rounded,
                              size: 18,
                              color: YeolpumtaTheme.textSecondary
                                  .withValues(alpha: 0.75),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _profile!.email,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 6, left: 2),
                        child: Text(
                          '이메일은 변경할 수 없어요.',
                          style: TextStyle(
                            fontSize: 11,
                            color: YeolpumtaTheme.textSecondary
                                .withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        '닉네임',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: YeolpumtaTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _nicknameCtrl,
                        maxLength: 16,
                        buildCounter: (
                          context, {
                          required currentLength,
                          required isFocused,
                          maxLength,
                        }) =>
                            const SizedBox.shrink(),
                        decoration: InputDecoration(
                          hintText: '2~16자',
                          filled: true,
                          fillColor: YeolpumtaTheme.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: YeolpumtaTheme.divider),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: YeolpumtaTheme.accent,
                              width: 1.2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '상태 메시지',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: YeolpumtaTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _statusCtrl,
                        maxLines: 3,
                        maxLength: 120,
                        decoration: InputDecoration(
                          hintText: '한 줄 소개 (선택)',
                          filled: true,
                          fillColor: YeolpumtaTheme.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: YeolpumtaTheme.divider),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: YeolpumtaTheme.accent,
                              width: 1.2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _saving ? null : _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: YeolpumtaTheme.accent,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                '저장',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ],
                  ],
                ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({
    required this.label,
    required this.value,
    this.locked = false,
    this.multiline = false,
  });

  final String label;
  final String value;
  final bool locked;
  final bool multiline;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: YeolpumtaTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: YeolpumtaTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: YeolpumtaTheme.textSecondary.withValues(alpha: 0.9),
                ),
              ),
              if (locked) ...[
                const SizedBox(width: 6),
                Icon(
                  Icons.lock_outline_rounded,
                  size: 14,
                  color: YeolpumtaTheme.textSecondary.withValues(alpha: 0.65),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: multiline ? 15 : 16,
              fontWeight: FontWeight.w600,
              height: multiline ? 1.4 : 1.2,
              color: YeolpumtaTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
