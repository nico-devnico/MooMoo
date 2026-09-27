import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_config.dart';

class ApiException implements Exception {
  final int status;
  final String message;
  final String? code;

  ApiException(this.status, this.message, {this.code});

  @override
  String toString() => message;
}

class ApiClient {
  final http.Client _client;
  final String baseUrl;

  ApiClient({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        baseUrl = baseUrl ?? ApiConfig.baseUrl;

  Uri _uri(String path, [Map<String, String>? query]) {
    final normalized = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$baseUrl$normalized').replace(queryParameters: query);
  }

  Future<Map<String, dynamic>> get(
    String path, {
    String? accessToken,
    Map<String, String>? query,
  }) async {
    final res = await _client.get(
      _uri(path, query),
      headers: _headers(accessToken),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic>? body,
    String? accessToken,
  }) async {
    final res = await _client.post(
      _uri(path),
      headers: {
        ..._headers(accessToken),
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body ?? {}),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> postMultipart(
    String path, {
    required List<int> fileBytes,
    required String filename,
    String fieldName = 'file',
    Map<String, String>? fields,
    String? accessToken,
  }) async {
    final req = http.MultipartRequest('POST', _uri(path));
    if (accessToken != null && accessToken.isNotEmpty) {
      req.headers['Authorization'] = 'Bearer $accessToken';
    }
    if (fields != null) {
      req.fields.addAll(fields);
    }
    req.files.add(
      http.MultipartFile.fromBytes(fieldName, fileBytes, filename: filename),
    );
    final streamed = await _client.send(req);
    final res = await http.Response.fromStream(streamed);
    return _decode(res);
  }

  Map<String, String> _headers(String? accessToken) {
    final h = <String, String>{'Accept': 'application/json'};
    if (accessToken != null && accessToken.isNotEmpty) {
      h['Authorization'] = 'Bearer $accessToken';
    }
    return h;
  }

  Map<String, dynamic> _decode(http.Response res) {
    Map<String, dynamic> json;
    try {
      final decoded = jsonDecode(res.body);
      json = decoded is Map<String, dynamic>
          ? decoded
          : <String, dynamic>{'data': decoded};
    } catch (_) {
      json = {'message': res.body};
    }
    if (res.statusCode >= 400) {
      throw ApiException(
        res.statusCode,
        json['message']?.toString() ??
            json['error']?.toString() ??
            'HTTP ${res.statusCode}',
        code: json['error']?.toString(),
      );
    }
    return json;
  }
}
