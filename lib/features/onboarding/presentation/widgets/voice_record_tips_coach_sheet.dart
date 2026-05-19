import 'package:flutter/material.dart';

import '../../../../app/theme/yeolpumta_theme.dart';
import '../../data/onboarding_prefs.dart';
import 'coach_mascot.dart';

/// 직접 녹음 전 일회성 안내 (게임 튜토리얼 말풍선 스타일)
Future<void> showVoiceRecordTipsCoachIfNeeded(BuildContext context) async {
  final done = await OnboardingPrefs.isVoiceRecordTipsDone();
  if (!context.mounted || done) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const VoiceRecordTipsCoachSheet(),
  );
  await OnboardingPrefs.setVoiceRecordTipsDone();
}

class VoiceRecordTipsCoachSheet extends StatelessWidget {
  const VoiceRecordTipsCoachSheet({super.key});

  static const _tips = <_TipItem>[
    _TipItem(
      icon: Icons.timer_outlined,
      title: '5~10초만 말해 주세요',
      body: '너무 짧거나 길면 서버에서 등록이 안 될 수 있어요.',
    ),
    _TipItem(
      icon: Icons.mic_rounded,
      title: '또렷하게, 마이크 가까이',
      body: '조용한 곳에서 한 문장만 크게 읽어도 충분해요.',
    ),
    _TipItem(
      icon: Icons.volume_off_rounded,
      title: '조용한 녹음은 실패할 수 있어요',
      body: '말소리가 거의 없으면 목소리 등록이 거절될 수 있어요.',
    ),
    _TipItem(
      icon: Icons.chat_bubble_outline_rounded,
      title: '이렇게 말해 보세요',
      body: '예) "안녕하세요, 제 목소리 테스트입니다."',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, bottom + 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Color(0xFFFFF7FB),
            ],
          ),
          border: Border.all(color: const Color(0xFFFBCFE8), width: 2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF472B6).withValues(alpha: 0.18),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: YeolpumtaTheme.divider,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CoachMascot(size: 52),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '녹음 전에 잠깐만!',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                              color: YeolpumtaTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '목소리 등록이 잘 되려면 아래만 지켜 주세요.',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.35,
                              color: YeolpumtaTheme.textSecondary.withValues(alpha: 0.96),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Column(
                  children: [
                    for (var i = 0; i < _tips.length; i++) ...[
                      if (i > 0) const SizedBox(height: 8),
                      _TipCard(item: _tips[i]),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: YeolpumtaTheme.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      '알겠어요! 녹음 시작',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TipItem {
  const _TipItem({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}

class _TipCard extends StatelessWidget {
  const _TipCard({required this.item});

  final _TipItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: YeolpumtaTheme.accentSoft.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: YeolpumtaTheme.accent.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, size: 20, color: YeolpumtaTheme.accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: YeolpumtaTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.body,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: YeolpumtaTheme.textSecondary.withValues(alpha: 0.95),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
