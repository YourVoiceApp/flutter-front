import 'package:flutter/material.dart';

import 'theme/yeolpumta_theme.dart';
import '../features/auth/presentation/pages/login_page.dart';

class VoiceStudioApp extends StatelessWidget {
  const VoiceStudioApp({super.key});

  /// Used so dialogs still show after returning from the Google account UI.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Your Voice',
      theme: YeolpumtaTheme.light(),
      home: const LoginPage(),
    );
  }
}
