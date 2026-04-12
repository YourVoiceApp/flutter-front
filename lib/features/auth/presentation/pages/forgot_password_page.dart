import 'package:flutter/material.dart';

import '../../../shared/presentation/widgets/common_widgets.dart';
import '../../../../app/theme/yeolpumta_theme.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YeolpumtaTheme.bg,
      appBar: AppBar(
        title: const Text('비밀번호 찾기'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          children: [
            Text(
              '현재 백엔드 명세에는 비밀번호 찾기/재설정 전용 API가 없어요. 로그인 후 계정 정보 화면에서 비밀번호 변경을 사용할 수 있어요.',
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: YeolpumtaTheme.textSecondary.withValues(alpha: 0.95),
              ),
            ),
            const SizedBox(height: 20),
            WhiteCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    '지원 범위',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: YeolpumtaTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text('• 로그인 후 `계정 정보` 화면에서 비밀번호 변경 가능'),
                  SizedBox(height: 6),
                  Text('• 비밀번호가 없는 소셜 계정도 새 비밀번호 설정 가능'),
                  SizedBox(height: 6),
                  Text('• 별도 이메일 인증 기반 비밀번호 찾기 API는 아직 없음'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
