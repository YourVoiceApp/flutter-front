import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../domain/market_listing.dart';

const _prefsKey = 'market_listings_v1';

class MarketRepository {
  MarketRepository();

  final _uuid = const Uuid();

  Future<List<MarketListing>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) {
      final seed = _seedOthers();
      await _save(prefs, seed);
      return seed;
    }
    try {
      final list = (jsonDecode(raw) as List<dynamic>)
          .map((e) => _fromJson(e as Map<String, dynamic>))
          .toList();
      return list;
    } catch (_) {
      final seed = _seedOthers();
      await _save(prefs, seed);
      return seed;
    }
  }

  Future<void> _save(SharedPreferences prefs, List<MarketListing> list) async {
    await prefs.setString(
      _prefsKey,
      jsonEncode(list.map(_toJson).toList()),
    );
  }

  Future<List<MarketListing>> addMine({
    required String fileName,
    required int priceWon,
    required String sourceVoiceJobId,
    required String previewScript,
    required String creatorNickname,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final all = await loadAll();
    final n = MarketListing(
      id: 'ml-${_uuid.v4()}',
      fileName: fileName,
      priceWon: priceWon,
      sellerLabel: creatorNickname,
      listedAt: DateTime.now(),
      sourceVoiceJobId: sourceVoiceJobId,
      isMine: true,
      previewScript: previewScript,
      purchaseCount: 0,
    );
    final next = [n, ...all.where((e) => !(e.isMine && e.sourceVoiceJobId == sourceVoiceJobId))];
    await _save(prefs, next);
    return next;
  }

  /// 데모 구매 완료 시 인기 집계용
  Future<void> incrementDemoPurchase(String listingId) async {
    final prefs = await SharedPreferences.getInstance();
    final all = await loadAll();
    final idx = all.indexWhere((e) => e.id == listingId);
    if (idx < 0) return;
    final cur = all[idx];
    final next = List<MarketListing>.from(all);
    next[idx] = cur.copyWith(purchaseCount: cur.purchaseCount + 1);
    await _save(prefs, next);
  }

  Map<String, dynamic> _toJson(MarketListing m) => {
        'id': m.id,
        'fileName': m.fileName,
        'priceWon': m.priceWon,
        'sellerLabel': m.sellerLabel,
        'listedAt': m.listedAt.toIso8601String(),
        'sourceVoiceJobId': m.sourceVoiceJobId,
        'isMine': m.isMine,
        'previewScript': m.previewScript,
        'purchaseCount': m.purchaseCount,
      };

  MarketListing _fromJson(Map<String, dynamic> m) => MarketListing(
        id: m['id'] as String,
        fileName: m['fileName'] as String,
        priceWon: (m['priceWon'] as num).toInt(),
        sellerLabel: m['sellerLabel'] as String,
        listedAt: DateTime.tryParse(m['listedAt'] as String? ?? '') ??
            DateTime.now(),
        sourceVoiceJobId: m['sourceVoiceJobId'] as String?,
        isMine: m['isMine'] as bool? ?? false,
        previewScript: m['previewScript'] as String? ?? '',
        purchaseCount: (m['purchaseCount'] as num?)?.toInt() ?? 0,
      );

  List<MarketListing> _seedOthers() => [
        MarketListing(
          id: 'seed-1',
          fileName: '따뜻한_안내_보이스.wav',
          priceWon: 4900,
          sellerLabel: '크리에이터 A',
          listedAt: DateTime(2026, 3, 20),
          previewScript: '안녕하세요, 오늘도 좋은 하루 되세요. 문의 주시면 친절히 안내드릴게요.',
          purchaseCount: 128,
        ),
        MarketListing(
          id: 'seed-2',
          fileName: '캐주얼_낭독.m4a',
          priceWon: 12000,
          sellerLabel: '스튜디오 B',
          listedAt: DateTime(2026, 4, 1),
          previewScript: '이 문장은 미리듣기예요. 구매 전에 목소리 느낌만 확인해 보세요.',
          purchaseCount: 42,
        ),
        MarketListing(
          id: 'seed-3',
          fileName: '짧은_인사말 세트',
          priceWon: 2900,
          sellerLabel: '음성장터 #102',
          listedAt: DateTime(2026, 4, 4),
          previewScript: '감사합니다. 다음에 또 뵈어요.',
          purchaseCount: 256,
        ),
      ];
}
