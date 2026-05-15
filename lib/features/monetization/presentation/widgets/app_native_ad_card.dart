import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../../../app/config/admob_config.dart';
import '../../../../app/theme/yeolpumta_theme.dart';

class AppNativeAdCard extends StatefulWidget {
  const AppNativeAdCard({
    super.key,
    this.compact = false,
    this.spotlight = false,
    this.onClose,
    this.onLoaded,
    this.onFailedToLoad,
  });

  final bool compact;
  final bool spotlight;
  final VoidCallback? onClose;
  final VoidCallback? onLoaded;
  final VoidCallback? onFailedToLoad;

  @override
  State<AppNativeAdCard> createState() => _AppNativeAdCardState();
}

class _AppNativeAdCardState extends State<AppNativeAdCard> {
  NativeAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    final adUnitId = AdMobConfig.nativeAdUnitId;
    if (adUnitId == null) return;

    final ad = NativeAd(
      adUnitId: adUnitId,
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: widget.compact ? TemplateType.small : TemplateType.medium,
        mainBackgroundColor: YeolpumtaTheme.surface,
        cornerRadius: 16,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          backgroundColor: YeolpumtaTheme.accent,
          style: NativeTemplateFontStyle.bold,
          size: 15,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: YeolpumtaTheme.textPrimary,
          style: NativeTemplateFontStyle.bold,
          size: 17,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: YeolpumtaTheme.textSecondary,
          size: 13,
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: YeolpumtaTheme.textSecondary.withValues(alpha: 0.8),
          size: 12,
        ),
      ),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _ad = ad as NativeAd;
            _loaded = true;
          });
          widget.onLoaded?.call();
        },
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          if (!mounted) return;
          setState(() {
            _ad = null;
            _loaded = false;
          });
          widget.onFailedToLoad?.call();
        },
      ),
    );
    ad.load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (!AdMobConfig.supportsMobileAds || !_loaded || ad == null) {
      return const SizedBox.shrink();
    }

    final adHeight = widget.compact
        ? (widget.spotlight ? 145.0 : 120.0)
        : 320.0;
    final background = widget.spotlight
        ? LinearGradient(
            colors: [YeolpumtaTheme.accentSoft, YeolpumtaTheme.surface],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : null;

    return Container(
      decoration: BoxDecoration(
        color: background == null ? YeolpumtaTheme.surface : null,
        gradient: background,
        borderRadius: BorderRadius.circular(widget.spotlight ? 22 : 18),
        border: Border.all(
          color: widget.spotlight
              ? YeolpumtaTheme.accent.withValues(alpha: 0.18)
              : YeolpumtaTheme.divider,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: widget.spotlight ? 0.08 : 0.05,
            ),
            blurRadius: widget.spotlight ? 18 : 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              widget.spotlight ? 16 : 14,
              widget.spotlight ? 12 : 10,
              widget.spotlight ? 10 : 14,
              widget.spotlight ? 4 : 0,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: YeolpumtaTheme.surface.withValues(alpha: 0.78),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: YeolpumtaTheme.accent.withValues(alpha: 0.16),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.campaign_outlined,
                        size: 14,
                        color: YeolpumtaTheme.textSecondary.withValues(
                          alpha: 0.75,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.spotlight ? '오늘의 추천 광고' : '추천 광고',
                        style: TextStyle(
                          color: YeolpumtaTheme.textSecondary.withValues(
                            alpha: 0.85,
                          ),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (widget.onClose != null)
                  IconButton(
                    tooltip: '광고 닫기',
                    onPressed: widget.onClose,
                    visualDensity: VisualDensity.compact,
                    style: IconButton.styleFrom(
                      backgroundColor: YeolpumtaTheme.surface.withValues(
                        alpha: 0.8,
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: YeolpumtaTheme.textSecondary.withValues(
                        alpha: 0.75,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (widget.spotlight)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                '무료 기능 유지를 위한 짧은 추천이에요.',
                style: TextStyle(
                  color: YeolpumtaTheme.textSecondary.withValues(alpha: 0.9),
                  fontSize: 12,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              widget.spotlight ? 10 : 0,
              0,
              widget.spotlight ? 10 : 0,
              widget.spotlight ? 10 : 0,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widget.spotlight ? 16 : 0),
              child: SizedBox(
                height: adHeight,
                child: AdWidget(ad: ad),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
