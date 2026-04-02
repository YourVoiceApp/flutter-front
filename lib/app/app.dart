import 'package:flutter/material.dart';
import '../features/auth/presentation/pages/login_page.dart';

class VoiceStudioApp extends StatelessWidget {
  const VoiceStudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Voice Studio',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF4F7FF),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3B6AF5),
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          foregroundColor: Color(0xFF0F172A),
          backgroundColor: Color(0xFFF4F7FF),
          scrolledUnderElevation: 0,
        ),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}
