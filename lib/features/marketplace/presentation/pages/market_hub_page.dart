import 'package:flutter/material.dart';

import '../../../../app/theme/yeolpumta_theme.dart';
import '../../../monetization/data/premium_repository.dart';
import '../../../monetization/presentation/pages/ads_removal_paywall_page.dart';
import '../../../voices/domain/voice_job.dart';
import '../../data/market_repository.dart';
import '../../domain/market_listing.dart';
import '../utils/preview_voice_helper.dart';
import 'sell_voice_listing_page.dart';

enum _BrowseSort { popular, latest }

/// 열품타식: 여백·단순·한눈에 — 시장 / 내 판매
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
  final _marketRepo = MarketRepository();
  final _previewPlayer = PreviewVoiceHelper();
  final _browseSearchCtrl = TextEditingController();
  List<MarketListing> _list = [];
  bool _loading = true;
  String? _previewingId;

  /// 0 둘러보기 · 1 내 판매
  int _segment = 0;
  _BrowseSort _browseSort = _BrowseSort.popular;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _browseSearchCtrl.dispose();
    _previewPlayer.dispose();
    super.dispose();
  }

  List<MarketListing> _filterAndSortBrowse(List<MarketListing> others) {
    final q = _browseSearchCtrl.text.trim().toLowerCase();
    var out = [...others];
    if (q.isNotEmpty) {
      out = out.where((e) {
        final nick = e.sellerLabel.toLowerCase();
        final file = e.fileName.toLowerCase();
        return nick.contains(q) || file.contains(q);
      }).toList();
    }
    if (_browseSort == _BrowseSort.latest) {
      out.sort((a, b) => b.listedAt.compareTo(a.listedAt));
    } else {
      out.sort((a, b) {
        final c = b.purchaseCount.compareTo(a.purchaseCount);
        if (c != 0) return c;
        return b.listedAt.compareTo(a.listedAt);
      });
    }
    return out;
  }

  Future<void> _playPreview(MarketListing m) async {
    final t = m.previewScript.trim();
    if (t.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('미리듣기 문장이 없어요.')),
      );
      return;
    }
    setState(() => _previewingId = m.id);
    try {
      await _previewPlayer.playPreview(t, seconds: 5);
    } finally {
      if (mounted) setState(() => _previewingId = null);
    }
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    final l = await _marketRepo.loadAll();
    if (mounted) {
      setState(() {
        _list = l;
        _loading = false;
      });
    }
  }

  Future<void> _openPremium() async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AdsRemovalPaywallPage(
          repository: widget.premiumRepository,
        ),
      ),
    );
    if (ok == true && mounted) setState(() {});
  }

  Future<void> _openSell() async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => SellVoiceListingPage(
          completedJobs: widget.completedJobs,
          marketRepository: _marketRepo,
        ),
      ),
    );
    if (ok != true) return;
    await _reload();
    if (!mounted) return;
    setState(() => _segment = 1);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('등록했어요. (데모)')),
    );
  }

  Future<void> _buyDemo(MarketListing m) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: YeolpumtaTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '구매',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: YeolpumtaTheme.textPrimary,
          ),
        ),
        content: Text(
          '「${m.fileName}」\n'
          '크리에이터 · ${m.sellerLabel}\n'
          '${formatWon(m.priceWon)}\n\n'
          '목록에서 5초 미리듣기로 느낌을 확인한 뒤 구매하면 돼요.\n\n'
          '데모예요. 결제·라이선스는 연동 후에요.',
          style: const TextStyle(
            height: 1.45,
            color: YeolpumtaTheme.textPrimary,
            fontSize: 15,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('닫기'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: YeolpumtaTheme.accent,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await _marketRepo.incrementDemoPurchase(m.id);
              if (!mounted) return;
              await _reload();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('구매 완료 (데모)')),
              );
            },
            child: const Text('데모로 구매'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mine = _list.where((e) => e.isMine).toList();
    final others = _list.where((e) => !e.isMine).toList();
    final browse = _filterAndSortBrowse(others);

    return ColoredBox(
      color: YeolpumtaTheme.bg,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
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
                          '필요할 때만 골라요. 듣기 광고 끄기 · 목소리 사고팔기',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.45,
                            color: YeolpumtaTheme.textSecondary.withValues(alpha: 0.92),
                          ),
                        ),
                        const SizedBox(height: 22),
                        _YeolGroupedCard(
                          children: [
                            _YeolQuietRow(
                              title: '듣기 화면 광고 끄기',
                              caption: '듣기 탭과 같은 혜택이에요',
                              trailing: '2,900원',
                              onTap: _openPremium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SegmentedButton<int>(
                          segments: const [
                            ButtonSegment(
                              value: 0,
                              label: Text('둘러보기'),
                              icon: Icon(Icons.grid_view_rounded, size: 18),
                            ),
                            ButtonSegment(
                              value: 1,
                              label: Text('내 판매'),
                              icon: Icon(Icons.inventory_2_outlined, size: 18),
                            ),
                          ],
                          selected: {_segment},
                          onSelectionChanged: (s) {
                            setState(() => _segment = s.first);
                          },
                          style: ButtonStyle(
                            visualDensity: VisualDensity.compact,
                            padding: WidgetStateProperty.all(
                              const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        if (_segment == 0) ...[
                          TextField(
                            controller: _browseSearchCtrl,
                            onChanged: (_) => setState(() {}),
                            textInputAction: TextInputAction.search,
                            style: const TextStyle(
                              fontSize: 15,
                              color: YeolpumtaTheme.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: '크리에이터 닉네임·파일명 검색',
                              hintStyle: TextStyle(
                                color: YeolpumtaTheme.textSecondary
                                    .withValues(alpha: 0.75),
                                fontSize: 14,
                              ),
                              prefixIcon: Icon(
                                Icons.search_rounded,
                                color: YeolpumtaTheme.textSecondary
                                    .withValues(alpha: 0.65),
                                size: 22,
                              ),
                              suffixIcon: _browseSearchCtrl.text.isNotEmpty
                                  ? IconButton(
                                      tooltip: '지우기',
                                      onPressed: () {
                                        _browseSearchCtrl.clear();
                                        setState(() {});
                                      },
                                      icon: Icon(
                                        Icons.close_rounded,
                                        size: 20,
                                        color: YeolpumtaTheme.textSecondary
                                            .withValues(alpha: 0.65),
                                      ),
                                    )
                                  : null,
                              filled: true,
                              fillColor: YeolpumtaTheme.surface,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    const BorderSide(color: YeolpumtaTheme.divider),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    const BorderSide(color: YeolpumtaTheme.divider),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: YeolpumtaTheme.accent,
                                  width: 1.2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: SegmentedButton<_BrowseSort>(
                              segments: [
                                ButtonSegment<_BrowseSort>(
                                  value: _BrowseSort.popular,
                                  label: const Text('인기순'),
                                  icon: const Icon(Icons.trending_up_rounded, size: 16),
                                ),
                                ButtonSegment<_BrowseSort>(
                                  value: _BrowseSort.latest,
                                  label: const Text('최신순'),
                                  icon: const Icon(Icons.schedule_rounded, size: 16),
                                ),
                              ],
                              selected: {_browseSort},
                              onSelectionChanged: (s) {
                                setState(() => _browseSort = s.first);
                              },
                              style: ButtonStyle(
                                visualDensity: VisualDensity.compact,
                                padding: WidgetStateProperty.all(
                                  const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 10,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                        if (_segment == 1) ...[
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: widget.completedJobs.isNotEmpty
                                  ? _openSell
                                  : null,
                              style: FilledButton.styleFrom(
                                backgroundColor: YeolpumtaTheme.accent,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor:
                                    YeolpumtaTheme.divider,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                widget.completedJobs.isEmpty
                                    ? '먼저 음성 학습을 완료해 주세요'
                                    : '가격 정해서 올리기',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (widget.completedJobs.isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Text(
                                '「음성」탭에서 학습이 끝난 뒤 등록할 수 있어요.',
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.35,
                                  color: YeolpumtaTheme.textSecondary
                                      .withValues(alpha: 0.9),
                                ),
                              ),
                            ),
                          const SizedBox(height: 14),
                        ],
                      ],
                    ),
                  ),
                ),
                if (_segment == 0)
                  _buildBrowseSliver(others, browse)
                else
                  _buildMineSliver(mine),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
    );
  }

  Widget _buildBrowseSliver(
    List<MarketListing> othersRaw,
    List<MarketListing> browse,
  ) {
    if (othersRaw.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.waves_rounded,
                size: 40,
                color: YeolpumtaTheme.textSecondary.withValues(alpha: 0.45),
              ),
              const SizedBox(height: 14),
              Text(
                '올라온 목소리가 없어요',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.45,
                  color: YeolpumtaTheme.textSecondary.withValues(alpha: 0.95),
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (browse.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 40,
                color: YeolpumtaTheme.textSecondary.withValues(alpha: 0.45),
              ),
              const SizedBox(height: 14),
              Text(
                '검색 결과가 없어요\n닉네임이나 파일명을 바꿔 보세요',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: YeolpumtaTheme.textSecondary.withValues(alpha: 0.95),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      sliver: SliverList.separated(
        itemCount: browse.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, i) => _YeolMarketRow(
          listing: browse[i],
          onBuy: () => _buyDemo(browse[i]),
          onPreview: () => _playPreview(browse[i]),
          previewing: _previewingId == browse[i].id,
        ),
      ),
    );
  }

  Widget _buildMineSliver(List<MarketListing> mine) {
    if (mine.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 44,
                color: YeolpumtaTheme.textSecondary.withValues(alpha: 0.45),
              ),
              const SizedBox(height: 14),
              Text(
                '아직 올린 판매가 없어요\n위 버튼으로 가격을 정해 보세요',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: YeolpumtaTheme.textSecondary.withValues(alpha: 0.95),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      sliver: SliverList.separated(
        itemCount: mine.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, i) => _YeolMarketRow(
          listing: mine[i],
          isMine: true,
          onBuy: () {},
          onPreview: () => _playPreview(mine[i]),
          previewing: _previewingId == mine[i].id,
        ),
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
                        color: YeolpumtaTheme.textSecondary.withValues(alpha: 0.92),
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

/// 시장 행 — 구매 탭 / 5초 미리듣기 버튼 분리
class _YeolMarketRow extends StatelessWidget {
  const _YeolMarketRow({
    required this.listing,
    required this.onBuy,
    required this.onPreview,
    required this.previewing,
    this.isMine = false,
  });

  final MarketListing listing;
  final VoidCallback onBuy;
  final VoidCallback onPreview;
  final bool previewing;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final raw = listing.sellerLabel.trim();
    final letter = raw.isNotEmpty
        ? raw.substring(0, 1).toUpperCase()
        : '?';
    final hasPreview = listing.previewScript.trim().isNotEmpty;

    return Material(
      color: YeolpumtaTheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 6, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: YeolpumtaTheme.bg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                letter,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: YeolpumtaTheme.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: InkWell(
                onTap: isMine ? null : onBuy,
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        listing.fileName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                          color: YeolpumtaTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        isMine
                            ? '내 판매 · ${listing.sellerLabel}'
                            : '크리에이터 · ${listing.sellerLabel}',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.2,
                          color: YeolpumtaTheme.textSecondary.withValues(alpha: 0.9),
                        ),
                      ),
                      if (!isMine) ...[
                        const SizedBox(height: 3),
                        Text(
                          '데모 인기 ${listing.purchaseCount}회',
                          style: TextStyle(
                            fontSize: 11,
                            height: 1.2,
                            color: YeolpumtaTheme.textSecondary.withValues(alpha: 0.72),
                          ),
                        ),
                      ],
                      if (hasPreview) ...[
                        const SizedBox(height: 6),
                        Text(
                          listing.previewScript.trim(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.3,
                            color: YeolpumtaTheme.textSecondary.withValues(alpha: 0.88),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatWon(listing.priceWon),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    color: YeolpumtaTheme.textPrimary,
                  ),
                ),
                if (!isMine) ...[
                  const SizedBox(height: 2),
                  Text(
                    '탭하여 구매',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: YeolpumtaTheme.textSecondary.withValues(alpha: 0.7),
                    ),
                  ),
                ],
                if (hasPreview) ...[
                  const SizedBox(height: 6),
                  TextButton(
                    onPressed: previewing ? null : onPreview,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      previewing ? '재생 중…' : '5초 듣기',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: YeolpumtaTheme.accent,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
