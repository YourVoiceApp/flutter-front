import 'package:flutter/material.dart';

import 'theme/yeolpumta_theme.dart';
import '../features/auth/presentation/pages/login_page.dart';

class VoiceStudioApp extends StatelessWidget {
  const VoiceStudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Your Voice',
      theme: YeolpumtaTheme.light(),
      home: const LoginPage(),
    );
  }
}
