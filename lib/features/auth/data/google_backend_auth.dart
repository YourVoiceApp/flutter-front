import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../app/config/auth_config.dart';
import 'auth_api_client.dart';
import 'auth_device_info.dart';
import 'auth_session_store.dart';
import 'google_auth_flow_exception.dart';
import 'user_profile_repository.dart';

/// Google Sign-In → [idToken] → your Spring API → persist session + local profile.
class GoogleBackendAuth {
  GoogleBackendAuth({
    AuthApiClient? apiClient,
    UserProfileRepository? profileRepository,
    AuthSessionStore? sessionStore,
  })  : _api = apiClient ?? AuthApiClient(),
        _profiles = profileRepository ?? UserProfileRepository(),
        _sessions = sessionStore ?? AuthSessionStore();

  final AuthApiClient _api;
  final UserProfileRepository _profiles;
  final AuthSessionStore _sessions;

  static Future<void>? _googleInit;

  static String? _platformClientId() {
    if (kIsWeb) return null;
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS => AuthConfig.googleIosClientId,
      TargetPlatform.macOS => AuthConfig.googleIosClientId,
      _ => null,
    };
  }

  static Future<void> _ensureGoogleSignInInitialized() async {
    try {
      _googleInit ??= GoogleSignIn.instance.initialize(
        clientId: _platformClientId(),
        serverClientId: AuthConfig.googleServerClientId.isEmpty
            ? null
            : AuthConfig.googleServerClientId,
      );
      await _googleInit!;
    } catch (e, _) {
      _googleInit = null;
      throw GoogleAuthFlowException(
        stage: GoogleAuthFailureStage.google,
        title: '[Google] Sign-In init failed',
        detail: '$e',
        cause: e,
      );
    }
  }

  /// Interactive sign-in, backend exchange, then saves tokens and profile.
  Future<void> signInExchangeAndPersist() async {
    await _ensureGoogleSignInInitialized();

    if (!GoogleSignIn.instance.supportsAuthenticate()) {
      throw GoogleAuthFlowException(
        stage: GoogleAuthFailureStage.google,
        title: '[Google] Not supported on this device',
        detail:
            'Use Android, iOS, macOS, or Web. (google_sign_in does not support Windows desktop.)',
      );
    }

    final GoogleSignInAccount account;
    try {
      account = await GoogleSignIn.instance
          .authenticate(
            scopeHint: const ['email', 'profile'],
          )
          .timeout(
            const Duration(minutes: 2),
            onTimeout: () => throw GoogleAuthFlowException(
              stage: GoogleAuthFailureStage.google,
              title: '[Google] Sign-in timed out',
              detail:
                  'No completion after account picker. Retry, or check Play Services / network.',
            ),
          );
    } on GoogleAuthFlowException {
      rethrow;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        rethrow;
      }
      throw GoogleAuthFlowException(
        stage: GoogleAuthFailureStage.google,
        title: '[Google] Account sign-in failed',
        detail: e.description?.isNotEmpty == true
            ? e.description!
            : e.toString(),
        cause: e,
      );
    }

    final idToken = account.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw GoogleAuthFlowException(
        stage: GoogleAuthFailureStage.google,
        title: '[Google] No idToken',
        detail:
            'Check Web OAuth client ID (serverClientId) in auth_config / Google Cloud.',
      );
    }

    final AuthExchangeResult result;
    try {
      result = await _api.exchangeGoogleIdToken(
        idToken,
        deviceInfo: buildAuthDeviceInfo(),
      );
    } on AuthApiException catch (e) {
      final title = e.isNetworkError
          ? '[Backend] Cannot reach server'
          : '[Backend] Server returned an error';
      final buf = StringBuffer();
      if (e.requestUri != null) {
        buf.writeln('POST ${e.requestUri}');
      }
      if (e.statusCode != null) {
        buf.writeln('HTTP ${e.statusCode}');
      }
      buf.write(e.message);
      throw GoogleAuthFlowException(
        stage: GoogleAuthFailureStage.backend,
        title: title,
        detail: buf.toString().trim(),
        cause: e,
      );
    }

    try {
      await _sessions.save(
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
        userId: result.userId,
      );
    } catch (e, _) {
      throw GoogleAuthFlowException(
        stage: GoogleAuthFailureStage.local,
        title: '[App] Failed to save session',
        detail: '$e',
        cause: e,
      );
    }

    final email = (result.email != null && result.email!.isNotEmpty)
        ? result.email!
        : account.email;
    if (email.isEmpty) {
      throw GoogleAuthFlowException(
        stage: GoogleAuthFailureStage.backend,
        title: '[Backend] No email in response',
        detail:
            'Server JSON should include email, or Google account must expose email.',
      );
    }

    final nickname = account.displayName?.trim();
    try {
      await _profiles.saveSocialSignInProfile(
        email: email,
        nickname: (nickname != null && nickname.isNotEmpty)
            ? nickname
            : email.split('@').first,
        provider: 'google',
      );
    } catch (e, _) {
      throw GoogleAuthFlowException(
        stage: GoogleAuthFailureStage.local,
        title: '[App] Failed to save profile',
        detail: '$e',
        cause: e,
      );
    }
  }

  /// Clears Google session and stored API tokens (e.g. logout).
  Future<void> signOutEverywhere() async {
    await _ensureGoogleSignInInitialized();
    await GoogleSignIn.instance.signOut();
    await _sessions.clear();
  }
}
