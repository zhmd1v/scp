import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class ApiServiceException implements Exception {
  const ApiServiceException(this.message);
  final String message;

  @override
  String toString() => 'ApiServiceException: $message';
}

class ApiService {
  ApiService({
    http.Client? client,
    String? baseUrl,
    Duration? timeout,
  })  : _client = client ?? http.Client(),
        _timeout = timeout ?? const Duration(seconds: 15),
        _baseUrl = baseUrl ?? _resolveDefaultBaseUrl();

  final http.Client _client;
  final Duration _timeout;
  String _baseUrl;

  static String _resolveDefaultBaseUrl() {
    return kBackendBaseUrl;
  }

  String get baseUrl => _baseUrl;

  void updateBaseUrl(String newBaseUrl) {
    if (newBaseUrl.isEmpty || newBaseUrl == _baseUrl) return;
    _baseUrl = newBaseUrl;
  }

  Uri buildUri(String path) {
    final normalizedBase =
        _baseUrl.endsWith('/') ? _baseUrl.substring(0, _baseUrl.length - 1) : _baseUrl;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$normalizedBase$normalizedPath');
  }

  Map<String, String> defaultHeaders({String? token}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Token $token';
    }
    return headers;
  }

  Future<http.Response> get(
    String path, {
    Map<String, String>? headers,
    String? token,
  }) {
    return _client
        .get(
          buildUri(path),
          headers: {
            ...defaultHeaders(token: token),
            ...?headers,
          },
        )
        .timeout(_timeout);
  }

  Future<http.Response> post(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    String? token,
  }) {
    return _client
        .post(
          buildUri(path),
          headers: {
            ...defaultHeaders(token: token),
            ...?headers,
          },
          body: body == null ? null : jsonEncode(body),
        )
        .timeout(_timeout);
  }

  Map<String, dynamic> decodeToMap(String body) {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) return decoded;
    throw const ApiServiceException('Unexpected response format from server.');
  }

  List<dynamic> decodeToList(String body) {
    final decoded = jsonDecode(body);
    if (decoded is List) return decoded;
    throw const ApiServiceException('Unexpected response format from server.');
  }

  String? extractErrorMessage(String body) {
    try {
      final parsed = jsonDecode(body);
      if (parsed is Map<String, dynamic>) {
        if (parsed['detail'] is String) return parsed['detail'] as String;
        if (parsed['error'] is String) return parsed['error'] as String;

        final listSegments = parsed.values.whereType<List<dynamic>>();
        if (listSegments.isNotEmpty) {
          final firstList = listSegments.first;
          if (firstList.isNotEmpty) return firstList.first.toString();
        }
      }
    } catch (_) {
      return null;
    }
    return null;
  }
}

