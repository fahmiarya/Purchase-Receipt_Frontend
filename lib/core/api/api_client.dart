// lib/core/api/api_client.dart
// Base HTTP client: BASE_URL, JSON envelope handling, error mapping.

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String message;

  /// Optional `details` object returned by the API alongside `error`.
  final dynamic details;

  ApiException(this.message, [this.details]);

  @override
  String toString() => 'ApiException: $message';
}

/// Maps any thrown error to a user-facing message following
/// the error handling rules in REQUIREMENTS.md.
String apiErrorMessage(Object error) {
  if (error is ApiException) return error.message;
  return 'Gagal terhubung ke server';
}

class ApiClient {
  final String baseUrl;
  ApiClient({required this.baseUrl});

  /// Parses the standard `{ success, data, message }` success envelope and
  /// `{ success: false, error, details }` error envelope.
  /// Falls back to generic HTTP errors when the body is not JSON.
  Future<Map<String, dynamic>> _handleResponse(http.Response response) async {
    Map<String, dynamic>? json;
    if (response.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) json = decoded;
      } catch (_) {
        // Non-JSON body — handled below.
      }
    }

    final ok = response.statusCode >= 200 && response.statusCode < 300;

    if (json != null && json.containsKey('success')) {
      if (json['success'] == true && ok) return json;
      throw ApiException(
        (json['error'] ?? 'Terjadi kesalahan (HTTP ${response.statusCode})').toString(),
        json['details'],
      );
    }

    if (ok) return json ?? <String, dynamic>{};
    throw ApiException('HTTP ${response.statusCode}: ${response.reasonPhrase ?? ''}'.trim());
  }

  /// Wraps a request so network failures / timeouts are reported as
  /// "Gagal terhubung ke server" instead of raw socket exceptions.
  Future<Map<String, dynamic>> _run(Future<http.Response> Function() request) async {
    try {
      return await _handleResponse(await request());
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException('Gagal terhubung ke server');
    } catch (_) {
      throw ApiException('Gagal terhubung ke server');
    }
  }

  Future<Map<String, dynamic>> get(String path, {Map<String, String>? query}) {
    return _run(() async {
      final uri = Uri.parse('$baseUrl$path').replace(
        queryParameters: (query == null || query.isEmpty) ? null : query,
      );
      return http.get(uri);
    });
  }

  Future<Map<String, dynamic>> post(String path, dynamic body) {
    return _run(() => http.post(
          Uri.parse('$baseUrl$path'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        ));
  }

  Future<Map<String, dynamic>> put(String path, dynamic body) {
    return _run(() => http.put(
          Uri.parse('$baseUrl$path'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        ));
  }

  Future<Map<String, dynamic>> patch(String path, {dynamic body}) {
    return _run(() => http.patch(
          Uri.parse('$baseUrl$path'),
          headers: body == null ? null : {'Content-Type': 'application/json'},
          body: body == null ? null : jsonEncode(body),
        ));
  }

  Future<Map<String, dynamic>> delete(String path) {
    return _run(() => http.delete(Uri.parse('$baseUrl$path')));
  }
}
