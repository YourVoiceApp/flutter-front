import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../../app/config/admob_config.dart';

class AppOpenAdManager {
  AppOpenAdManager._();

  static final AppOpenAdManager instance = AppOpenAdManager._();

  static bool _shownThisSession = false;

  AppOpenAd? _ad;
  DateTime? _loadedAt;
  bool _loading = false;
  bool _showing = false;
  bool _showWhenLoaded = false;

  bool get _isFresh {
    final loadedAt = _loadedAt;
    if (_ad == null || loadedAt == null) return false;
    return DateTime.now().difference(loadedAt) < const Duration(hours: 4);
  }

  void load() {
    if (_loading || _isFresh) return;
    final adUnitId = AdMobConfig.appOpenAdUnitId;
    if (adUnitId == null) return;

    _loading = true;
    AppOpenAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _loading = false;
          _ad?.dispose();
          _ad = ad;
          _loadedAt = DateTime.now();
          if (_showWhenLoaded) {
            _showWhenLoaded = false;
            showOnceIfAvailable();
          }
        },
        onAdFailedToLoad: (_) {
          _loading = false;
          _ad = null;
          _loadedAt = null;
        },
      ),
    );
  }

  void showOnceIfAvailable() {
    if (_shownThisSession || _showing) return;
    if (!_isFresh) {
      _showWhenLoaded = true;
      load();
      return;
    }

    final ad = _ad;
    if (ad == null) return;

    _shownThisSession = true;
    _showing = true;
    ad.fullScreenContentCallback = FullScreenContentCallback<AppOpenAd>(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _ad = null;
        _loadedAt = null;
        _showing = false;
        load();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _ad = null;
        _loadedAt = null;
        _showing = false;
        load();
      },
    );
    ad.show();
  }
}
