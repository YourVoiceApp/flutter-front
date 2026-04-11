/// Backend URL and Google OAuth values for compile-time injection.
///
/// Example:
/// `flutter run --dart-define=AUTH_API_BASE=http://10.0.2.2:9090`
/// `--dart-define=GOOGLE_SERVER_CLIENT_ID=xxxx.apps.googleusercontent.com`
///
/// Android emulator: use `http://10.0.2.2:9090` instead of `localhost`.
///
/// [googleServerClientId] must be the **Web application** OAuth client ID from
/// Google Cloud (used as `serverClientId`) so the plugin can return an
/// **idToken** on Android/iOS.
abstract final class AuthConfig {
  static const apiBaseUrl = String.fromEnvironment(
    'AUTH_API_BASE',
    defaultValue: 'http://43.202.13.147:9090',
  );

  /// POST `/auth/google` with `{ "idToken", "deviceInfo" }`.
  static const googleAuthPath = String.fromEnvironment(
    'AUTH_GOOGLE_PATH',
    defaultValue: '/auth/google',
  );

  static const googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue:
        '498950596222-ipue9oeqdnsug7jt8rl0i77v5shrj06p.apps.googleusercontent.com',
  );
}
