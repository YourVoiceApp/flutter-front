import '../../features/auth/data/auth_api_client.dart';
import '../../features/auth/data/auth_service.dart';
import '../../features/auth/data/auth_session_store.dart';
import '../../features/auth/data/google_backend_auth.dart';
import '../../features/auth/data/kakao_backend_auth.dart';
import '../../features/auth/data/user_profile_repository.dart';

/// Central app-level dependencies for auth/session flows.
///
/// Pages should read from this shared container instead of instantiating new
/// auth services ad-hoc, so login, refresh, logout, and local persistence all
/// go through one consistent path on web and mobile.
class AppServices {
  AppServices._()
    : authApiClient = AuthApiClient(),
      authSessionStore = AuthSessionStore(),
      userProfileRepository = UserProfileRepository() {
    authService = AuthService(
      apiClient: authApiClient,
      sessionStore: authSessionStore,
      profileRepository: userProfileRepository,
    );
    googleBackendAuth = GoogleBackendAuth(authService: authService);
    kakaoBackendAuth = KakaoBackendAuth(authService: authService);
  }

  static final AppServices instance = AppServices._();

  final AuthApiClient authApiClient;
  final AuthSessionStore authSessionStore;
  final UserProfileRepository userProfileRepository;

  late final AuthService authService;
  late final GoogleBackendAuth googleBackendAuth;
  late final KakaoBackendAuth kakaoBackendAuth;
}
