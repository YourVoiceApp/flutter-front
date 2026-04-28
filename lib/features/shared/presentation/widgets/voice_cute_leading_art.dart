import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../voices/domain/voice_job.dart';
import '../../../../app/theme/yeolpumta_theme.dart';

/// 음성 카드·칩용 귀여운 미니 일러스트 (아이콘 대신)
class VoiceCuteLeadingAvatar extends StatelessWidget {
  const VoiceCuteLeadingAvatar({
    super.key,
    required this.origin,
    this.size = 44,
    this.borderRadius = 12,
  });

  final VoiceOrigin origin;
  final double size;
  final double borderRadius;

  static String assetPath(VoiceOrigin origin) {
    return switch (origin) {
      VoiceOrigin.uploaded => 'assets/images/voice_thumb_upload.png',
      VoiceOrigin.sharedRoom => 'assets/images/voice_thumb_room.png',
      VoiceOrigin.purchased => 'assets/images/voice_thumb_market.png',
    };
  }

  @override
  Widget build(BuildContext context) {
    final (Color tint, Color accent) = switch (origin) {
      VoiceOrigin.uploaded => (
          YeolpumtaTheme.accentSoft,
          YeolpumtaTheme.accent,
        ),
      VoiceOrigin.sharedRoom => (
          const Color(0xFFFFF0E5),
          const Color(0xFFFF9F66),
        ),
      VoiceOrigin.purchased => (
          const Color(0xFFE8F5FF),
          const Color(0xFF5BA3F5),
        ),
    };

    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Image.asset(
        assetPath(origin),
        fit: BoxFit.cover,
        width: size,
        height: size,
        filterQuality: FilterQuality.medium,
        errorBuilder: (context, error, stackTrace) {
          return CustomPaint(
            painter: _MiniAvatarPainter(origin: origin, accent: accent),
          );
        },
      ),
    );
  }
}

class _MiniAvatarPainter extends CustomPainter {
  _MiniAvatarPainter({required this.origin, required this.accent});

  final VoiceOrigin origin;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final c = Offset(w / 2, w / 2);
    switch (origin) {
      case VoiceOrigin.uploaded:
        _paintMicBuddy(canvas, c, w, accent);
      case VoiceOrigin.sharedRoom:
        _paintTwoHearts(canvas, c, w, accent);
      case VoiceOrigin.purchased:
        _paintGiftSparkle(canvas, c, w, accent);
    }
  }

  void _paintMicBuddy(Canvas canvas, Offset c, double w, Color ac) {
    final body = Paint()..color = ac.withValues(alpha: 0.2);
    canvas.drawCircle(Offset(c.dx, c.dy + w * 0.06), w * 0.26, body);
    canvas.drawCircle(Offset(c.dx - w * 0.14, c.dy - w * 0.1), w * 0.1, body);
    canvas.drawCircle(Offset(c.dx + w * 0.14, c.dy - w * 0.1), w * 0.1, body);
    final face = Paint()..color = const Color(0xFFFFE4DE);
    canvas.drawCircle(c, w * 0.2, face);
    canvas.drawCircle(
      Offset(c.dx - w * 0.07, c.dy - w * 0.04),
      w * 0.03,
      Paint()..color = const Color(0xFF374151),
    );
    canvas.drawCircle(
      Offset(c.dx + w * 0.07, c.dy - w * 0.04),
      w * 0.03,
      Paint()..color = const Color(0xFF374151),
    );
    final smile = Path()
      ..addArc(
        Rect.fromCenter(center: Offset(c.dx, c.dy + w * 0.02), width: w * 0.14, height: w * 0.1),
        math.pi * 0.15,
        math.pi * 0.7,
      );
    canvas.drawPath(
      smile,
      Paint()
        ..color = ac.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round,
    );
    final mic = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(c.dx, c.dy + w * 0.2), width: w * 0.1, height: w * 0.16),
      const Radius.circular(5),
    );
    canvas.drawRRect(mic, Paint()..color = ac);
    canvas.drawCircle(Offset(c.dx, c.dy + w * 0.28), w * 0.05, Paint()..color = ac.withValues(alpha: 0.45));
  }

  void _paintTwoHearts(Canvas canvas, Offset c, double w, Color ac) {
    void heart(Offset o, double s) {
      final p = Path();
      p.addOval(Rect.fromCenter(center: o + Offset(-s * 0.25, -s * 0.15), width: s * 0.5, height: s * 0.5));
      p.addOval(Rect.fromCenter(center: o + Offset(s * 0.25, -s * 0.15), width: s * 0.5, height: s * 0.5));
      p.moveTo(o.dx, o.dy + s * 0.35);
      p.lineTo(o.dx - s * 0.55, o.dy - s * 0.05);
      p.quadraticBezierTo(o.dx - s * 0.5, o.dy - s * 0.55, o.dx, o.dy - s * 0.35);
      p.lineTo(o.dx + s * 0.55, o.dy - s * 0.05);
      p.quadraticBezierTo(o.dx + s * 0.5, o.dy - s * 0.55, o.dx, o.dy - s * 0.35);
      p.close();
      canvas.drawPath(p, Paint()..color = ac.withValues(alpha: 0.9));
    }

    heart(Offset(c.dx - w * 0.14, c.dy + w * 0.04), w * 0.22);
    heart(Offset(c.dx + w * 0.14, c.dy - w * 0.04), w * 0.18);
    canvas.drawCircle(
      Offset(c.dx, c.dy - w * 0.22),
      w * 0.07,
      Paint()..color = const Color(0xFFFFD6E5),
    );
  }

  void _paintGiftSparkle(Canvas canvas, Offset c, double w, Color ac) {
    final bag = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(c.dx, c.dy + w * 0.04), width: w * 0.52, height: w * 0.36),
      const Radius.circular(6),
    );
    canvas.drawRRect(bag, Paint()..color = ac.withValues(alpha: 0.35));
    canvas.drawRRect(
      bag,
      Paint()
        ..color = ac
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    canvas.drawRect(
      Rect.fromCenter(center: Offset(c.dx, c.dy - w * 0.06), width: w * 0.52, height: w * 0.1),
      Paint()..color = ac.withValues(alpha: 0.75),
    );
    _sparkle(canvas, Offset(c.dx + w * 0.26, c.dy - w * 0.22), w * 0.1, ac);
    _sparkle(canvas, Offset(c.dx - w * 0.22, c.dy + w * 0.2), w * 0.06, ac);
  }

  void _sparkle(Canvas canvas, Offset o, double r, Color ac) {
    final p = Path()
      ..moveTo(o.dx, o.dy - r)
      ..lineTo(o.dx, o.dy + r)
      ..moveTo(o.dx - r, o.dy)
      ..lineTo(o.dx + r, o.dy);
    canvas.drawPath(
      p,
      Paint()
        ..color = ac
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _MiniAvatarPainter oldDelegate) =>
      oldDelegate.origin != origin || oldDelegate.accent != accent;
}

