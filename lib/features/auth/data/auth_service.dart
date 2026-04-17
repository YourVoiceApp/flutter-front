import 'auth_api_client.dart';
import 'auth_device_info.dart';
import 'auth_session_store.dart';
import '../domain/auth_user.dart';
import '../domain/social_account_link.dart';
import '../domain/user_profile.dart';
import 'user_profile_repository.dart';

class AuthService {
  AuthService({
    AuthApiClient? apiClient,
    AuthSessionStore? sessionStore,
    UserProfileRepository? profileRepository,
  }) : _api = apiClient ?? AuthApiClient(),
       _sessions = sessionStore ?? AuthSessionStore(),
       _profiles = profileRepository ?? UserProfileRepository();

  final AuthApiClient _api;
  final AuthSessionStore _sessions;
  final UserProfileRepository _profiles;

  Future<AuthUser> signUpWithEmail({
    required String nickName,
    required String email,
    required String password,
  }) async {
    final result = await _api.signUp(
      nickName: nickName,
      email: email,
      password: password,
      deviceInfo: buildAuthDeviceInfo(),
    );
    return _completeSignIn(
      result,
      fallbackEmail: email,
      fallbackNickName: nickName,
      fallbackHasPassword: true,
    );
  }

  Future<void> sendEmailVerification({required String email}) {
    return _api.sendEmailVerification(email: email);
  }

  Future<void> verifyEmailCode({required String email, required String code}) {
    return _api.verifyEmailCode(email: email, code: code);
  }

  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final result = await _api.login(
      email: email,
      password: password,
      deviceInfo: buildAuthDeviceInfo(),
    );
    return _completeSignIn(
      result,
      fallbackEmail: email,
      fallbackNickName: email.split('@').first,
      fallbackHasPassword: true,
    );
  }

  Future<AuthUser> completeGoogleSignIn({
    required String idToken,
    required String fallbackEmail,
    required String fallbackNickName,
  }) async {
    final result = await _api.exchangeGoogleIdToken(
      idToken,
      deviceInfo: buildAuthDeviceInfo(),
    );
    return _completeSignIn(
      result,
      fallbackEmail: fallbackEmail,
      fallbackNickName: fallbackNickName,
      fallbackHasPassword: false,
    );
  }

  Future<AuthUser> completeKakaoSignIn({
    required String accessToken,
    required String fallbackNickName,
  }) async {
    final result = await _api.exchangeKakaoAccessToken(
      accessToken,
      deviceInfo: buildAuthDeviceInfo(),
    );
    return _completeSignIn(
      result,
      fallbackEmail: result.email ?? '',
      fallbackNickName: fallbackNickName,
      fallbackHasPassword: false,
    );
  }

  Future<AuthUser?> restoreSession() async {
    final refreshToken = await _sessions.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return null;
    try {
      final refreshed = await _api.refreshSession(refreshToken);
      await _persistSession(refreshed);
      final user = await _requireMe();
      await _cacheUser(user);
      return user;
    } catch (_) {
      await clearLocalSession();
      return null;
    }
  }

  Future<void> logout() async {
    final refreshToken = await _sessions.readRefreshToken();
    try {
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _api.logout(refreshToken);
      }
    } catch (_) {
      // Best effort; local sign-out must still complete.
    }
    await clearLocalSession();
  }

  Future<AuthUser> fetchCurrentUser() async {
    final user = await _authorized(_api.getCurrentUser);
    await _cacheUser(user);
    return user;
  }

  Future<AuthUser> updateNickname(String nickName) async {
    final user = await _authorized(
      (accessToken) => _api.updateProfile(accessToken, nickName: nickName),
    );
    await _cacheUser(user);
    return user;
  }

  Future<void> updatePassword({
    String? currentPassword,
    required String newPassword,
  }) async {
    await _authorizedVoid(
      (accessToken) => _api.updatePassword(
        accessToken,
        currentPassword: currentPassword,
        newPassword: newPassword,
      ),
    );
    final cached = await _profiles.loadProfile();
    if (cached != null && !cached.hasPassword) {
      await _profiles.updateProfile(cached.copyWith(hasPassword: true));
    }
  }

  Future<List<SocialAccountLink>> fetchSocialAccounts() {
    return _authorized(_api.getSocialAccounts);
  }

  Future<void> deleteAccount() async {
    await _authorizedVoid(_api.deleteMe);
    await clearLocalSession();
  }

  Future<UserProfile?> loadCachedProfile() {
    return _profiles.loadProfile();
  }

  Future<bool> hasStoredSession() async {
    final refreshToken = await _sessions.readRefreshToken();
    return refreshToken != null && refreshToken.isNotEmpty;
  }

  Future<T> authorizedRequest<T>(
    Future<T> Function(String accessToken) action,
  ) {
    return _authorized(action);
  }

  Future<void> authorizedRequestVoid(
    Future<void> Function(String accessToken) action,
  ) {
    return _authorizedVoid(action);
  }

  Future<void> clearLocalSession() async {
    await _sessions.clear();
    await _profiles.clear();
  }

  Future<AuthUser> _completeSignIn(
    AuthExchangeResult result, {
    required String fallbackEmail,
    required String fallbackNickName,
    required bool fallbackHasPassword,
  }) async {
    await _persistSession(result);
    try {
      final user = await _requireMe();
      await _cacheUser(user);
      return user;
    } catch (_) {
      final user = AuthUser(
        id: result.userId ?? 0,
        nickName: fallbackNickName,
        email: (result.email != null && result.email!.isNotEmpty)
            ? result.email!
            : fallbackEmail,
        hasPassword: fallbackHasPassword,
      );
      await _cacheUser(user);
      return user;
    }
  }

  Future<void> _persistSession(AuthExchangeResult result) async {
    await _sessions.save(
      accessToken: result.accessToken,
      refreshToken: result.refreshToken,
      userId: result.userId,
    );
  }

  Future<AuthUser> _requireMe() async {
    return _authorized(_api.getCurrentUser);
  }

  Future<void> _cacheUser(AuthUser user) async {
    if (user.email.isEmpty) return;
    await _profiles.saveProfile(
      email: user.email,
      nickname: user.nickName,
      hasPassword: user.hasPassword,
    );
  }

  Future<T> _authorized<T>(
    Future<T> Function(String accessToken) action,
  ) async {
    var accessToken = await _sessions.readAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      accessToken = await _refreshAccessToken();
    }

    try {
      return await action(accessToken);
    } on AuthApiException catch (e) {
      if (e.statusCode != 401) rethrow;
      accessToken = await _refreshAccessToken();
      return action(accessToken);
    }
  }

  Future<void> _authorizedVoid(
    Future<void> Function(String accessToken) action,
  ) async {
    await _authorized<void>((accessToken) => action(accessToken));
  }

  Future<String> _refreshAccessToken() async {
    final refreshToken = await _sessions.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      await clearLocalSession();
      throw StateError('No refresh token available.');
    }
    try {
      final refreshed = await _api.refreshSession(refreshToken);
      await _persistSession(refreshed);
      final nextAccessToken = refreshed.accessToken;
      if (nextAccessToken == null || nextAccessToken.isEmpty) {
        throw StateError('Refresh succeeded without a new access token.');
      }
      return nextAccessToken;
    } catch (_) {
      await clearLocalSession();
      rethrow;
    }
  }
}
