import 'package:flutter/material.dart';

import '../../../../app/theme/yeolpumta_theme.dart';
import 'coach_mascot.dart';

/// 스포트라이트 + 게임 느낌의 귀여운 말풍선(짧은 카피)
class SpotlightCoachOverlay extends StatelessWidget {
  const SpotlightCoachOverlay({
    super.key,
    required this.holeRect,
    required this.title,
    required this.body,
    this.tapHint = '👉 버튼을 눌러볼까?',
    this.holeRadius = 18,
  });

  final Rect holeRect;
  final String title;
  final String body;
  final String tapHint;
  final double holeRadius;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final w = size.width;
    final h = size.height;
    final hr = holeRect;

    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        _BarrierStrip(rect: Rect.fromLTWH(0, 0, w, hr.top.clamp(0.0, h))),
        _BarrierStrip(
          rect: Rect.fromLTWH(0, hr.bottom, w, (h - hr.bottom).clamp(0.0, h)),
        ),
        _BarrierStrip(
          rect: Rect.fromLTWH(0, hr.top, hr.left.clamp(0.0, w), hr.height),
        ),
        _BarrierStrip(
          rect: Rect.fromLTWH(
            hr.right.clamp(0.0, w),
            hr.top,
            (w - hr.right).clamp(0.0, w),
            hr.height,
          ),
        ),
        Positioned.fromRect(
          rect: hr,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(holeRadius),
                border: Border.all(
                  color: const Color(0xFFF472B6).withValues(alpha: 0.65),
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: YeolpumtaTheme.accent.withValues(alpha: 0.35),
                    blurRadius: 18,
                    spreadRadius: 0,
                  ),
                ],
              ),
            ),
          ),
        ),
        _CuteCoachBubble(holeRect: holeRect, title: title, body: body, tapHint: tapHint),
      ],
    );
  }
}

class _BarrierStrip extends StatelessWidget {
  const _BarrierStrip({required this.rect});

  final Rect rect;

  @override
  Widget build(BuildContext context) {
    if (rect.width <= 0 || rect.height <= 0) return const SizedBox.shrink();
    return Positioned(
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {},
        child: const ColoredBox(color: Color(0x70000000)),
      ),
    );
  }
}

class _CuteCoachBubble extends StatelessWidget {
  const _CuteCoachBubble({
    required this.holeRect,
    required this.title,
    required this.body,
    required this.tapHint,
  });

  final Rect holeRect;
  final String title;
  final String body;
  final String tapHint;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screenH = media.size.height;
    const maxBubbleW = 328.0;
    var top = holeRect.top - 16 - 168;
    if (top < media.padding.top + 48) {
      top = holeRect.bottom + 12;
    }
    top = top.clamp(media.padding.top + 6, screenH - 260);

    final bubbleAboveHole = top < holeRect.top - 20;

    return Positioned(
      left: 14,
      right: 14,
      top: top,
      child: IgnorePointer(
        ignoring: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (!bubbleAboveHole)
              const Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: _WiggleTail(down: false),
              ),
            Container(
              constraints: BoxConstraints(maxWidth: maxBubbleW),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    const Color(0xFFFFF7FB),
                    YeolpumtaTheme.accentSoft.withValues(alpha: 0.35),
                  ],
                ),
                border: Border.all(
                  color: const Color(0xFFFBCFE8),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF472B6).withValues(alpha: 0.18),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Transform.translate(
                    offset: const Offset(0, 4),
                    child: const CoachMascot(size: 50),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                            letterSpacing: -0.4,
                            color: YeolpumtaTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          body,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.35,
                            color: YeolpumtaTheme.textSecondary.withValues(alpha: 0.96),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: YeolpumtaTheme.accentSoft.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: YeolpumtaTheme.accent.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Text(
                            tapHint,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: YeolpumtaTheme.accent.withValues(alpha: 0.95),
                              height: 1.25,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (bubbleAboveHole)
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: _WiggleTail(down: true),
              ),
          ],
        ),
      ),
    );
  }
}

class _WiggleTail extends StatelessWidget {
  const _WiggleTail({required this.down});

  final bool down;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(28, down ? 11 : 11),
      painter: _SoftTailPainter(
        down: down,
        fill: const Color(0xFFFFF7FB),
        stroke: const Color(0xFFFBCFE8),
      ),
    );
  }
}

class _SoftTailPainter extends CustomPainter {
  _SoftTailPainter({
    required this.down,
    required this.fill,
    required this.stroke,
  });

  final bool down;
  final Color fill;
  final Color stroke;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.translate(size.width / 2, 0);
    final path = Path();
    if (down) {
      path
        ..moveTo(-11, 0)
        ..quadraticBezierTo(0, size.height + 2, 11, 0)
        ..close();
    } else {
      path
        ..moveTo(-11, size.height)
       ..quadraticBezierTo(0, -2, 11, size.height)
        ..close();
    }
    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..color = stroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(covariant _SoftTailPainter oldDelegate) =>
      oldDelegate.down != down;
}
