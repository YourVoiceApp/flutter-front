import 'package:flutter/material.dart';

import '../../../../app/services/app_services.dart';
import '../../../../app/theme/yeolpumta_theme.dart';
import '../../data/auth_api_client.dart';
import '../../domain/social_account_link.dart';
import '../../domain/user_profile.dart';

class AccountDetailPage extends StatefulWidget {
  const AccountDetailPage({super.key, this.onAccountDeleted});

  final VoidCallback? onAccountDeleted;

  @override
  State<AccountDetailPage> createState() => _AccountDetailPageState();
}

class _AccountDetailPageState extends State<AccountDetailPage> {
  final _authService = AppServices.instance.authService;
  final _profileRepository = AppServices.instance.userProfileRepository;

  UserProfile? _profile;
  List<SocialAccountLink> _socialAccounts = const [];
  bool _loading = true;
  bool _editing = false;
  bool _saving = false;
  bool _savingPassword = false;
  bool _deleting = false;

  final _nicknameCtrl = TextEditingController();
  final _currentPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _newPasswordAgainCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nicknameCtrl.dispose();
    _currentPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _newPasswordAgainCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final cached = await _profileRepository.loadProfile();
    try {
      await _authService.fetchCurrentUser();
      final socialAccounts = await _authService.fetchSocialAccounts();
      final refreshed = await _profileRepository.loadProfile();
      if (!mounted) return;
      setState(() {
        _profile = refreshed;
        _socialAccounts = socialAccounts;
        _nicknameCtrl.text = refreshed?.nickname ?? '';
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _profile = cached;
        _socialAccounts = const [];
        _nicknameCtrl.text = cached?.nickname ?? '';
        _loading = false;
      });
    }
  }

  void _beginEdit() {
    final profile = _profile;
    if (profile == null) return;
    setState(() {
      _editing = true;
      _nicknameCtrl.text = profile.nickname;
    });
  }

  void _cancelEdit() {
    final profile = _profile;
    setState(() {
      _editing = false;
      if (profile != null) {
        _nicknameCtrl.text = profile.nickname;
      }
    });
  }

  Future<void> _saveNickname() async {
    final profile = _profile;
    if (profile == null) return;
    final nick = _nicknameCtrl.text.trim();
    if (nick.length < 2 || nick.length > 16) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('닉네임은 2~16자로 입력해 주세요.')));
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      await _authService.updateNickname(nick);
      await _load();
      if (!mounted) return;
      setState(() => _editing = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('닉네임을 저장했어요.')));
    } on AuthApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _changePassword() async {
    final profile = _profile;
    if (profile == null) return;
    final newPassword = _newPasswordCtrl.text;
    final newPasswordAgain = _newPasswordAgainCtrl.text;
    if (profile.hasPassword && _currentPasswordCtrl.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('현재 비밀번호를 입력해 주세요.')));
      return;
    }
    if (newPassword.length < 8) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('새 비밀번호는 8자 이상으로 입력해 주세요.')));
      return;
    }
    if (newPassword != newPasswordAgain) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('새 비밀번호가 서로 달라요.')));
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _savingPassword = true);
    try {
      await _authService.updatePassword(
        currentPassword: profile.hasPassword ? _currentPasswordCtrl.text : null,
        newPassword: newPassword,
      );
      _currentPasswordCtrl.clear();
      _newPasswordCtrl.clear();
      _newPasswordAgainCtrl.clear();
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('비밀번호를 변경했어요.')));
    } on AuthApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _savingPassword = false);
    }
  }

  Future<void> _confirmDeleteAccount() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('회원 탈퇴'),
        content: const Text('계정을 삭제하면 현재 로그인도 해제돼요.'),
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

    setState(() => _deleting = true);
    try {
      await _authService.deleteAccount();
      if (!mounted) return;
      widget.onAccountDeleted?.call();
    } on AuthApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
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
                  '계정 정보를 불러오지 못했어요.\n다시 로그인해 주세요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.45,
                    color: YeolpumtaTheme.textSecondary.withValues(alpha: 0.95),
                  ),
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                _DetailTile(label: '이메일', value: _profile!.email, locked: true),
                const SizedBox(height: 12),
                if (!_editing) ...[
                  _DetailTile(label: '닉네임', value: _profile!.nickname),
                  const SizedBox(height: 12),
                  _DetailTile(
                    label: '가입일',
                    value: _dateLabel(_profile!.createdAt),
                  ),
                  const SizedBox(height: 20),
                  _SocialAccountsSection(accounts: _socialAccounts),
                  Padding(
                    padding: const EdgeInsets.only(top: 12, left: 4),
                    child: Text(
                      '이메일은 변경할 수 없어요.',
                      style: TextStyle(
                        fontSize: 12,
                        color: YeolpumtaTheme.textSecondary.withValues(
                          alpha: 0.88,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  _PasswordSection(
                    profile: _profile!,
                    currentPasswordCtrl: _currentPasswordCtrl,
                    newPasswordCtrl: _newPasswordCtrl,
                    newPasswordAgainCtrl: _newPasswordAgainCtrl,
                    saving: _savingPassword,
                    onSubmit: _changePassword,
                  ),
                  const SizedBox(height: 28),
                  OutlinedButton(
                    onPressed: _deleting ? null : _confirmDeleteAccount,
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
                    buildCounter:
                        (
                          context, {
                          required currentLength,
                          required isFocused,
                          maxLength,
                        }) => const SizedBox.shrink(),
                    decoration: InputDecoration(
                      hintText: '2~16자',
                      filled: true,
                      fillColor: YeolpumtaTheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: YeolpumtaTheme.divider,
                        ),
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
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _saving ? null : _saveNickname,
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
  });

  final String label;
  final String value;
  final bool locked;

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
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: YeolpumtaTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialAccountsSection extends StatelessWidget {
  const _SocialAccountsSection({required this.accounts});

  final List<SocialAccountLink> accounts;

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
          Text(
            '연결된 소셜 계정',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: YeolpumtaTheme.textSecondary.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 10),
          if (accounts.isEmpty)
            Text(
              '연결된 소셜 계정이 없어요.',
              style: TextStyle(
                fontSize: 14,
                color: YeolpumtaTheme.textSecondary.withValues(alpha: 0.92),
              ),
            )
          else
            ...accounts.map(
              (account) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        account.provider,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      account.email,
                      style: TextStyle(
                        fontSize: 13,
                        color: YeolpumtaTheme.textSecondary.withValues(
                          alpha: 0.92,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PasswordSection extends StatelessWidget {
  const _PasswordSection({
    required this.profile,
    required this.currentPasswordCtrl,
    required this.newPasswordCtrl,
    required this.newPasswordAgainCtrl,
    required this.saving,
    required this.onSubmit,
  });

  final UserProfile profile;
  final TextEditingController currentPasswordCtrl;
  final TextEditingController newPasswordCtrl;
  final TextEditingController newPasswordAgainCtrl;
  final bool saving;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: YeolpumtaTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: YeolpumtaTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '비밀번호 변경',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: YeolpumtaTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            profile.hasPassword
                ? '현재 비밀번호 확인 후 새 비밀번호로 바꿔요.'
                : '현재 비밀번호 없이 새 비밀번호를 설정할 수 있어요.',
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: YeolpumtaTheme.textSecondary.withValues(alpha: 0.92),
            ),
          ),
          if (profile.hasPassword) ...[
            const SizedBox(height: 14),
            TextField(
              controller: currentPasswordCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: '현재 비밀번호'),
            ),
          ],
          const SizedBox(height: 14),
          TextField(
            controller: newPasswordCtrl,
            obscureText: true,
            decoration: const InputDecoration(labelText: '새 비밀번호'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: newPasswordAgainCtrl,
            obscureText: true,
            onSubmitted: (_) => onSubmit(),
            decoration: const InputDecoration(labelText: '새 비밀번호 확인'),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: saving ? null : onSubmit,
            style: FilledButton.styleFrom(
              backgroundColor: YeolpumtaTheme.accent,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
            ),
            child: saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('비밀번호 저장'),
          ),
        ],
      ),
    );
  }
}
