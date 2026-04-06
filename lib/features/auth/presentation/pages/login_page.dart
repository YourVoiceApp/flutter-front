import 'package:flutter/material.dart';

import '../../../shared/presentation/pages/placeholder_page.dart';
import '../../../shared/presentation/widgets/common_widgets.dart';
import '../../../shell/presentation/pages/main_shell_page.dart';
import '../../../../app/theme/yeolpumta_theme.dart';
import 'sign_up_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _openPlaceholder(String title) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => PlaceholderPage(title: title, message: '$title 화면 (UI 데모)'),
      ),
    );
  }

  void _submitLogin() {
    FocusScope.of(context).unfocus();
    Navigator.of(context).pushReplacement<void, void>(
      MaterialPageRoute<void>(builder: (_) => const MainShellPage()),
    );
  }

  void _socialComingSoon(String name) {
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$name 로그인은 연동 예정이에요.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YeolpumtaTheme.bg,
      appBar: AppBar(
        title: const Text('Your Voice'),
        actions: [
          TextButton(
            onPressed: _submitLogin,
            child: const Text(
              '시작',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: YeolpumtaTheme.accent,
              ),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: YeolpumtaTheme.surface,
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(color: YeolpumtaTheme.bg),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    '메뉴',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: YeolpumtaTheme.textPrimary,
                    ),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.folder_outlined, color: YeolpumtaTheme.accent),
                title: const Text('프로젝트'),
                onTap: () {
                  Navigator.pop(context);
                  _openPlaceholder('프로젝트');
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings_outlined, color: YeolpumtaTheme.accent),
                title: const Text('설정'),
                onTap: () {
                  Navigator.pop(context);
                  _openPlaceholder('설정');
                },
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: [
            const SizedBox(height: 12),
            Center(
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: YeolpumtaTheme.accentSoft,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.graphic_eq_rounded,
                      size: 36,
                      color: YeolpumtaTheme.accent,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '그리운 목소리를\n언제든지 다시 듣기',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                      color: YeolpumtaTheme.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '녹음하고 학습하면, 문장으로 불러낼 수 있어요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.45,
                      color: YeolpumtaTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            WhiteCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '로그인',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: YeolpumtaTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: fieldDecoration(
                      hint: '이메일',
                      icon: Icons.alternate_email_rounded,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    autofillHints: const [AutofillHints.password],
                    decoration: fieldDecoration(
                      hint: '비밀번호',
                      icon: Icons.lock_outline_rounded,
                      suffix: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _submitLogin,
                      style: FilledButton.styleFrom(
                        backgroundColor: YeolpumtaTheme.accent,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        '로그인',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        FocusScope.of(context).unfocus();
                        Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            builder: (_) => const SignUpPage(),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: YeolpumtaTheme.accent,
                        minimumSize: const Size.fromHeight(52),
                        side: const BorderSide(color: YeolpumtaTheme.accent, width: 1.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        '회원가입',
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
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(child: Divider(color: YeolpumtaTheme.divider, height: 1)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text(
                    '또는 소셜 계정으로',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: YeolpumtaTheme.textSecondary.withValues(alpha: 0.9),
                    ),
                  ),
                ),
                Expanded(child: Divider(color: YeolpumtaTheme.divider, height: 1)),
              ],
            ),
            const SizedBox(height: 20),
            _SocialLoginButton(
              label: 'Google로 계속하기',
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1F1F1F),
              borderColor: const Color(0xFFDADCE0),
              leading: _SocialMark.google(),
              onPressed: () => _socialComingSoon('Google'),
            ),
            const SizedBox(height: 10),
            _SocialLoginButton(
              label: '카카오로 시작하기',
              backgroundColor: const Color(0xFFFEE500),
              foregroundColor: const Color(0xFF191919),
              borderColor: const Color(0xFFFEE500),
              leading: _SocialMark.kakao(),
              onPressed: () => _socialComingSoon('카카오'),
            ),
            const SizedBox(height: 10),
            _SocialLoginButton(
              label: '네이버로 시작하기',
              backgroundColor: const Color(0xFF03C75A),
              foregroundColor: Colors.white,
              borderColor: const Color(0xFF03C75A),
              leading: _SocialMark.naver(),
              onPressed: () => _socialComingSoon('네이버'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 공통 앱들과 비슷한 전체 너비 소셜 버튼 (로고 에셋 없이 기호만)
class _SocialLoginButton extends StatelessWidget {
  const _SocialLoginButton({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
    required this.leading,
    required this.onPressed,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;
  final Widget leading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          height: 52,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: backgroundColor == Colors.white
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: leading,
                ),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    color: foregroundColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialMark {
  static Widget google() {
    return SizedBox(
      width: 28,
      height: 28,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFE8EAED)),
        ),
        child: const Center(
          child: Text(
            'G',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF4285F4),
              height: 1,
            ),
          ),
        ),
      ),
    );
  }

  static Widget kakao() {
    return SizedBox(
      width: 28,
      height: 28,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF191919).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Center(
          child: Icon(
            Icons.chat_bubble_rounded,
            size: 16,
            color: Color(0xFF191919),
          ),
        ),
      ),
    );
  }

  static Widget naver() {
    return SizedBox(
      width: 28,
      height: 28,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Center(
          child: Text(
            'N',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}
