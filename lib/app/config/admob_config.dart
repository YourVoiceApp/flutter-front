import 'package:flutter/foundation.dart';

/// AdMob IDs are centralized here so production IDs can replace test IDs later.
///
/// Native App IDs must also be mirrored in:
/// - android/app/src/main/AndroidManifest.xml
/// - ios/Runner/Info.plist
class AdMobConfig {
  const AdMobConfig._();

  static const androidTestAppId = 'ca-app-pub-3940256099942544~3347511713';
  static const iosTestAppId = 'ca-app-pub-3940256099942544~1458002511';

  static const androidTestBannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111';
  static const iosTestBannerAdUnitId = 'ca-app-pub-3940256099942544/2934735716';

  static const androidTestAppOpenAdUnitId =
      'ca-app-pub-3940256099942544/9257395921';
  static const iosTestAppOpenAdUnitId =
      'ca-app-pub-3940256099942544/5575463023';

  static const androidTestNativeAdUnitId =
      'ca-app-pub-3940256099942544/2247696110';
  static const iosTestNativeAdUnitId = 'ca-app-pub-3940256099942544/3986624511';

  /// Production Android AdMob IDs for 목음기.
  static const androidAppId = 'ca-app-pub-8414309358374456~5076626495';
  static const androidProductionBannerAdUnitId =
      'ca-app-pub-8414309358374456/1652992040';
  static const androidProductionNativeAdUnitId =
      'ca-app-pub-8414309358374456/7907638118';

  /// Replace iOS IDs with real AdMob ad unit IDs before iOS release.
  static const androidBannerAdUnitId = androidProductionBannerAdUnitId;
  static const iosBannerAdUnitId = iosTestBannerAdUnitId;
  static const androidAppOpenAdUnitId = androidTestAppOpenAdUnitId;
  static const iosAppOpenAdUnitId = iosTestAppOpenAdUnitId;
  static const androidNativeAdUnitId = androidProductionNativeAdUnitId;
  static const iosNativeAdUnitId = iosTestNativeAdUnitId;

  static bool get supportsMobileAds {
    return !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
  }

  static String? get bannerAdUnitId {
    if (!supportsMobileAds) return null;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => androidBannerAdUnitId,
      TargetPlatform.iOS => iosBannerAdUnitId,
      _ => null,
    };
  }

  static String? get appOpenAdUnitId {
    if (!supportsMobileAds) return null;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => androidAppOpenAdUnitId,
      TargetPlatform.iOS => iosAppOpenAdUnitId,
      _ => null,
    };
  }

  static String? get nativeAdUnitId {
    if (!supportsMobileAds) return null;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => androidNativeAdUnitId,
      TargetPlatform.iOS => iosNativeAdUnitId,
      _ => null,
    };
  }
}
