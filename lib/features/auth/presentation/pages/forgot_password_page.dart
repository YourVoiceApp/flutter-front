import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/presentation/widgets/common_widgets.dart';
import '../../data/user_profile_repository.dart';
import '../../../../app/theme/yeolpumta_theme.dart';

/// 이메일 인증 → 비밀번호 재설정 (데모 — 실제 메일 발송 없음)
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _repo = UserProfileRepository();
  final _emailCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  final _pwAgainCtrl = TextEditingController();

  int _step = 0;
  bool _codeSent = false;
  bool _emailVerified = false;
  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _busy = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    _pwCtrl.dispose();
    _pwAgainCtrl.dispose();
    super.dispose();
  }

  bool _looksLikeEmail(String s) {
    final t = s.trim();
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(t);
  }

  Future<void> _sendCode() async {
    FocusScope.of(context).unfocus();
    final email = _emailCtrl.text.trim();
    if (!_looksLikeEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이메일 형식을 확인해 주세요.')),
      );
      return;
    }
    final exists = await _repo.hasEmail(email);
    if (!mounted) return;
    if (!exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('가입된 이메일이 없어요. 회원가입을 먼저 해 주세요.')),
      );
      return;
    }
    setState(() {
      _codeSent = true;
      _emailVerified = false;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('데모: 인증번호가 발송됐다고 가정해요. 6자리를 입력해 주세요.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _confirmCode() {
    FocusScope.of(context).unfocus();
    final code = _codeCtrl.text.trim();
    if (code.length != 6 || int.tryParse(code) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('인증번호 6자리(숫자)를 입력해 주세요.')),
      );
      return;
    }
    setState(() {
      _emailVerified = true;
      _step = 2;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('인증이 완료됐어요. 새 비밀번호를 설정해 주세요.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _submitNewPassword() async {
    FocusScope.of(context).unfocus();
    final p = _pwCtrl.text;
    final p2 = _pwAgainCtrl.text;
    if (p.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호는 8자 이상이에요.')),
      );
      return;
    }
    if (p != p2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호가 서로 달라요.')),
      );
      return;
    }
    setState(() => _busy = true);
    await _repo.updatePassword(p);
    if (!mounted) return;
    setState(() => _busy = false);
    Navigator.of(context).pop<bool>(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YeolpumtaTheme.bg,
      appBar: AppBar(
        title: Text(_step < 2 ? '비밀번호 찾기' : '비밀번호 재설정'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          children: [
            Text(
              _step < 2
                  ? '가입하신 이메일로 인증번호를 받고, 확인 후 새 비밀번호를 설정해요.'
                  : '새 비밀번호를 입력해 주세요.',
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: YeolpumtaTheme.textSecondary.withValues(alpha: 0.95),
              ),
            ),
            const SizedBox(height: 20),
            if (_step < 2) ...[
              WhiteCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '이메일',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: YeolpumtaTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      enabled: !_emailVerified,
                      decoration: fieldDecoration(
                        hint: '가입 이메일',
                        icon: Icons.alternate_email_rounded,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      '이메일 인증',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: YeolpumtaTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _codeCtrl,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            enabled: _codeSent && !_emailVerified,
                            decoration: fieldDecoration(
                              hint: '인증번호 6자리',
                              icon: Icons.pin_outlined,
                            ).copyWith(counterText: ''),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: OutlinedButton(
                            onPressed: _emailVerified ? null : _sendCode,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: YeolpumtaTheme.accent,
                              side: const BorderSide(color: YeolpumtaTheme.accent),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              '인증번호\n받기',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (!_emailVerified) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _codeSent ? _confirmCode : null,
                          child: const Text('인증 확인'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ] else ...[
              WhiteCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _pwCtrl,
                      obscureText: _obscure1,
                      decoration: fieldDecoration(
                        hint: '새 비밀번호 (8자 이상)',
                        icon: Icons.lock_outline_rounded,
                        suffix: IconButton(
                          onPressed: () =>
                              setState(() => _obscure1 = !_obscure1),
                          icon: Icon(
                            _obscure1
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _pwAgainCtrl,
                      obscureText: _obscure2,
                      onSubmitted: (_) => _submitNewPassword(),
                      decoration: fieldDecoration(
                        hint: '새 비밀번호 확인',
                        icon: Icons.lock_outline_rounded,
                        suffix: IconButton(
                          onPressed: () =>
                              setState(() => _obscure2 = !_obscure2),
                          icon: Icon(
                            _obscure2
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    FilledButton(
                      onPressed: _busy ? null : _submitNewPassword,
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
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              '비밀번호 재설정 완료',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
