import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../app/config/auth_config.dart';
import '../domain/auth_user.dart';
import '../domain/social_account_link.dart';

class AuthApiException implements Exception {
  AuthApiException(
    this.message, {
    this.statusCode,
    this.isNetworkError = false,
    this.requestUri,
  });

  final String message;
  final int? statusCode;

  /// True when the request did not reach a valid HTTP response (timeout, DNS, refused, etc.).
  final bool isNetworkError;
  final Uri? requestUri;

  @override
  String toString() => 'AuthApiException($statusCode, network=$isNetworkError): $message';
}

/// Response from Spring after exchanging a social login credential.
class AuthExchangeResult {
  const AuthExchangeResult({
    this.accessToken,
    this.refreshToken,
    this.userId,
    this.email,
    this.raw,
  });

  final String? accessToken;
  final String? refreshToken;
  final int? userId;
  final String? email;
  final Map<String, dynamic>? raw;
}

class AuthApiClient {
  AuthApiClient({
    String? baseUrl,
    String? signUpPath,
    String? loginPath,
    String? emailSendVerificationPath,
    String? emailVerifyPath,
    String? googleAuthPath,
    String? kakaoAuthPath,
    String? refreshPath,
    String? logoutPath,
    String? mePath,
    String? profilePath,
    String? passwordPath,
    String? socialAccountsPath,
    String? deleteMePath,
    http.Client? httpClient,
  })  : _baseUrl = baseUrl ?? AuthConfig.apiBaseUrl,
        _signUpPath = signUpPath ?? '/auth/signup',
        _loginPath = loginPath ?? '/auth/login',
        _emailSendVerificationPath =
            emailSendVerificationPath ?? '/auth/email/send-verification',
        _emailVerifyPath = emailVerifyPath ?? '/auth/email/verify',
        _googlePath = googleAuthPath ?? AuthConfig.googleAuthPath,
        _kakaoPath = kakaoAuthPath ?? AuthConfig.kakaoAuthPath,
        _refreshPath = refreshPath ?? '/auth/refresh',
        _logoutPath = logoutPath ?? '/auth/logout',
        _mePath = mePath ?? '/me',
        _profilePath = profilePath ?? '/me/profile',
        _passwordPath = passwordPath ?? '/me/password',
        _socialAccountsPath = socialAccountsPath ?? '/me/social-accounts',
        _deleteMePath = deleteMePath ?? '/me',
        _http = httpClient ?? http.Client();

  final String _baseUrl;
  final String _signUpPath;
  final String _loginPath;
  final String _emailSendVerificationPath;
  final String _emailVerifyPath;
  final String _googlePath;
  final String _kakaoPath;
  final String _refreshPath;
  final String _logoutPath;
  final String _mePath;
  final String _profilePath;
  final String _passwordPath;
  final String _socialAccountsPath;
  final String _deleteMePath;
  final http.Client _http;

  Uri _socialUri(String pathValue) {
    final base = _baseUrl.endsWith('/')
        ? _baseUrl.substring(0, _baseUrl.length - 1)
        : _baseUrl;
    final path = pathValue.startsWith('/') ? pathValue : '/$pathValue';
    return Uri.parse('$base$path');
  }

  Uri _googleUri() => _socialUri(_googlePath);

  Uri _kakaoUri() => _socialUri(_kakaoPath);

  Uri _signUpUri() => _socialUri(_signUpPath);

  Uri _loginUri() => _socialUri(_loginPath);

  Uri _emailSendVerificationUri() => _socialUri(_emailSendVerificationPath);

  Uri _emailVerifyUri() => _socialUri(_emailVerifyPath);

  Uri _refreshUri() => _socialUri(_refreshPath);

  Uri _logoutUri() => _socialUri(_logoutPath);

  Uri _meUri() => _socialUri(_mePath);

  Uri _profileUri() => _socialUri(_profilePath);

  Uri _passwordUri() => _socialUri(_passwordPath);

  Uri _socialAccountsUri() => _socialUri(_socialAccountsPath);

  Uri _deleteMeUri() => _socialUri(_deleteMePath);

  Future<AuthExchangeResult> signUp({
    required String nickName,
    required String email,
    required String password,
    required String deviceInfo,
  }) {
    return _postExchange(
      _signUpUri(),
      <String, String>{
        'nickName': nickName,
        'email': email,
        'password': password,
        'deviceInfo': deviceInfo,
      },
    );
  }

  Future<AuthExchangeResult> login({
    required String email,
    required String password,
    required String deviceInfo,
  }) {
    return _postExchange(
      _loginUri(),
      <String, String>{
        'email': email,
        'password': password,
        'deviceInfo': deviceInfo,
      },
    );
  }

