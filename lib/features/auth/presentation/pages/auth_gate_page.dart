import 'package:flutter/material.dart';

import '../../../../app/services/app_services.dart';
import '../../../../app/theme/yeolpumta_theme.dart';
import '../../../shell/presentation/pages/main_shell_page.dart';
import '../../domain/auth_user.dart';
import 'login_page.dart';
import 'social_nickname_setup_page.dart';

class AuthGatePage extends StatefulWidget {
  const AuthGatePage({super.key});

  @override
  State<AuthGatePage> createState() => _AuthGatePageState();
}

class _AuthGatePageState extends State<AuthGatePage> {
  final _authService = AppServices.instance.authService;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final restored = await _authService.restoreSession();
    if (!mounted) return;
    final Widget home = switch (restored) {
      null => const LoginPage(),
      AuthUser u when u.needsSocialNicknameSetup => SocialNicknameSetupPage(
        email: u.email,
        suggestedNickname: u.nickName,
      ),
      _ => const MainShellPage(),
    };
    Navigator.of(context).pushReplacement<void, void>(
      MaterialPageRoute<void>(builder: (_) => home),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: YeolpumtaTheme.bg,
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
