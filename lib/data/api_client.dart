import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'lifeshare_api.dart';

/// Small JSON-over-HTTP wrapper for the Spring Boot backend.
///
/// - Sends `Authorization: Bearer <token>` once a token is set.
/// - Sends `Accept-Language: ar|en` so the backend can localise error messages.
/// - Turns non-2xx responses into [ApiException], reading `message` from the
///   Spring Boot error body when there is one.
class ApiClient {
  ApiClient({String? baseUrl, http.Client? client})
      : baseUrl = baseUrl ?? AppConfig.apiBaseUrl,
        _http = client ?? http.Client();

  final String baseUrl;
  final http.Client _http;
  String? token;
  String language = 'ar';

  Map<String, String> get _headers => {
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'application/json',
        'Accept-Language': language,
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Uri _uri(String path, [Map<String, String?>? query]) {
    final q = <String, String>{};
    query?.forEach((k, v) {
      if (v != null && v.isNotEmpty) q[k] = v;
    });
    return Uri.parse('$baseUrl$path').replace(queryParameters: q.isEmpty ? null : q);
  }

  Future<dynamic> get(String path, {Map<String, String?>? query}) =>
      _send(() => _http.get(_uri(path, query), headers: _headers));

  Future<dynamic> post(String path, [Object? body]) => _send(() => _http.post(
        _uri(path),
        headers: _headers,
        body: body == null ? null : jsonEncode(body),
      ));

  Future<dynamic> patch(String path, [Object? body]) => _send(() => _http.patch(
        _uri(path),
        headers: _headers,
        body: body == null ? null : jsonEncode(body),
      ));

  Future<dynamic> _send(Future<http.Response> Function() call) async {
    http.Response res;
    try {
      res = await call().timeout(AppConfig.requestTimeout);
    } on TimeoutException {
      throw const ApiException('timeout');
    } on Exception {
      // No connection, wrong IP, backend not running, etc.
      throw const ApiException('network');
    }

    final text = utf8.decode(res.bodyBytes);
    final dynamic data = text.isEmpty ? null : jsonDecode(text);

    if (res.statusCode >= 200 && res.statusCode < 300) return data;

    String message = 'server';
    if (data is Map && data['message'] is String) message = data['message'] as String;
    throw ApiException(message, statusCode: res.statusCode);
  }
}
