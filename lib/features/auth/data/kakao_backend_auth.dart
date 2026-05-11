import 'package:flutter/foundation.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

import '../../../app/config/auth_config.dart';
import 'auth_service.dart';

/// Kakao SDK login -> backend `/auth/kakao` with Kakao access token -> persist app session.
class KakaoBackendAuth {
  KakaoBackendAuth({
    AuthService? authService,
  }) : _authService = authService ?? AuthService();

  final AuthService _authService;

  static Future<void>? _kakaoInit;

  static Future<void> _ensureKakaoInitialized() async {
    if (kIsWeb) {
      throw UnsupportedError('Kakao login is not configured for web in this app.');
    }
    if (AuthConfig.kakaoNativeAppKey.isEmpty) {
      throw StateError(
        'KAKAO_NATIVE_APP_KEY is missing. Add it in auth_config.dart or pass --dart-define.',
      );
    }

    _kakaoInit ??= KakaoSdk.init(
      nativeAppKey: AuthConfig.kakaoNativeAppKey,
      customScheme: AuthConfig.kakaoRedirectScheme,
    );
    await _kakaoInit!;
  }

  Future<void> signInExchangeAndPersist() async {
    await _ensureKakaoInitialized();

    late final OAuthToken kakaoToken;
    final talkInstalled = await isKakaoTalkInstalled();
    if (talkInstalled) {
      try {
        kakaoToken = await UserApi.instance.loginWithKakaoTalk();
      } catch (_) {
        kakaoToken = await UserApi.instance.loginWithKakaoAccount();
      }
    } else {
      kakaoToken = await UserApi.instance.loginWithKakaoAccount();
    }

    final kakaoAccessToken = kakaoToken.accessToken;
    if (kakaoAccessToken.isEmpty) {
      throw StateError('Kakao did not return an access token.');
    }

    try {
      await _authService.completeKakaoSignIn(
        accessToken: kakaoAccessToken,
        /// `/me` 실패 시 빈 닉으로 두어 닉네임 설정 화면으로 유도
        fallbackNickName: '',
      );
    } finally {
      // We do not use Kakao tokens for app auth; keep only our backend JWT.
      await TokenManagerProvider.instance.manager.clear();
    }
  }
}
