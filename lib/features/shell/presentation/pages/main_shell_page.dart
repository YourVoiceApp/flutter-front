import 'package:flutter/material.dart';

import 'yeolpumta_main_shell.dart';

class MainShellPage extends StatelessWidget {
  const MainShellPage({super.key, this.isGuestMode = false});

  final bool isGuestMode;

  @override
  Widget build(BuildContext context) {
    return YeolpumtaMainShell(isGuestMode: isGuestMode);
  }
}
