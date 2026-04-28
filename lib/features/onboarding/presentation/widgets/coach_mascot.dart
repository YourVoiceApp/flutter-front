import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/yeolpumta_theme.dart';

/// 튜토리얼용 작은 캐릭터(말풍선 옆)
class CoachMascot extends StatelessWidget {
  const CoachMascot({super.key, this.size = 52});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _MascotPainter()),
    );
  }
}

class _MascotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final bodyPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFFBF7),
          YeolpumtaTheme.accentSoft.withValues(alpha: 0.85),
          const Color(0xFFD1FAE5).withValues(alpha: 0.5),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(cx, h * 0.48), radius: w * 0.55));

    final bodyPath = Path()
      ..addOval(
        Rect.fromCenter(
          center: Offset(cx, h * 0.5),
          width: w * 0.92,
          height: h * 0.78,
        ),
      );
    canvas.drawShadow(bodyPath, const Color(0x33000000), 3, false);
    canvas.drawPath(bodyPath, bodyPaint);
    canvas.drawPath(
      bodyPath,
      Paint()
        ..color = const Color(0xFFF9A8D4).withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // 작은 귀 / 볼 주름
    final earPaint = Paint()..color = const Color(0xFFFBCFE8).withValues(alpha: 0.7);
    canvas.drawCircle(Offset(cx - w * 0.38, h * 0.32), w * 0.1, earPaint);
    canvas.drawCircle(Offset(cx + w * 0.38, h * 0.32), w * 0.1, earPaint);

    // 볼
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx - w * 0.22, h * 0.52),
        width: w * 0.14,
        height: w * 0.08,
      ),
      Paint()..color = const Color(0xFFFFB4C8).withValues(alpha: 0.55),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx + w * 0.22, h * 0.52),
        width: w * 0.14,
        height: w * 0.08,
      ),
      Paint()..color = const Color(0xFFFFB4C8).withValues(alpha: 0.55),
    );

    // 눈
    final eyeY = h * 0.42;
    final eyeR = w * 0.07;
    canvas.drawCircle(Offset(cx - w * 0.18, eyeY), eyeR, Paint()..color = const Color(0xFF374151));
    canvas.drawCircle(Offset(cx + w * 0.18, eyeY), eyeR, Paint()..color = const Color(0xFF374151));
    canvas.drawCircle(
      Offset(cx - w * 0.16, eyeY - eyeR * 0.35),
      eyeR * 0.35,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      Offset(cx + w * 0.2, eyeY - eyeR * 0.35),
      eyeR * 0.35,
      Paint()..color = Colors.white,
    );

    // 미소
    final smilePath = Path()
      ..addArc(
        Rect.fromCenter(
          center: Offset(cx, h * 0.58),
          width: w * 0.42,
          height: h * 0.22,
        ),
        math.pi * 0.1,
        math.pi * 0.8,
      );
    canvas.drawPath(
      smilePath,
      Paint()
        ..color = const Color(0xFFEC4899)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round,
    );

    // 반짝
    final spark = Paint()..color = const Color(0xFFFBBF24).withValues(alpha: 0.9);
    canvas.drawCircle(Offset(cx + w * 0.32, h * 0.2), w * 0.045, spark);
    canvas.drawCircle(Offset(cx - w * 0.35, h * 0.24), w * 0.025, spark);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
