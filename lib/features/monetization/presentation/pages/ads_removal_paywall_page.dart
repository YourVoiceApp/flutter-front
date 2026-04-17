import 'package:flutter/material.dart';

import '../../../../app/theme/yeolpumta_theme.dart';
import '../../../auth/data/auth_api_client.dart';
import '../../data/premium_repository.dart';

/// 듣기 구간 광고 제거 — 2,900원 (UI·로컬 데모)
class AdsRemovalPaywallPage extends StatefulWidget {
  const AdsRemovalPaywallPage({super.key, required this.repository});

  final PremiumRepository repository;

  @override
  State<AdsRemovalPaywallPage> createState() => _AdsRemovalPaywallPageState();
}

class _AdsRemovalPaywallPageState extends State<AdsRemovalPaywallPage> {
  bool _already = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final v = await widget.repository.isAdsRemoved();
    if (mounted) setState(() => _already = v);
  }

  Future<void> _purchaseDemo() async {
    setState(() => _busy = true);
    try {
      await widget.repository.purchaseAdsRemoval(
        purchaseToken: 'dev-${DateTime.now().millisecondsSinceEpoch}',
      );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _already = true;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('광고 제거가 적용됐어요.')));
      Navigator.of(context).pop<bool>(true);
    } on AuthApiException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('구매 처리 중 오류가 발생했어요: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YeolpumtaTheme.bg,
      appBar: AppBar(title: const Text('광고 제거')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: YeolpumtaTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: YeolpumtaTheme.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: YeolpumtaTheme.accentSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.block_rounded,
                        color: YeolpumtaTheme.accent,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text(
                        '듣기할 때 나오는 광고를 없애요',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                          color: YeolpumtaTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const _Bullet(text: '듣기 전·후 광고 슬롯 비움'),
                const _Bullet(text: '한 번 구매로 이 기기에서 유지 (데모)'),
                const _Bullet(text: '집중해서 문장 듣기에만 쓸 수 있어요'),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const Center(
            child: Text(
              '2,900원',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
                color: YeolpumtaTheme.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              _already ? '이미 적용됨' : '일회성 · 부가세 포함 가정',
              style: TextStyle(
                fontSize: 14,
                color: _already
                    ? YeolpumtaTheme.accent
                    : YeolpumtaTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: (_already || _busy) ? null : _purchaseDemo,
            style: FilledButton.styleFrom(
              backgroundColor: YeolpumtaTheme.accent,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _busy
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    _already ? '구매 완료' : '2,900원에 구매하기',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          Text(
            '현재는 백엔드 주문/확인 API에 연결돼 있고, 실제 서비스에서는 스토어 결제 토큰을 넘기도록 확장하면 됩니다.',
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: YeolpumtaTheme.textSecondary.withValues(alpha: 0.95),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '· ',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: YeolpumtaTheme.accent,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                height: 1.35,
                color: YeolpumtaTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
