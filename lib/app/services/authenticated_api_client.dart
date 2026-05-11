import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../features/auth/data/auth_api_client.dart';
import '../../features/auth/data/auth_service.dart';
import '../config/auth_config.dart';

class MultipartPayloadFile {
  const MultipartPayloadFile({
    required this.fieldName,
    required this.filename,
    required this.bytes,
    this.contentType,
  });

  final String fieldName;
  final String filename;
  final Uint8List bytes;

  /// Guessed `Content-Type` part for common recorder / picker extensions.
  final MediaType? contentType;

  static MediaType contentTypeForAudioFilename(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.mp3')) return MediaType('audio', 'mpeg');
    if (lower.endsWith('.m4a') || lower.endsWith('.aac')) {
      return MediaType('audio', 'mp4');
    }
    if (lower.endsWith('.wav')) return MediaType('audio', 'wav');
    if (lower.endsWith('.ogg')) return MediaType('audio', 'ogg');
    if (lower.endsWith('.flac')) return MediaType('audio', 'flac');
    if (lower.endsWith('.webm')) return MediaType('audio', 'webm');
    if (lower.endsWith('.amr')) return MediaType('audio', 'amr');
    return MediaType('application', 'octet-stream');
  }
}

/// Small helper for authenticated JSON / multipart calls outside auth flows.
class AuthenticatedApiClient {
  AuthenticatedApiClient({
    required AuthService authService,
    String? baseUrl,
    http.Client? httpClient,
  }) : _authService = authService,
       _baseUrl = baseUrl ?? AuthConfig.apiBaseUrl,
       _http = httpClient ?? http.Client();

  final AuthService _authService;
  final String _baseUrl;
  final http.Client _http;

  Uri _uri(
    String path, {
    Map<String, String?>? queryParameters,
    bool includeEmptyQueryValues = false,
  }) {
    final base = _baseUrl.endsWith('/')
        ? _baseUrl.substring(0, _baseUrl.length - 1)
        : _baseUrl;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('$base$normalizedPath');
    final filteredQuery = queryParameters == null
        ? null
        : <String, String>{
            for (final entry in queryParameters.entries)
              if (entry.value != null &&
                  (includeEmptyQueryValues || entry.value!.isNotEmpty))
                entry.key: entry.value!,
          };
    return filteredQuery == null || filteredQuery.isEmpty
        ? uri
        : uri.replace(queryParameters: filteredQuery);
  }

  Future<Map<String, dynamic>> getJsonObject(
    String path, {
    Map<String, String?>? queryParameters,
  }) {
    return _sendJsonObject('GET', _uri(path, queryParameters: queryParameters));
  }

  Future<List<dynamic>> getJsonList(
    String path, {
    Map<String, String?>? queryParameters,
  }) {
    return _sendJsonList('GET', _uri(path, queryParameters: queryParameters));
  }

  Future<Map<String, dynamic>> postJsonObject(
    String path, {
    Map<String, dynamic>? body,
    Set<int> successCodes = const {200},
  }) {
    return _sendJsonObject(
      'POST',
      _uri(path),
      body: body,
      successCodes: successCodes,
    );
  }

  /// POST that expects a JSON **array** in the response body.
  Future<List<dynamic>> postJsonList(
    String path, {
    Map<String, dynamic>? body,
    Set<int> successCodes = const {200, 201},
  }) {
    return _sendJsonList('POST', _uri(path), body: body, successCodes: successCodes);
  }

  Future<Map<String, dynamic>> putJsonObject(
    String path, {
    Map<String, dynamic>? body,
  }) {
    return _sendJsonObject('PUT', _uri(path), body: body);
  }

  Future<Map<String, dynamic>> patchJsonObject(
    String path, {
    Map<String, dynamic>? body,
  }) {
    return _sendJsonObject('PATCH', _uri(path), body: body);
  }

  Future<List<dynamic>> patchJsonList(
    String path, {
    Map<String, dynamic>? body,
  }) {
    return _sendJsonList('PATCH', _uri(path), body: body);
  }

  Future<void> deleteNoContent(String path) {
    return _sendNoContent('DELETE', _uri(path));
  }

