import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:your_voice_app/features/auth/presentation/pages/login_page.dart';

void main() {
  testWidgets('Login screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LoginPage(),
      ),
    );

    expect(find.text('Your Voice'), findsWidgets);
    expect(find.text('로그인'), findsWidgets);
  });
}