  Future<void> sendEmailVerification({
    required String email,
  }) async {
    await _sendNoContent(
      'POST',
      _emailSendVerificationUri(),
      body: <String, String>{'email': email},
      successCodes: const {204},
    );
  }

  Future<void> verifyEmailCode({
    required String email,
    required String code,
  }) async {
    await _sendNoContent(
      'POST',
      _emailVerifyUri(),
      body: <String, String>{
        'email': email,
        'code': code,
      },
      successCodes: const {204},
    );
  }

  /// Sends `{ "idToken", "deviceInfo" }` to match Spring contract.
  Future<AuthExchangeResult> exchangeGoogleIdToken(
    String idToken, {
    required String deviceInfo,
  }) async {
    return _postExchange(
      _googleUri(),
      <String, String>{
        'idToken': idToken,
        'deviceInfo': deviceInfo,
      },
    );
  }

  /// Sends `{ "accessToken", "deviceInfo" }` to match Spring Kakao contract.
  Future<AuthExchangeResult> exchangeKakaoAccessToken(
    String accessToken, {
    required String deviceInfo,
  }) async {
    return _postExchange(
      _kakaoUri(),
      <String, String>{
        'accessToken': accessToken,
        'deviceInfo': deviceInfo,
      },
    );
  }

  Future<AuthExchangeResult> refreshSession(String refreshToken) {
    return _postExchange(
      _refreshUri(),
      <String, String>{'refreshToken': refreshToken},
    );
  }

  Future<void> logout(String refreshToken) async {
    await _sendNoContent(
      'POST',
      _logoutUri(),
      body: <String, String>{'refreshToken': refreshToken},
      successCodes: const {204},
    );
  }

  Future<AuthUser> getCurrentUser(String accessToken) async {
    final decoded = await _sendJson(
      'GET',
      _meUri(),
      bearerToken: accessToken,
    );
    return _parseAuthUser(decoded);
  }

  Future<AuthUser> updateProfile(
    String accessToken, {
    required String nickName,
  }) async {
    final decoded = await _sendJson(
      'PATCH',
      _profileUri(),
      bearerToken: accessToken,
      body: <String, String>{'nickName': nickName},
    );
    return _parseAuthUser(decoded);
  }

  Future<void> updatePassword(
    String accessToken, {
    String? currentPassword,
    required String newPassword,
  }) async {
    final body = <String, String>{'newPassword': newPassword};
    if (currentPassword != null && currentPassword.isNotEmpty) {
      body['currentPassword'] = currentPassword;
    }
    await _sendNoContent(
      'PATCH',
      _passwordUri(),
      bearerToken: accessToken,
      body: body,
      successCodes: const {204},
    );
  }

  Future<List<SocialAccountLink>> getSocialAccounts(String accessToken) async {
    final decoded = await _sendJsonList(
      'GET',
      _socialAccountsUri(),
      bearerToken: accessToken,
    );
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(
          (item) => SocialAccountLink(
            provider: item['provider'] as String? ?? '',
            email: item['email'] as String? ?? '',
          ),
        )
        .toList(growable: false);
  }

  Future<void> deleteMe(String accessToken) async {
    await _sendNoContent(
      'DELETE',
      _deleteMeUri(),
      bearerToken: accessToken,
      successCodes: const {204},
    );
  }

  Future<AuthExchangeResult> _postExchange(
    Uri uri,
    Map<String, String> body,
  ) async {
    final decoded = await _sendJson(
      'POST',
      uri,
      body: body,
    );
    return _parseExchangeResult(decoded);
  }

  Future<Map<String, dynamic>> _sendJson(
    String method,
    Uri uri, {
    String? bearerToken,
    Map<String, String>? body,
    Set<int> successCodes = const {200},
  }) async {
    final response = await _send(
      method,
      uri,
      bearerToken: bearerToken,
      body: body,
    );
    _ensureSuccess(response, uri, successCodes);
    if (response.body.isEmpty) return <String, dynamic>{};

    final decoded = _decodeJson(response, uri);
    if (decoded is Map<String, dynamic>) return decoded;
    throw AuthApiException(
      'Expected JSON object but got ${decoded.runtimeType}',
      statusCode: response.statusCode,
      requestUri: uri,
    );
  }

