import 'package:flutter/material.dart';

import '../../../../app/theme/yeolpumta_theme.dart';
import '../../../monetization/data/premium_repository.dart';
import '../../../monetization/presentation/pages/ads_removal_paywall_page.dart';
import '../../../monetization/presentation/widgets/app_native_ad_card.dart';
import '../../../voices/domain/voice_job.dart';

class MarketHubPage extends StatefulWidget {
  const MarketHubPage({
    super.key,
    required this.completedJobs,
    required this.premiumRepository,
  });

  final List<VoiceJob> completedJobs;
  final PremiumRepository premiumRepository;

  @override
  State<MarketHubPage> createState() => _MarketHubPageState();
}

class _MarketHubPageState extends State<MarketHubPage> {
  bool _adsRemoved = false;

  @override
  void initState() {
    super.initState();
    _loadAdsState();
  }

  Future<void> _loadAdsState() async {
    final removed = await widget.premiumRepository.isAdsRemoved();
    if (!mounted) return;
    setState(() => _adsRemoved = removed);
  }

  Future<void> _openPremium() async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) =>
            AdsRemovalPaywallPage(repository: widget.premiumRepository),
      ),
    );
    if (ok == true && mounted) {
      setState(() => _adsRemoved = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: YeolpumtaTheme.bg,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '마켓',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: YeolpumtaTheme.textPrimary,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '앱과 어울리는 추천 광고와 광고 제거 옵션을 모아뒀어요.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: YeolpumtaTheme.textSecondary.withValues(
                        alpha: 0.92,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (!_adsRemoved) ...[
                    const AppNativeAdCard(),
                    const SizedBox(height: 18),
                  ],
                  _YeolGroupedCard(
                    children: [
                      _YeolQuietRow(
                        title: '광고 제거하기',
                        caption: '배너와 추천 광고를 숨기고 더 깔끔하게 사용해요',
                        trailing: '2,900원',
                        onTap: _openPremium,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

/// 흰 박스 + 안쪽 구분선 (설정 앱 느낌)
class _YeolGroupedCard extends StatelessWidget {
  const _YeolGroupedCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: YeolpumtaTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: YeolpumtaTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _YeolQuietRow extends StatelessWidget {
  const _YeolQuietRow({
    required this.title,
    required this.caption,
    required this.trailing,
    required this.onTap,
  });

  final String title;
  final String caption;
  final String trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: YeolpumtaTheme.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      caption,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.3,
                        color: YeolpumtaTheme.textSecondary.withValues(
                          alpha: 0.92,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    trailing,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: YeolpumtaTheme.textPrimary,
                    ),
                  ),
                ),
              Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: YeolpumtaTheme.textSecondary.withValues(alpha: 0.55),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
