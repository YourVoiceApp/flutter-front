import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../app/config/auth_config.dart';

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

/// Response from Spring after verifying Google [idToken].
class GoogleIdTokenExchangeResult {
  const GoogleIdTokenExchangeResult({
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
    String? googleAuthPath,
    http.Client? httpClient,
  })  : _baseUrl = baseUrl ?? AuthConfig.apiBaseUrl,
        _googlePath = googleAuthPath ?? AuthConfig.googleAuthPath,
        _http = httpClient ?? http.Client();

  final String _baseUrl;
  final String _googlePath;
  final http.Client _http;

  Uri _googleUri() {
    final base = _baseUrl.endsWith('/')
        ? _baseUrl.substring(0, _baseUrl.length - 1)
        : _baseUrl;
    final path =
        _googlePath.startsWith('/') ? _googlePath : '/$_googlePath';
    return Uri.parse('$base$path');
  }

  /// Sends `{ "idToken", "deviceInfo" }` to match Spring contract.
  Future<GoogleIdTokenExchangeResult> exchangeGoogleIdToken(
    String idToken, {
    required String deviceInfo,
  }) async {
    final uri = _googleUri();
    late http.Response response;
    try {
      response = await _http
          .post(
            uri,
            headers: const {
              'Content-Type': 'application/json; charset=UTF-8',
              'Accept': 'application/json',
            },
            body: jsonEncode(<String, String>{
              'idToken': idToken,
              'deviceInfo': deviceInfo,
            }),
          )
          .timeout(
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
      if (e is AuthApiException) rethrow;
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

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final bodyPreview = response.body.length > 500
          ? '${response.body.substring(0, 500)}…'
          : response.body;
      throw AuthApiException(
        bodyPreview.isEmpty
            ? 'HTTP ${response.statusCode}'
            : bodyPreview,
        statusCode: response.statusCode,
        requestUri: uri,
      );
    }

    if (response.body.isEmpty) {
      return const GoogleIdTokenExchangeResult();
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (e) {
      throw AuthApiException(
        'Invalid JSON in response: $e',
        statusCode: response.statusCode,
        requestUri: uri,
      );
    }
    if (decoded is! Map<String, dynamic>) {
      return GoogleIdTokenExchangeResult(raw: {'_text': response.body});
    }

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

    return GoogleIdTokenExchangeResult(
      accessToken: access,
      refreshToken: refresh,
      userId: userId,
      email: email,
      raw: decoded,
    );
  }
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