  Future<List<dynamic>> _sendJsonList(
    String method,
    Uri uri, {
    String? bearerToken,
    Map<String, String>? body,
    Set<int> successCodes = const {200},
  }) async {
    final response = await _send(
      method,
      uri,
      bearerToken: bearerToken,
      body: body,
    );
    _ensureSuccess(response, uri, successCodes);
    if (response.body.isEmpty) return const <dynamic>[];

    final decoded = _decodeJson(response, uri);
    if (decoded is List<dynamic>) return decoded;
    throw AuthApiException(
      'Expected JSON array but got ${decoded.runtimeType}',
      statusCode: response.statusCode,
      requestUri: uri,
    );
  }

  Future<void> _sendNoContent(
    String method,
    Uri uri, {
    String? bearerToken,
    Map<String, String>? body,
    Set<int> successCodes = const {200, 204},
  }) async {
    final response = await _send(
      method,
      uri,
      bearerToken: bearerToken,
      body: body,
    );
    _ensureSuccess(response, uri, successCodes);
  }

  Future<http.Response> _send(
    String method,
    Uri uri, {
    String? bearerToken,
    Map<String, String>? body,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Accept': 'application/json',
      if (bearerToken != null && bearerToken.isNotEmpty)
        'Authorization': 'Bearer $bearerToken',
    };
    try {
      final request = switch (method.toUpperCase()) {
        'GET' => _http.get(uri, headers: headers),
        'POST' => _http.post(
            uri,
            headers: headers,
            body: body == null ? null : jsonEncode(body),
          ),
        'PATCH' => _http.patch(
            uri,
            headers: headers,
            body: body == null ? null : jsonEncode(body),
          ),
        'DELETE' => _http.delete(
            uri,
            headers: headers,
            body: body == null ? null : jsonEncode(body),
          ),
        _ => throw UnsupportedError('Unsupported HTTP method: $method'),
      };
      return await request.timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw AuthApiException(
          'Request timed out after 30s',
          isNetworkError: true,
          requestUri: uri,
        ),
      );
    } on AuthApiException {
      rethrow;
    } on http.ClientException catch (e) {
      throw AuthApiException(
        e.message,
        isNetworkError: true,
        requestUri: uri,
      );
    } catch (e) {
      final text = e.toString();
      if (text.contains('SocketException') ||
          text.contains('Failed host lookup')) {
        throw AuthApiException(
          text,
          isNetworkError: true,
          requestUri: uri,
        );
      }
      rethrow;
    }
  }

  void _ensureSuccess(
    http.Response response,
    Uri uri,
    Set<int> successCodes,
  ) {
    if (successCodes.contains(response.statusCode)) return;
    final bodyPreview = response.body.length > 500
        ? '${response.body.substring(0, 500)}…'
        : response.body;
    throw AuthApiException(
      bodyPreview.isEmpty ? 'HTTP ${response.statusCode}' : bodyPreview,
      statusCode: response.statusCode,
      requestUri: uri,
    );
  }

  Object? _decodeJson(http.Response response, Uri uri) {
    try {
      return jsonDecode(response.body);
    } catch (e) {
      throw AuthApiException(
        'Invalid JSON in response: $e',
        statusCode: response.statusCode,
        requestUri: uri,
      );
    }
  }
}

AuthExchangeResult _parseExchangeResult(Map<String, dynamic> decoded) {
  var access = _pickString(decoded, const [
    'accessToken',
    'access_token',
    'token',
  ]);
  var refresh = _pickString(decoded, const [
    'refreshToken',
    'refresh_token',
  ]);
  var userId = _pickInt(decoded, const ['userId', 'user_id']);
  var email = _pickString(decoded, const ['email']);

  final data = decoded['data'];
  if (data is Map<String, dynamic>) {
    access ??= _pickString(data, const [
      'accessToken',
      'access_token',
      'token',
    ]);
    refresh ??= _pickString(data, const [
      'refreshToken',
      'refresh_token',
    ]);
    userId ??= _pickInt(data, const ['userId', 'user_id']);
    email ??= _pickString(data, const ['email']);
  }

  return AuthExchangeResult(
    accessToken: access,
    refreshToken: refresh,
    userId: userId,
    email: email,
    raw: decoded,
  );
}

AuthUser _parseAuthUser(Map<String, dynamic> decoded) {
  return AuthUser(
    id: _pickInt(decoded, const ['id', 'userId', 'user_id']) ?? 0,
    nickName: _pickString(decoded, const ['nickName', 'nickname']) ?? '',
    email: _pickString(decoded, const ['email']) ?? '',
    hasPassword: decoded['hasPassword'] as bool? ?? true,
  );
}

String? _pickString(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    if (value is String && value.isNotEmpty) {
      return value;
    }
  }
  return null;
}

int? _pickInt(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
  }
  return null;
}