  Future<Uint8List> getBytes(
    String path, {
    Map<String, String?>? queryParameters,
    String accept = 'audio/mpeg,*/*',
    Duration timeout = const Duration(seconds: 120),
  }) async {
    final uri = _uri(path, queryParameters: queryParameters);
    return getBytesUri(uri, accept: accept, timeout: timeout);
  }

  /// 절대 URL(예: 합성 응답의 [streamUrl]) — 베이스 URL을 붙이지 않습니다.
  Future<Uint8List> getBytesUri(
    Uri uri, {
    String accept = 'audio/mpeg,*/*',
    Duration timeout = const Duration(seconds: 120),
  }) async {
    return _authService.authorizedRequest((accessToken) async {
      final headers = <String, String>{
        'Accept': accept,
        'Authorization': 'Bearer $accessToken',
      };
      try {
        final response = await _http.get(uri, headers: headers).timeout(
          timeout,
          onTimeout: () => throw AuthApiException(
            'Request timed out after ${timeout.inSeconds}s',
            isNetworkError: true,
            requestUri: uri,
          ),
        );
        _ensureSuccess(response, uri, const {200});
        return response.bodyBytes;
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
          throw AuthApiException(text, isNetworkError: true, requestUri: uri);
        }
        rethrow;
      }
    });
  }

  Future<Map<String, dynamic>> postMultipartObject(
    String path, {
    Map<String, String> fields = const {},
    Map<String, String?>? queryParameters,
    List<MultipartPayloadFile> files = const [],
  }) async {
    final uri = _uri(
      path,
      queryParameters: queryParameters,
      includeEmptyQueryValues: true,
    );
    return _authService.authorizedRequest((accessToken) async {
      final request = http.MultipartRequest('POST', uri)
        ..headers['Accept'] = 'application/json'
        ..headers['Authorization'] = 'Bearer $accessToken'
        ..fields.addAll(fields);
      for (final file in files) {
        final type = file.contentType ??
            MultipartPayloadFile.contentTypeForAudioFilename(file.filename);
        request.files.add(
          http.MultipartFile.fromBytes(
            file.fieldName,
            file.bytes,
            filename: file.filename,
            contentType: type,
          ),
        );
      }
      try {
        final streamed = await request.send().timeout(
          const Duration(seconds: 120),
          onTimeout: () => throw AuthApiException(
            'Request timed out after 120s',
            isNetworkError: true,
            requestUri: uri,
          ),
        );
        final response = await http.Response.fromStream(streamed);
        _ensureSuccess(response, uri, const {200, 201});
        if (response.body.isEmpty) return <String, dynamic>{};
        final decoded = _decodeJson(response, uri);
        if (decoded is Map<String, dynamic>) return decoded;
        throw AuthApiException(
          'Expected JSON object but got ${decoded.runtimeType}',
          statusCode: response.statusCode,
          requestUri: uri,
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
          throw AuthApiException(text, isNetworkError: true, requestUri: uri);
        }
        rethrow;
      }
    });
  }

  Future<Map<String, dynamic>> _sendJsonObject(
    String method,
    Uri uri, {
    Map<String, dynamic>? body,
    Set<int> successCodes = const {200},
  }) async {
    final response = await _send(method, uri, body: body);
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
    Map<String, dynamic>? body,
    Set<int> successCodes = const {200},
  }) async {
    final response = await _send(method, uri, body: body);
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
    Map<String, dynamic>? body,
    Set<int> successCodes = const {200, 204},
  }) async {
    final response = await _send(method, uri, body: body);
    _ensureSuccess(response, uri, successCodes);
  }

  Future<http.Response> _send(
    String method,
    Uri uri, {
    Map<String, dynamic>? body,
  }) {
    return _authService.authorizedRequest((accessToken) async {
      final headers = <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
        'Authorization': 'Bearer $accessToken',
      };
      try {
        final request = switch (method.toUpperCase()) {
          'GET' => _http.get(uri, headers: headers),
          'POST' => _http.post(
            uri,
            headers: headers,
            body: body == null ? null : jsonEncode(body),
          ),
          'PUT' => _http.put(
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
          throw AuthApiException(text, isNetworkError: true, requestUri: uri);
        }
        rethrow;
      }
    });
  }

  void _ensureSuccess(http.Response response, Uri uri, Set<int> successCodes) {
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
