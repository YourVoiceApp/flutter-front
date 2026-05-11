import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../shared/presentation/pages/placeholder_page.dart';
import '../../../shared/presentation/widgets/common_widgets.dart';
import '../../../shell/presentation/pages/main_shell_page.dart';
import '../../../../app/app.dart';
import '../../../../app/config/auth_config.dart';
import '../../../../app/services/app_services.dart';
import '../../../../app/theme/yeolpumta_theme.dart';
import '../../data/auth_api_client.dart';
import '../../data/google_auth_flow_exception.dart';
import '../../domain/auth_user.dart';
import 'sign_up_page.dart';
import 'social_nickname_setup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _services = AppServices.instance;
  bool _obscurePassword = true;
  bool _loggingIn = false;
  bool _googleSigningIn = false;
  bool _kakaoSigningIn = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _openPlaceholder(String title) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) =>
            PlaceholderPage(title: title, message: '$title 화면 (UI 데모)'),
      ),
    );
  }

  Future<void> _submitLogin() async {
    FocusScope.of(context).unfocus();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('이메일과 비밀번호를 입력해 주세요.')));
      return;
    }
    setState(() => _loggingIn = true);
    try {
      await _services.authService.signInWithEmail(
        email: email,
        password: password,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement<void, void>(
        MaterialPageRoute<void>(builder: (_) => const MainShellPage()),
      );
    } on AuthApiException catch (e) {
      await _showAuthErrorDialog(
        title: e.isNetworkError ? '로그인 서버에 연결할 수 없어요' : '로그인에 실패했어요',
        body: e.message,
      );
    } on StateError catch (e) {
      await _showAuthErrorDialog(title: '로그인 상태를 저장하지 못했어요', body: e.message);
    } catch (e) {
      await _showAuthErrorDialog(title: '예상하지 못한 로그인 오류', body: '$e');
    } finally {
      if (mounted) setState(() => _loggingIn = false);
    }
  }

  void _openMainOrNicknameSetup(AuthUser user) {
    if (!mounted) return;
    if (user.needsSocialNicknameSetup) {
      Navigator.of(context).pushReplacement<void, void>(
        MaterialPageRoute<void>(
          builder: (_) => SocialNicknameSetupPage(
            email: user.email,
            suggestedNickname: user.nickName,
          ),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement<void, void>(
        MaterialPageRoute<void>(builder: (_) => const MainShellPage()),
      );
    }
  }

  void _continueAsGuest() {
    FocusScope.of(context).unfocus();
    Navigator.of(context).pushReplacement<void, void>(
      MaterialPageRoute<void>(
        builder: (_) => const MainShellPage(isGuestMode: true),
      ),
    );
  }

  Future<void> _showAuthErrorDialog({
    required String title,
    required String body,
  }) async {
    Future<void> open(BuildContext dialogContext) async {
      await showDialog<void>(
        context: dialogContext,
        useRootNavigator: true,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(child: Text(body)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }

    final root = VoiceStudioApp.navigatorKey.currentContext;
    if (root != null && root.mounted) {
      await open(root);
      return;
    }
    if (context.mounted) {
      await open(context);
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = VoiceStudioApp.navigatorKey.currentContext;
      if (c != null && c.mounted) {
        open(c);
      }
    });
  }

  Future<void> _showGoogleAuthDiagnostic(GoogleAuthFlowException e) async {
    var detail = e.detail;
    if (e.stage == GoogleAuthFailureStage.backend &&
        detail.contains('localhost')) {
      detail =
          '$detail\n\nTip: Default API is the deploy server. If you overrode '
          'AUTH_API_BASE to localhost, the Android emulator cannot reach your PC '
          'that way — use http://10.0.2.2:YOUR_PORT for a local backend only.';
    }
    final stageLabel = switch (e.stage) {
      GoogleAuthFailureStage.google => 'Stage: Google (account / idToken)',
      GoogleAuthFailureStage.backend => 'Stage: Backend API',
      GoogleAuthFailureStage.local => 'Stage: Save on device',
    };
    final headline = switch (e.stage) {
      GoogleAuthFailureStage.google => 'Problem at Google sign-in step',
      GoogleAuthFailureStage.backend =>
        'Problem calling your server (network / URL / HTTP error)',
      GoogleAuthFailureStage.local => 'Problem saving login on this device',
    };
    await _showAuthErrorDialog(
      title: headline,
      body: '[$stageLabel]\n${e.title}\n\n$detail',
    );
  }

  Future<void> _signInWithGoogle() async {
    FocusScope.of(context).unfocus();
    setState(() => _googleSigningIn = true);
    try {
      await _services.googleBackendAuth.signInExchangeAndPersist();
      if (!mounted) return;
      final user = await _services.authService.fetchCurrentUser();
      if (!mounted) return;
      _openMainOrNicknameSetup(user);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        await _showAuthErrorDialog(
          title: 'Google sign-in did not finish',
          body:
              'You may have closed the screen, or Google stopped the flow.\n\n'
              'If you saw a message like a linked account (e.g. Kakao), '
              'Google may treat that as cancel - try another Google account '
              "or complete the steps on Google's screen.\n\n"
              'Code: canceled\n'
              '${e.description ?? ''}',
        );
        return;
      }
      if (e.code == GoogleSignInExceptionCode.interrupted) {
        await _showAuthErrorDialog(
          title: 'Google sign-in was interrupted',
          body:
              'Common causes after picking an account:\n\n'
              '• Default API is ${AuthConfig.deployedApiBaseUrl}. If you pointed '
              'AUTH_API_BASE at localhost on an emulator, use '
              'http://10.0.2.2:9090 for a PC-local server instead.\n'
              '• Server not running or blocked port / firewall\n'
              '• Android OAuth client: package name + debug SHA-1 must match\n\n'
              'Code: interrupted\n'
              '${e.description ?? e.toString()}',
        );
        return;
      }
      await _showAuthErrorDialog(
        title: 'Google sign-in failed',
        body: e.description?.isNotEmpty == true ? e.description! : e.toString(),
      );
    } on GoogleAuthFlowException catch (e) {
      await _showGoogleAuthDiagnostic(e);
    } on AuthApiException catch (e) {
      await _showAuthErrorDialog(
        title: e.isNetworkError
            ? 'Cannot reach backend server'
            : 'Backend returned an error',
        body:
            '${e.isNetworkError ? "Network / address / timeout. " : ""}'
            '${e.message}',
      );
    } on PlatformException catch (e) {
      await _showAuthErrorDialog(
        title: 'Google sign-in (platform)',
        body: '${e.message ?? e.code}\n${e.details ?? ''}',
      );
    } on UnsupportedError catch (e) {
      await _showAuthErrorDialog(
        title: 'Not supported here',
        body: e.message ?? 'Google sign-in is not available on this platform.',
      );
    } on StateError catch (e) {
      await _showAuthErrorDialog(title: 'Error', body: e.message);
    } catch (e) {
      await _showAuthErrorDialog(title: 'Unexpected error', body: '$e');
    } finally {
      if (mounted) setState(() => _googleSigningIn = false);
    }
  }

  Future<void> _signInWithKakao() async {
    FocusScope.of(context).unfocus();
    setState(() => _kakaoSigningIn = true);
    try {
      await _services.kakaoBackendAuth.signInExchangeAndPersist();
      if (!mounted) return;
      final user = await _services.authService.fetchCurrentUser();
      if (!mounted) return;
      _openMainOrNicknameSetup(user);
    } on AuthApiException catch (e) {
      await _showAuthErrorDialog(
        title: e.isNetworkError
            ? 'Cannot reach backend server'
            : 'Backend returned an error',
        body:
            '${e.isNetworkError ? "Network / address / timeout. " : ""}'
            '${e.message}',
      );
    } on PlatformException catch (e) {
      final title = e.code == 'CANCELED'
          ? 'Kakao sign-in canceled'
          : 'Kakao sign-in failed';
      await _showAuthErrorDialog(
        title: title,
        body: '${e.message ?? e.code}\n${e.details ?? ''}',
      );
    } on UnsupportedError catch (e) {
      await _showAuthErrorDialog(
        title: 'Not supported here',
        body: e.message ?? 'Kakao sign-in is not available on this platform.',
      );
    } on StateError catch (e) {
      await _showAuthErrorDialog(
        title: 'Kakao configuration or response error',
        body: e.message,
      );
    } catch (e) {
      await _showAuthErrorDialog(
        title: 'Unexpected Kakao login error',
        body: '$e',
      );
    } finally {
      if (mounted) setState(() => _kakaoSigningIn = false);
    }
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
                leading: const Icon(
                  Icons.folder_outlined,
                  color: YeolpumtaTheme.accent,
                ),
                title: const Text('프로젝트'),
                onTap: () {
                  Navigator.pop(context);
                  _openPlaceholder('프로젝트');
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.settings_outlined,
                  color: YeolpumtaTheme.accent,
                ),
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
                  Semantics(
                    label: '소중한 사람의 목소리를 남기는 일러스트',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(26),
                      child: SizedBox(
                        width: 260,
                        height: 168,
                        child: Image.asset(
                          'assets/images/login_hero.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const _LoginHeroFallback(),
                        ),
                      ),
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
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        FocusScope.of(context).unfocus();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              '현재 백엔드에 비밀번호 찾기 API가 없어 앱 내에서 지원하지 않아요.',
                            ),
                          ),
                        );
                      },
                      child: const Text('비밀번호 찾기'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _loggingIn ? null : _submitLogin,
                      style: FilledButton.styleFrom(
                        backgroundColor: YeolpumtaTheme.accent,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: _loggingIn
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
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
                        side: const BorderSide(
                          color: YeolpumtaTheme.accent,
                          width: 1.2,
                        ),
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
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: _loggingIn ? null : _continueAsGuest,
                      child: const Text('로그인 없이 둘러보기'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: Divider(color: YeolpumtaTheme.divider, height: 1),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text(
                    '또는 소셜 계정으로',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: YeolpumtaTheme.textSecondary.withValues(
                        alpha: 0.9,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Divider(color: YeolpumtaTheme.divider, height: 1),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _SocialLoginButton(
              label: 'Google로 계속하기',
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1F1F1F),
              borderColor: const Color(0xFFDADCE0),
              leading: _SocialMark.google(),
              isLoading: _googleSigningIn,
              onPressed: _signInWithGoogle,
            ),
            const SizedBox(height: 10),
            _SocialLoginButton(
              label: '카카오로 시작하기',
              backgroundColor: const Color(0xFFFEE500),
              foregroundColor: const Color(0xFF191919),
              borderColor: const Color(0xFFFEE500),
              leading: _SocialMark.kakao(),
              isLoading: _kakaoSigningIn,
              onPressed: _signInWithKakao,
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
    this.isLoading = false,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;
  final Widget leading;
  final VoidCallback onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onPressed,
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
                  child: isLoading
                      ? SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: foregroundColor.withValues(alpha: 0.85),
                          ),
                        )
                      : leading,
                ),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    color: foregroundColor.withValues(
                      alpha: isLoading ? 0.45 : 1,
                    ),
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
}

/// [Image.asset] 실패 시 보여 줄 히어로 장면
class _LoginHeroFallback extends StatelessWidget {
  const _LoginHeroFallback();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _LoginHeroFallbackPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _LoginHeroFallbackPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final bg = Paint()
      ..shader = LinearGradient(
        colors: [
          YeolpumtaTheme.accentSoft,
          Colors.white,
          const Color(0xFFFFF7FB),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);
    canvas.drawRect(rect, bg);

    final left = size.width * 0.22;
    final baseY = size.height * 0.62;
    final pSoft = Paint()..color = YeolpumtaTheme.accent.withValues(alpha: 0.22);
    canvas.drawCircle(Offset(left, baseY), size.width * 0.12, pSoft);
    canvas.drawCircle(
      Offset(size.width * 0.78, baseY - size.height * 0.06),
      size.width * 0.1,
      pSoft,
    );

    final heart = Path();
    final hc = Offset(size.width * 0.5, size.height * 0.38);
    const hs = 18.0;
    heart.addOval(
      Rect.fromCenter(
        center: hc + const Offset(-hs * 0.28, -hs * 0.2),
        width: hs * 0.75,
        height: hs * 0.75,
      ),
    );
    heart.addOval(
      Rect.fromCenter(
        center: hc + const Offset(hs * 0.28, -hs * 0.2),
        width: hs * 0.75,
        height: hs * 0.75,
      ),
    );
    heart.moveTo(hc.dx, hc.dy + hs * 0.55);
    heart.lineTo(hc.dx - hs * 0.65, hc.dy);
    heart.quadraticBezierTo(hc.dx - hs * 0.55, hc.dy - hs * 0.65, hc.dx, hc.dy - hs * 0.35);
    heart.lineTo(hc.dx + hs * 0.65, hc.dy);
    heart.quadraticBezierTo(hc.dx + hs * 0.55, hc.dy - hs * 0.65, hc.dx, hc.dy - hs * 0.35);
    heart.close();
    canvas.drawPath(
      heart,
      Paint()..color = const Color(0xFFF472B6).withValues(alpha: 0.55),
    );

    final mic = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.72),
        width: size.width * 0.14,
        height: size.height * 0.22,
      ),
      const Radius.circular(8),
    );
    canvas.drawRRect(mic, Paint()..color = YeolpumtaTheme.accent.withValues(alpha: 0.85));
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.87),
      size.width * 0.06,
      Paint()..color = YeolpumtaTheme.accent.withValues(alpha: 0.45),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
