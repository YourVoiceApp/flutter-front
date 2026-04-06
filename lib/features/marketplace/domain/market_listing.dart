/// 시장에 올라온 음성 판매 항목 (UI 데모)
class MarketListing {
  const MarketListing({
    required this.id,
    required this.fileName,
    required this.priceWon,
    required this.sellerLabel,
    required this.listedAt,
    this.sourceVoiceJobId,
    this.isMine = false,
    this.previewScript = '',
    this.purchaseCount = 0,
  });

  final String id;
  final String fileName;
  final int priceWon;

  /// 크리에이터(판매자) 표시명 · 검색(닉네임)에 사용
  final String sellerLabel;
  final DateTime listedAt;

  /// 데모 인기순용. 실제 서비스에서는 구매·조회 등으로 집계
  final int purchaseCount;

  /// 내가 올린 판매면 연결된 음성 작업 id
  final String? sourceVoiceJobId;
  final bool isMine;

  /// 구매자 미리듣기용 문장 (약 5초 분량 권장). 데모는 기기 TTS.
  final String previewScript;

  MarketListing copyWith({
    String? id,
    String? fileName,
    int? priceWon,
    String? sellerLabel,
    DateTime? listedAt,
    String? sourceVoiceJobId,
    bool? isMine,
    String? previewScript,
    int? purchaseCount,
  }) {
    return MarketListing(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      priceWon: priceWon ?? this.priceWon,
      sellerLabel: sellerLabel ?? this.sellerLabel,
      listedAt: listedAt ?? this.listedAt,
      sourceVoiceJobId: sourceVoiceJobId ?? this.sourceVoiceJobId,
      isMine: isMine ?? this.isMine,
      previewScript: previewScript ?? this.previewScript,
      purchaseCount: purchaseCount ?? this.purchaseCount,
    );
  }
}

String formatWon(int n) {
  final s = n.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    final fromEnd = s.length - i;
    if (i > 0 && fromEnd % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return '$buf원';
}
