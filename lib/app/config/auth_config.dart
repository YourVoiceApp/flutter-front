/// Central place for auth-related runtime settings used by Flutter.
///
/// Update values here, or override them with `--dart-define`.
///
/// Example:
/// `flutter run --dart-define=AUTH_API_BASE=http://10.0.2.2:9090`
/// `--dart-define=GOOGLE_SERVER_CLIENT_ID=xxxx.apps.googleusercontent.com`
/// `--dart-define=KAKAO_NATIVE_APP_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`
///
/// Notes:
/// - Android emulator should use `http://10.0.2.2:9090` instead of `localhost`.
/// - Some native platform files still mirror a few values here:
///   `android/app/src/main/AndroidManifest.xml`
///   `ios/Runner/Info.plist`
abstract final class AuthConfig {
  // ---------------------------------------------------------------------------
  // Backend
  // ---------------------------------------------------------------------------
  static const apiBaseUrl = String.fromEnvironment(
    'AUTH_API_BASE',
    defaultValue: 'http://43.202.13.147:9090',
  );

  static const googleAuthPath = String.fromEnvironment(
    'AUTH_GOOGLE_PATH',
    defaultValue: '/auth/google',
  );

  static const kakaoAuthPath = String.fromEnvironment(
    'AUTH_KAKAO_PATH',
    defaultValue: '/auth/kakao',
  );

  // ---------------------------------------------------------------------------
  // Google
  // ---------------------------------------------------------------------------
  /// Web OAuth client ID used as `serverClientId` so Flutter can receive
  /// an ID token and the backend can validate its audience.
  static const googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue:
        '498950596222-ipue9oeqdnsug7jt8rl0i77v5shrj06p.apps.googleusercontent.com',
  );

  static const googleIosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
    defaultValue:
        '498950596222-p466hd9uk790neei25bm7jqsbuhkh8r2.apps.googleusercontent.com',
  );

  static const googleIosReversedClientId = String.fromEnvironment(
    'GOOGLE_IOS_REVERSED_CLIENT_ID',
    defaultValue:
        'com.googleusercontent.apps.498950596222-p466hd9uk790neei25bm7jqsbuhkh8r2',
  );

  // ---------------------------------------------------------------------------
  // Kakao
  // ---------------------------------------------------------------------------
  /// Used only by the Flutter app to open Kakao auth and receive `code`.
  /// Backend token exchange should still use Kakao REST API key / secret.
  static const kakaoNativeAppKey = String.fromEnvironment(
    'KAKAO_NATIVE_APP_KEY',
    defaultValue: 'e4fc8019ea912c4a306ffb7dd98b80d8',
  );

  /// Must match the Kakao Developers redirect URI registered for the app.
  /// Recommended format: `kakao{NATIVE_APP_KEY}://oauth`
  static const kakaoRedirectScheme = String.fromEnvironment(
    'KAKAO_REDIRECT_SCHEME',
    defaultValue: 'kakaoe4fc8019ea912c4a306ffb7dd98b80d8',
  );

  static String get kakaoRedirectUri => '$kakaoRedirectScheme://oauth';
}
