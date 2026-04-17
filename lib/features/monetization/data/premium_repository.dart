import 'package:shared_preferences/shared_preferences.dart';

<<<<<<< Updated upstream
/// 광고 제거 구매 상태 (실제 IAP 전 로컬 데모)
class PremiumRepository {
  PremiumRepository();

  static const _keyAdsRemoved = 'premium_ads_removed_v1';

  Future<bool> isAdsRemoved() async {
=======
import '../../../app/services/app_services.dart';
import '../../../app/services/authenticated_api_client.dart';
import '../../auth/data/auth_api_client.dart';
import '../../auth/data/auth_service.dart';

/// 광고 제거 상태는 로그인 시 백엔드와 동기화하고,
/// 게스트/오프라인일 때만 로컬 데모 값으로 폴백한다.
class PremiumRepository {
  PremiumRepository({
    AuthService? authService,
    AuthenticatedApiClient? apiClient,
  }) : _authService = authService ?? AppServices.instance.authService,
       _api =
           apiClient ??
           AuthenticatedApiClient(
             authService: authService ?? AppServices.instance.authService,
           );

  static const _keyAdsRemoved = 'premium_ads_removed_v1';

  final AuthService _authService;
  final AuthenticatedApiClient _api;

  Future<bool> isAdsRemoved() async {
    if (await _authService.hasStoredSession()) {
      try {
        final response = await _api.getJsonObject(
          '/billing/ads-removal/status',
        );
        final adsFree = response['adsFree'] as bool? ?? false;
        await setAdsRemoved(adsFree);
        return adsFree;
      } on AuthApiException {
        // Fall back to cached state so the UI still works offline.
      }
    }
>>>>>>> Stashed changes
    final p = await SharedPreferences.getInstance();
    return p.getBool(_keyAdsRemoved) ?? false;
  }

  Future<void> setAdsRemoved(bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_keyAdsRemoved, value);
  }
<<<<<<< Updated upstream
=======

  Future<void> purchaseAdsRemoval({required String purchaseToken}) async {
    if (!await _authService.hasStoredSession()) {
      throw AuthApiException('광고 제거 구매는 로그인 후 사용할 수 있어요.');
    }

    final order = await _api.postJsonObject('/billing/ads-removal/orders');
    final orderId = order['orderId'];
    if (orderId == null) {
      throw StateError('주문 생성 응답에 orderId가 없어요.');
    }

    await _api.postJsonObject(
      '/billing/ads-removal/confirm',
      body: <String, dynamic>{
        'orderId': orderId,
        'purchaseToken': purchaseToken,
      },
    );
    await setAdsRemoved(true);
  }
>>>>>>> Stashed changes
}
