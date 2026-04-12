import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/presentation/widgets/common_widgets.dart';
import '../../data/auth_api_client.dart';
import '../../data/auth_service.dart';
import '../../../shell/presentation/pages/main_shell_page.dart';
import '../../../../app/theme/yeolpumta_theme.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _authService = AuthService();
  final _nicknameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _passwordAgainCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _obscurePasswordAgain = true;
  bool _codeSent = false;
  bool _emailVerified = false;
  bool _sendingCode = false;
  bool _verifyingCode = false;
  bool _submitting = false;

  @override
  void dispose() {
    _nicknameCtrl.dispose();
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    _passwordCtrl.dispose();
    _passwordAgainCtrl.dispose();
    super.dispose();
  }

  bool _looksLikeEmail(String s) {
    final t = s.trim();
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(t);
  }

  Future<void> _sendVerificationCode() async {
    FocusScope.of(context).unfocus();
    final email = _emailCtrl.text.trim();
    if (!_looksLikeEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이메일 형식을 확인해 주세요.')),
      );
      return;
    }
    setState(() => _sendingCode = true);
    try {
      await _authService.sendEmailVerification(email: email);
      if (!mounted) return;
      setState(() {
        _codeSent = true;
        _emailVerified = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('인증 메일을 보냈어요. 메일의 6자리 코드를 입력해 주세요.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on AuthApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _sendingCode = false);
    }
  }

  Future<void> _confirmVerificationCode() async {
    FocusScope.of(context).unfocus();
    final email = _emailCtrl.text.trim();
    final code = _codeCtrl.text.trim();
    if (!_looksLikeEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이메일을 확인해 주세요.')),
      );
      return;
    }
    if (code.length != 6 || int.tryParse(code) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('인증번호 6자리(숫자)를 입력해 주세요.')),
      );
      return;
    }
    setState(() => _verifyingCode = true);
    try {
      await _authService.verifyEmailCode(
        email: email,
        code: code,
      );
      if (!mounted) return;
      setState(() => _emailVerified = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('이메일 인증을 완료했어요.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on AuthApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _verifyingCode = false);
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final nick = _nicknameCtrl.text.trim();
    if (nick.length < 2 || nick.length > 16) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('닉네임은 2~16자로 입력해 주세요.')),
      );
      return;
    }
    if (!_looksLikeEmail(_emailCtrl.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이메일을 확인해 주세요.')),
      );
      return;
    }
    if (!_emailVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이메일 인증을 먼저 완료해 주세요.')),
      );
      return;
    }
    final p = _passwordCtrl.text;
    final p2 = _passwordAgainCtrl.text;
    if (p.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호는 8자 이상으로 설정해 주세요.')),
      );
      return;
    }
    if (p != p2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호가 서로 달라요.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await _authService.signUpWithEmail(
        nickName: nick,
        email: _emailCtrl.text.trim(),
        password: p,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement<void, void>(
        MaterialPageRoute<void>(builder: (_) => const MainShellPage()),
      );
    } on AuthApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('회원가입 중 오류가 발생했어요: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YeolpumtaTheme.bg,
      appBar: AppBar(
        title: const Text('회원가입'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          children: [
            Text(
              '계정 정보를 입력해 주세요.',
              style: TextStyle(
                fontSize: 15,
                height: 1.45,
                color: YeolpumtaTheme.textSecondary.withValues(alpha: 0.95),
              ),
            ),
            const SizedBox(height: 18),
            WhiteCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                    textInputAction: TextInputAction.next,
                    maxLength: 16,
                    buildCounter: (
                      context, {
                      required currentLength,
                      required isFocused,
                      maxLength,
                    }) =>
                        const SizedBox.shrink(),
                    decoration: fieldDecoration(
                      hint: '앱에서 사용할 이름',
                      icon: Icons.badge_outlined,
                    ),
                  ),
                  const SizedBox(height: 18),
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
                    autofillHints: const [AutofillHints.email],
                    textInputAction: TextInputAction.next,
                    onChanged: (_) {
                      if (_codeSent || _emailVerified) {
                        setState(() {
                          _codeSent = false;
                          _emailVerified = false;
                          _codeCtrl.clear();
                        });
                      }
                    },
                    decoration: fieldDecoration(
                      hint: 'example@email.com',
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
                  const SizedBox(height: 6),
                  Text(
                    '인증번호를 받은 뒤 6자리를 입력하고 확인해 주세요.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: YeolpumtaTheme.textSecondary.withValues(alpha: 0.88),
                    ),
                  ),
                  const SizedBox(height: 10),
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
                          textInputAction: TextInputAction.next,
                          enabled: _codeSent && !_emailVerified,
                          decoration: fieldDecoration(
                            hint: '인증번호 6자리',
                            icon: Icons.pin_outlined,
                          ).copyWith(
                            counterText: '',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: OutlinedButton(
                          onPressed: (_emailVerified || _sendingCode || _submitting)
                              ? null
                              : _sendVerificationCode,
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
                          child: _sendingCode
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text(
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
                        onPressed: (_codeSent && !_verifyingCode && !_submitting)
                            ? _confirmVerificationCode
                            : null,
                        child: _verifyingCode
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('인증 확인'),
                      ),
                    ),
                  ],
                  if (_emailVerified) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 18,
                          color: Colors.green.shade600,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '이메일 인증 완료',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 18),
                  const Text(
                    '비밀번호',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: YeolpumtaTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passwordCtrl,
                    obscureText: _obscurePassword,
                    autofillHints: const [AutofillHints.newPassword],
                    textInputAction: TextInputAction.next,
                    decoration: fieldDecoration(
                      hint: '8자 이상',
                      icon: Icons.lock_outline_rounded,
                      suffix: IconButton(
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    '비밀번호 확인',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: YeolpumtaTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passwordAgainCtrl,
                    obscureText: _obscurePasswordAgain,
                    autofillHints: const [AutofillHints.newPassword],
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                    decoration: fieldDecoration(
                      hint: '비밀번호 다시 입력',
                      icon: Icons.lock_outline_rounded,
                      suffix: IconButton(
                        onPressed: () {
                          setState(
                            () => _obscurePasswordAgain = !_obscurePasswordAgain,
                          );
                        },
                        icon: Icon(
                          _obscurePasswordAgain
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _submitting ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: YeolpumtaTheme.accent,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              '가입 완료',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
