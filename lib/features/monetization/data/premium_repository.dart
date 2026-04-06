import 'package:shared_preferences/shared_preferences.dart';

/// 광고 제거 구매 상태 (실제 IAP 전 로컬 데모)
class PremiumRepository {
  PremiumRepository();

  static const _keyAdsRemoved = 'premium_ads_removed_v1';

  Future<bool> isAdsRemoved() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_keyAdsRemoved) ?? false;
  }

  Future<void> setAdsRemoved(bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_keyAdsRemoved, value);
  }
}
