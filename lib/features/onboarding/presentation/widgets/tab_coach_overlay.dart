import 'package:flutter/material.dart';

import '../../../../app/theme/yeolpumta_theme.dart';
import 'coach_mascot.dart';

/// 하단 탭 위에 말풍선 형태의 일회성 안내 (게임 튜토리얼 느낌)
class TabCoachOverlay extends StatelessWidget {
  const TabCoachOverlay({
    super.key,
    required this.tabIndex,
    required this.title,
    required this.body,
    required this.onGotIt,
    required this.onBarrierTap,
    this.guestHint,
  });

  /// 0: 음성, 1: 함께, 2: 마켓 — 꼬리 위치 정렬용
  final int tabIndex;
  final String title;
  final String body;
  final VoidCallback onGotIt;
  /// 배경 탭: 이번에만 닫기(다음에 탭 들어오면 다시 표시)
  final VoidCallback onBarrierTap;
  final String? guestHint;

  static double _navBarTotalHeight(BuildContext context) {
    final theme = NavigationBarTheme.of(context);
    final h = theme.height ?? 64;
    return h + MediaQuery.paddingOf(context).bottom;
  }

  /// 탭 중심을 0~1 구간으로 근사 (3분할)
  static double _tailAlignmentX(int tabIndex) {
    switch (tabIndex.clamp(0, 2)) {
      case 0:
        return 1 / 6;
      case 1:
        return 0.5;
      default:
        return 5 / 6;
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final navTotal = _navBarTotalHeight(context);
    final tailXFraction = _tailAlignmentX(tabIndex);
    final screenW = media.size.width;

    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onBarrierTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.38),
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: navTotal + 6,
          child: LayoutBuilder(
            builder: (context, c) {
              final bubbleW = c.maxWidth;
              final rawOffset = screenW * tailXFraction - screenW / 2;
              final maxShift = (bubbleW / 2 - 22).clamp(0.0, double.infinity);
              final tailOffset = rawOffset.clamp(-maxShift, maxShift);

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
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
                          color: const Color(0xFFF472B6).withValues(alpha: 0.16),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const CoachMascot(size: 48),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.35,
                                      color: YeolpumtaTheme.textPrimary,
                                      height: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    body,
                                    style: TextStyle(
                                      fontSize: 13,
                                      height: 1.35,
                                      color: YeolpumtaTheme.textSecondary
                                          .withValues(alpha: 0.95),
                                    ),
                                  ),
                                  if (guestHint != null) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      guestHint!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        height: 1.3,
                                        color: YeolpumtaTheme.accent
                                            .withValues(alpha: 0.9),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: onGotIt,
                          style: FilledButton.styleFrom(
                            backgroundColor: YeolpumtaTheme.accent,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(46),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            '알겠어요 ✨',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Transform.translate(
                    offset: Offset(tailOffset, 0),
                    child: CustomPaint(
                      size: const Size(28, 12),
                      painter: _BubbleTailDown(
                        fill: const Color(0xFFFFF7FB),
                        stroke: const Color(0xFFFBCFE8),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _BubbleTailDown extends CustomPainter {
  _BubbleTailDown({required this.fill, required this.stroke});

  final Color fill;
  final Color stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(w / 2, h)
      ..lineTo(w, 0)
      ..close();

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
  bool shouldRepaint(covariant _BubbleTailDown oldDelegate) =>
      oldDelegate.fill != fill || oldDelegate.stroke != stroke;
}
