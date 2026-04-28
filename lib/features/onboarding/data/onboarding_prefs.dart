import 'package:shared_preferences/shared_preferences.dart';

/// 셸 하단 탭별 첫 방문 안내(코치마크) — 탭마다 한 번만
class OnboardingPrefs {
  OnboardingPrefs._();

  static String _shellCoachKey(int tabIndex) =>
      'shell_coach_tab_${tabIndex.clamp(0, 2)}_v2';

  static Future<bool> isShellTabCoachDismissed(int tabIndex) async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_shellCoachKey(tabIndex)) ?? false;
  }

  static Future<void> setShellTabCoachDismissed(int tabIndex) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_shellCoachKey(tabIndex), true);
  }

  static const _kVoiceRootCtaCoach = 'voice_root_cta_coach_v1';

  static Future<bool> isVoiceRootCtaCoachDone() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kVoiceRootCtaCoach) ?? false;
  }

  static Future<void> setVoiceRootCtaCoachDone() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kVoiceRootCtaCoach, true);
  }

  static const _kRoomHubIntro = 'room_coach_hub_intro_v1';
  static const _kRoomShareFab = 'room_coach_share_fab_v1';
  static const _kMarketSegment = 'market_coach_segment_v1';
  static const _kMarketPreview = 'market_coach_preview_v1';

  static Future<bool> isRoomHubIntroDone() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kRoomHubIntro) ?? false;
  }

  static Future<void> setRoomHubIntroDone() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kRoomHubIntro, true);
  }

  static Future<bool> isRoomShareFabDone() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kRoomShareFab) ?? false;
  }

  static Future<void> setRoomShareFabDone() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kRoomShareFab, true);
  }

  static Future<bool> isMarketSegmentCoachDone() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kMarketSegment) ?? false;
  }

  static Future<void> setMarketSegmentCoachDone() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kMarketSegment, true);
  }

  static Future<bool> isMarketPreviewCoachDone() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kMarketPreview) ?? false;
  }

  static Future<void> setMarketPreviewCoachDone() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kMarketPreview, true);
  }

  /// 설정·디버그용: 모든 탭 안내 다시 보기
  static Future<void> clearAllShellTabCoaches() async {
    final p = await SharedPreferences.getInstance();
    for (var i = 0; i < 3; i++) {
      await p.remove(_shellCoachKey(i));
    }
    await p.remove(_kVoiceRootCtaCoach);
    await p.remove(_kRoomHubIntro);
    await p.remove(_kRoomShareFab);
    await p.remove(_kMarketSegment);
    await p.remove(_kMarketPreview);
  }
}
