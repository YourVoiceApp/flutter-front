import 'package:flutter/foundation.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

import '../../../app/config/auth_config.dart';
import 'auth_api_client.dart';
import 'auth_device_info.dart';
import 'auth_session_store.dart';
import 'user_profile_repository.dart';

/// Kakao SDK login -> backend `/auth/kakao` with Kakao access token -> persist app session.
class KakaoBackendAuth {
  KakaoBackendAuth({
    AuthApiClient? apiClient,
    UserProfileRepository? profileRepository,
    AuthSessionStore? sessionStore,
  })  : _api = apiClient ?? AuthApiClient(),
        _profiles = profileRepository ?? UserProfileRepository(),
        _sessions = sessionStore ?? AuthSessionStore();

  final AuthApiClient _api;
  final UserProfileRepository _profiles;
  final AuthSessionStore _sessions;

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

    final AuthExchangeResult result;
    try {
      result = await _api.exchangeKakaoAccessToken(
        kakaoAccessToken,
        deviceInfo: buildAuthDeviceInfo(),
      );
    } finally {
      // We do not use Kakao tokens for app auth; keep only our backend JWT.
      await TokenManagerProvider.instance.manager.clear();
    }

    await _sessions.save(
      accessToken: result.accessToken,
      refreshToken: result.refreshToken,
      userId: result.userId,
    );

    final email = result.email;
    if (email == null || email.isEmpty) {
      throw StateError(
        'Backend did not return email. Check Kakao consent items or backend validation.',
      );
    }

    await _profiles.saveSocialSignInProfile(
      email: email,
      nickname: email.split('@').first,
      provider: 'kakao',
    );
  }
}
