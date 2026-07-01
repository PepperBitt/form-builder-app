import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../api_services/api_constants.dart';

/// Thin wrapper around `http` that:
///  - prepends the baseUrl
///  - auto-attaches the JWT bearer token once the user is logged in
///  - decodes JSON and throws a readable error on non-2xx responses
class ApiClient {
  ApiClient._internal();
  static final ApiClient instance = ApiClient._internal();

  String? _authToken;

  void setAuthToken(String? token) => _authToken = token;
  String? get authToken => _authToken;

  Map<String, String> _jsonHeaders() {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (_authToken != null) headers['Authorization'] = 'Bearer $_authToken';
    return headers;
  }

  Uri _uri(String path) => Uri.parse('${ApiConstants.baseUrl}$path');

  Future<dynamic> get(String path) async {
    final res = await http.get(_uri(path), headers: _jsonHeaders());
    return _handle(res);
  }

  Future<dynamic> post(String path, {Object? body}) async {
    final res = await http.post(
      _uri(path),
      headers: _jsonHeaders(),
      body: body == null ? null : jsonEncode(body),
    );
    return _handle(res);
  }

  Future<dynamic> put(String path, {Object? body}) async {
    final res = await http.put(
      _uri(path),
      headers: _jsonHeaders(),
      body: body == null ? null : jsonEncode(body),
    );
    return _handle(res);
  }

  Future<dynamic> delete(String path) async {
    final res = await http.delete(_uri(path), headers: _jsonHeaders());
    return _handle(res);
  }

  /// Backend's /api/auth/login expects OAuth2 form-data, not JSON.
  Future<dynamic> postForm(String path, Map<String, String> fields) async {
    final headers = <String, String>{};
    if (_authToken != null) headers['Authorization'] = 'Bearer $_authToken';
    final res = await http.post(_uri(path), headers: headers, body: fields);
    return _handle(res);
  }

  /// For file downloads — returns raw bytes.
  Future<List<int>> getBytes(String path) async {
    final res = await http.get(_uri(path), headers: {
      if (_authToken != null) 'Authorization': 'Bearer $_authToken',
    });
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Download failed (${res.statusCode})');
    }
    return res.bodyBytes;
  }

  /// Uploads a file via multipart/form-data.
  ///
  /// Provide either [filePath] (mobile/desktop) or [fileBytes] (web).
  /// [fileName] is always required for the multipart field name.
  Future<Map<String, dynamic>> uploadFile(
    String path, {
    String? filePath,
    List<int>? fileBytes,
    required String fileName,
  }) async {
    assert(filePath != null || fileBytes != null,
        'Either filePath or fileBytes must be provided');

    final request = http.MultipartRequest('POST', _uri(path));

    if (_authToken != null) {
      request.headers['Authorization'] = 'Bearer $_authToken';
    }

    if (fileBytes != null) {
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: fileName,
      ));
    } else {
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        filePath!,
        filename: fileName,
      ));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _handle(response) as Map<String, dynamic>;
  }

  dynamic _handle(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.isEmpty) return null;
      return jsonDecode(res.body);
    }
    String message = 'Request failed (${res.statusCode})';
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map && decoded['detail'] != null) {
        message = decoded['detail'].toString();
      }
    } catch (_) {}
    throw ApiException(res.statusCode, message);
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);
  @override
  String toString() => message;
}