/// 출처 칩용 작은 글리프
class VoiceOriginCuteGlyph extends StatelessWidget {
  const VoiceOriginCuteGlyph({
    super.key,
    required this.origin,
    this.size = 14,
    required this.color,
  });

  final VoiceOrigin origin;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GlyphPainter(origin: origin, color: color),
      ),
    );
  }
}

class _GlyphPainter extends CustomPainter {
  _GlyphPainter({required this.origin, required this.color});

  final VoiceOrigin origin;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    switch (origin) {
      case VoiceOrigin.uploaded:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: c + Offset(0, size.height * 0.08),
              width: size.width * 0.35,
              height: size.height * 0.5,
            ),
            const Radius.circular(3),
          ),
          Paint()..color = color,
        );
        canvas.drawLine(
          Offset(c.dx, c.dy - size.height * 0.15),
          Offset(c.dx, c.dy - size.height * 0.38),
          Paint()
            ..color = color
            ..strokeWidth = 1.5
            ..strokeCap = StrokeCap.round,
        );
      case VoiceOrigin.sharedRoom:
        canvas.drawCircle(
          c - Offset(size.width * 0.18, 0),
          size.width * 0.22,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.3,
        );
        canvas.drawCircle(
          c + Offset(size.width * 0.18, 0),
          size.width * 0.22,
          Paint()..color = color,
        );
      case VoiceOrigin.purchased:
        final star = Path()
          ..moveTo(c.dx, c.dy - size.height * 0.38)
          ..lineTo(c.dx + size.width * 0.1, c.dy + size.height * 0.05)
          ..lineTo(c.dx + size.width * 0.35, c.dy + size.height * 0.05)
          ..lineTo(c.dx + size.width * 0.12, c.dy + size.height * 0.22)
          ..lineTo(c.dx + size.width * 0.22, c.dy + size.height * 0.48)
          ..lineTo(c.dx, c.dy + size.height * 0.32)
          ..lineTo(c.dx - size.width * 0.22, c.dy + size.height * 0.48)
          ..lineTo(c.dx - size.width * 0.12, c.dy + size.height * 0.22)
          ..lineTo(c.dx - size.width * 0.35, c.dy + size.height * 0.05)
          ..lineTo(c.dx - size.width * 0.1, c.dy + size.height * 0.05)
          ..close();
        canvas.drawPath(star, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _GlyphPainter oldDelegate) =>
      oldDelegate.origin != origin || oldDelegate.color != color;
}

class VoiceCardSoftDecoration extends StatelessWidget {
  const VoiceCardSoftDecoration({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(88, 88),
      painter: _SoftNoteHeartsPainter(),
    );
  }
}

class _SoftNoteHeartsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final base = YeolpumtaTheme.accent.withValues(alpha: 0.08);
    final pink = const Color(0xFFF472B6).withValues(alpha: 0.07);
    for (var i = 0; i < 5; i++) {
      final o = Offset(size.width * 0.3 + i * 9.0, size.height * 0.35 + math.sin(i) * 5);
      canvas.drawCircle(o, 3 + i * 0.5, Paint()..color = i.isEven ? base : pink);
    }
    final h = Path();
    final c = Offset(size.width * 0.72, size.height * 0.5);
    const s = 10.0;
    h.addOval(Rect.fromCenter(center: c + const Offset(-s * 0.25, -s * 0.15), width: s * 0.55, height: s * 0.55));
    h.addOval(Rect.fromCenter(center: c + const Offset(s * 0.25, -s * 0.15), width: s * 0.55, height: s * 0.55));
    h.moveTo(c.dx, c.dy + s * 0.4);
    h.lineTo(c.dx - s * 0.55, c.dy);
    h.quadraticBezierTo(c.dx - s * 0.45, c.dy - s * 0.55, c.dx, c.dy - s * 0.35);
    h.lineTo(c.dx + s * 0.55, c.dy);
    h.quadraticBezierTo(c.dx + s * 0.45, c.dy - s * 0.55, c.dx, c.dy - s * 0.35);
    h.close();
    canvas.drawPath(h, Paint()..color = pink.withValues(alpha: 0.55));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
