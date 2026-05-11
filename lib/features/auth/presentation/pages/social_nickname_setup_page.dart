import 'package:flutter/material.dart';

import '../../../../app/services/app_services.dart';
import '../../../../app/theme/yeolpumta_theme.dart';
import '../../../shared/presentation/widgets/common_widgets.dart';
import '../../../shell/presentation/pages/main_shell_page.dart';
import '../../data/auth_api_client.dart';

/// 소셜 로그인 직후 — `PATCH /me/profile` 로 닉네임 등록
class SocialNicknameSetupPage extends StatefulWidget {
  const SocialNicknameSetupPage({
    super.key,
    required this.email,
    this.suggestedNickname = '',
  });

  final String email;
  final String suggestedNickname;

  @override
  State<SocialNicknameSetupPage> createState() =>
      _SocialNicknameSetupPageState();
}

class _SocialNicknameSetupPageState extends State<SocialNicknameSetupPage> {
  final _authService = AppServices.instance.authService;
  late final TextEditingController _nickCtrl;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final hint = widget.suggestedNickname.trim();
    final fallback = widget.email.contains('@')
        ? widget.email.split('@').first.trim()
        : '';
    _nickCtrl = TextEditingController(
      text: hint.isNotEmpty ? hint : fallback,
    );
  }

  @override
  void dispose() {
    _nickCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final nick = _nickCtrl.text.trim();
    if (nick.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('닉네임은 2자 이상 입력해 주세요.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (nick.length > 24) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('닉네임은 24자 이내로 입력해 주세요.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await _authService.updateNickname(nick);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil<void>(
        MaterialPageRoute<void>(builder: (_) => const MainShellPage()),
        (_) => false,
      );
    } on AuthApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: YeolpumtaTheme.bg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('닉네임 설정'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: YeolpumtaTheme.accentSoft,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: YeolpumtaTheme.divider),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.celebration_rounded,
                      color: YeolpumtaTheme.accent,
                      size: 32,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        '소셜 로그인을 완료했어요.\n앱에서 쓸 닉네임을 정해 주세요.',
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                          color: YeolpumtaTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '계정',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: YeolpumtaTheme.textSecondary.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.email.isEmpty ? '(이메일 없음)' : widget.email,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: YeolpumtaTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 22),
              TextField(
                controller: _nickCtrl,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submitting ? null : _submit(),
                decoration: fieldDecoration(
                  hint: '닉네임 (2~24자)',
                  icon: Icons.badge_outlined,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '마이페이지에서 언제든 바꿀 수 있어요.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: YeolpumtaTheme.textSecondary.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: YeolpumtaTheme.accent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        '시작하기',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
