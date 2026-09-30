import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import '../../core/constants/api_config.dart';

class ApiException implements Exception {
  final int status;
  final String message;
  final String? code;

  /// Technical cause, only sent by the API to administrators.
  final String? detail;

  ApiException(this.status, this.message, {this.code, this.detail});

  @override
  String toString() => message;
}

/// Raised when the API host cannot be reached at all.
///
/// Callers use this to fall back to Supabase directly instead of surfacing a
/// connection error to the user.
class ApiUnreachableException implements Exception {
  ApiUnreachableException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ApiClient {
  final http.Client _client;
  final String baseUrl;
  final Duration timeout;

  ApiClient({http.Client? client, String? baseUrl, Duration? timeout})
      : _client = client ?? http.Client(),
        baseUrl = baseUrl ?? ApiConfig.baseUrl,
        timeout = timeout ?? const Duration(seconds: 5);

  /// How long the API is considered down after a failed connection, so a
  /// stopped backend costs one failed request instead of one per action.
  static const Duration _unreachableCooldown = Duration(seconds: 30);

  static DateTime? _unreachableUntil;

  static bool get isProbablyUnreachable {
    final until = _unreachableUntil;
    return until != null && DateTime.now().isBefore(until);
  }

  /// Clears the cooldown, e.g. after the user starts the backend.
  static void resetAvailability() => _unreachableUntil = null;

  Uri _uri(String path, [Map<String, String>? query]) {
    final normalized = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$baseUrl$normalized').replace(queryParameters: query);
  }

  Future<T> _send<T>(
    Future<T> Function() request, {
    Duration? requestTimeout,
    bool markUnreachableOnFailure = true,
  }) async {
    // L'inférence ML doit toujours tenter l'appel : un cooldown déclenché
    // par une autre route (auth, models…) ne doit pas bloquer la traduction.
    if (markUnreachableOnFailure && isProbablyUnreachable) {
      throw ApiUnreachableException('API $baseUrl marquée injoignable');
    }
    try {
      final result = await request().timeout(requestTimeout ?? timeout);
      _unreachableUntil = null;
      return result;
    } on ApiException {
      rethrow;
    } on TimeoutException catch (e) {
      if (markUnreachableOnFailure) {
        _unreachableUntil = DateTime.now().add(_unreachableCooldown);
      }
      throw ApiUnreachableException('API $baseUrl délai dépassé : $e');
    } catch (e) {
      if (markUnreachableOnFailure) {
        _unreachableUntil = DateTime.now().add(_unreachableCooldown);
      }
      throw ApiUnreachableException('API $baseUrl injoignable : $e');
    }
  }

  Future<Map<String, dynamic>> get(
    String path, {
    String? accessToken,
    Map<String, String>? query,
    Duration? timeout,
  }) async {
    return _send(
      () async {
        final res = await _client.get(
          _uri(path, query),
          headers: _headers(accessToken),
        );
        return _decode(res);
      },
      requestTimeout: timeout,
    );
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic>? body,
    String? accessToken,
    Duration? timeout,
  }) async {
    return _send(
      () async {
        final res = await _client.post(
          _uri(path),
          headers: {
            ..._headers(accessToken),
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body ?? {}),
        );
        return _decode(res);
      },
      requestTimeout: timeout,
    );
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    String? accessToken,
  }) async {
    return _send(() async {
      final res = await _client.delete(
        _uri(path),
        headers: _headers(accessToken),
      );
      return _decode(res);
    });
  }

  Future<Map<String, dynamic>> postMultipart(
    String path, {
    required List<int> fileBytes,
    required String filename,
    String fieldName = 'file',
    Map<String, String>? fields,
    String? accessToken,
    Duration? timeout,
    bool markUnreachableOnFailure = true,
  }) async {
    return _send(
      () async {
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
      },
      // L'inférence ML peut dépasser 5 s au premier chargement TensorFlow.
      requestTimeout: timeout ?? const Duration(seconds: 60),
      markUnreachableOnFailure: markUnreachableOnFailure,
    );
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
      // A non-JSON body (proxy page, crash output) is never shown as is.
      json = const {};
    }
    if (res.statusCode >= 400) {
      throw ApiException(
        res.statusCode,
        json['message']?.toString() ?? 'HTTP ${res.statusCode}',
        code: json['error']?.toString(),
        detail: json['detail']?.toString(),
      );
    }
    return json;
  }
}
