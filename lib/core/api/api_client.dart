// KANAWA - Cliente HTTP para comunicar com o backend Django
// v2.1 — Refresh automático de token

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  static const String baseUrl = 'http://127.0.0.1:8000/api/v1';

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _accessTokenKey = 'kanawa_driver_access_token';
  static const _refreshTokenKey = 'kanawa_driver_refresh_token';
  static const _pendingPhoneKey = 'kanawa_driver_pending_phone';
  static const _pendingEmailKey = 'kanawa_driver_pending_email';

  static bool _isRefreshing = false;
  static Completer<bool>? _refreshCompleter;

  // ═══════════════════════════════════════════════════════
  // TOKEN
  // ═══════════════════════════════════════════════════════
  static Future<void> saveTokens({
    required String access,
    required String refresh,
  }) async {
    await _storage.write(key: _accessTokenKey, value: access);
    await _storage.write(key: _refreshTokenKey, value: refresh);
    debugPrint('🔐 Tokens do motorista guardados');
  }

  static Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  static Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    debugPrint('🚪 Tokens do motorista removidos');
  }

  static Future<bool> hasSession() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  // ═══════════════════════════════════════════════════════
  // REFRESH AUTOMÁTICO
  // ═══════════════════════════════════════════════════════
  static Future<bool> _tryRefreshToken() async {
    if (_isRefreshing) {
      return await _refreshCompleter?.future ?? false;
    }

    _isRefreshing = true;
    _refreshCompleter = Completer<bool>();

    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        _refreshCompleter!.complete(false);
        return false;
      }

      debugPrint('🔄 A renovar token do motorista...');
      final uri = Uri.parse('$baseUrl/auth/token/refresh/');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'refresh': refreshToken}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final newAccess = data['access'] as String?;
        final newRefresh = data['refresh'] as String?;

        if (newAccess != null && newAccess.isNotEmpty) {
          await _storage.write(key: _accessTokenKey, value: newAccess);
          if (newRefresh != null && newRefresh.isNotEmpty) {
            await _storage.write(key: _refreshTokenKey, value: newRefresh);
          }
          debugPrint('✅ Token do motorista renovado');
          _refreshCompleter!.complete(true);
          return true;
        }
      }

      await clearTokens();
      _refreshCompleter!.complete(false);
      return false;
    } catch (e) {
      debugPrint('❌ Erro ao renovar: $e');
      _refreshCompleter!.complete(false);
      return false;
    } finally {
      _isRefreshing = false;
      _refreshCompleter = null;
    }
  }

  // ═══════════════════════════════════════════════════════
  // VERIFICAÇÃO PENDENTE
  // ═══════════════════════════════════════════════════════
  static Future<void> savePendingVerification({
    required String phone,
    required String email,
  }) async {
    await _storage.write(key: _pendingPhoneKey, value: phone);
    await _storage.write(key: _pendingEmailKey, value: email);
  }

  static Future<Map<String, String>?> getPendingVerification() async {
    final phone = await _storage.read(key: _pendingPhoneKey);
    final email = await _storage.read(key: _pendingEmailKey);
    if (phone != null && email != null && phone.isNotEmpty) {
      return {'phone': phone, 'email': email};
    }
    return null;
  }

  static Future<void> clearPendingVerification() async {
    await _storage.delete(key: _pendingPhoneKey);
    await _storage.delete(key: _pendingEmailKey);
  }

  // ═══════════════════════════════════════════════════════
  // HEADERS
  // ═══════════════════════════════════════════════════════
  static Future<Map<String, String>> _buildHeaders({
    bool authenticated = false,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (authenticated) {
      final token = await getAccessToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // ═══════════════════════════════════════════════════════
  // MÉTODOS HTTP PÚBLICOS
  // ═══════════════════════════════════════════════════════
  static Future<ApiResponse> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool authenticated = false,
  }) async {
    return _sendWithRefresh(
      method: 'POST',
      endpoint: endpoint,
      body: body,
      authenticated: authenticated,
    );
  }

  static Future<ApiResponse> get(
    String endpoint, {
    bool authenticated = true,
  }) async {
    return _sendWithRefresh(
      method: 'GET',
      endpoint: endpoint,
      authenticated: authenticated,
    );
  }

  static Future<ApiResponse> patch(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    return _sendWithRefresh(
      method: 'PATCH',
      endpoint: endpoint,
      body: body,
      authenticated: true,
    );
  }

  static Future<ApiResponse> delete(String endpoint) async {
    return _sendWithRefresh(
      method: 'DELETE',
      endpoint: endpoint,
      authenticated: true,
    );
  }

  // ═══════════════════════════════════════════════════════
  // CORE
  // ═══════════════════════════════════════════════════════
  static Future<ApiResponse> _sendWithRefresh({
    required String method,
    required String endpoint,
    Map<String, dynamic>? body,
    bool authenticated = false,
  }) async {
    var response = await _send(
      method: method,
      endpoint: endpoint,
      body: body,
      authenticated: authenticated,
    );

    if (!authenticated || response.statusCode != 401) {
      return response;
    }

    debugPrint('⚠️ 401 em $endpoint — renovar token');
    final refreshed = await _tryRefreshToken();

    if (!refreshed) {
      debugPrint('❌ Refresh falhou');
      return response;
    }

    response = await _send(
      method: method,
      endpoint: endpoint,
      body: body,
      authenticated: authenticated,
    );

    return response;
  }

  static Future<ApiResponse> _send({
    required String method,
    required String endpoint,
    Map<String, dynamic>? body,
    bool authenticated = false,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');

    try {
      final headers = await _buildHeaders(authenticated: authenticated);

      http.Response response;

      switch (method) {
        case 'GET':
          response = await http
              .get(uri, headers: headers)
              .timeout(const Duration(seconds: 15));
          break;
        case 'POST':
          response = await http
              .post(
                uri,
                headers: headers,
                body: body != null ? jsonEncode(body) : null,
              )
              .timeout(const Duration(seconds: 15));
          break;
        case 'PATCH':
          response = await http
              .patch(
                uri,
                headers: headers,
                body: body != null ? jsonEncode(body) : null,
              )
              .timeout(const Duration(seconds: 15));
          break;
        case 'DELETE':
          response = await http
              .delete(uri, headers: headers)
              .timeout(const Duration(seconds: 15));
          break;
        default:
          throw Exception('Método HTTP não suportado: $method');
      }

      dynamic decoded;
      if (response.body.isNotEmpty) {
        try {
          decoded = jsonDecode(utf8.decode(response.bodyBytes));
        } catch (_) {
          decoded = response.body;
        }
      }

      return ApiResponse(
        success: response.statusCode >= 200 && response.statusCode < 300,
        statusCode: response.statusCode,
        data: decoded,
      );
    } on SocketException {
      return ApiResponse(
        success: false,
        statusCode: 0,
        error: 'Sem ligação à internet.',
      );
    } on FormatException {
      return ApiResponse(
        success: false,
        statusCode: 0,
        error: 'Resposta inválida do servidor.',
      );
    } on TimeoutException {
      return ApiResponse(
        success: false,
        statusCode: 0,
        error: 'O servidor demorou a responder.',
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        statusCode: 0,
        error: 'Erro: ${e.toString()}',
      );
    }
  }
}

// ═══════════════════════════════════════════════════════════
// RESPOSTA
// ═══════════════════════════════════════════════════════════
class ApiResponse {
  final bool success;
  final int statusCode;
  final dynamic data;
  final String? error;

  ApiResponse({
    required this.success,
    required this.statusCode,
    this.data,
    this.error,
  });

  String get errorMessage {
    if (error != null) return error!;

    if (data is Map) {
      final map = data as Map;
      if (map['detail'] != null) {
        final detail = map['detail'];
        if (detail is String) return detail;
        if (detail is List && detail.isNotEmpty) return detail.first.toString();
      }
      for (final entry in map.entries) {
        final value = entry.value;
        if (value is List && value.isNotEmpty) return value.first.toString();
        if (value is String) return value;
      }
    }

    return 'Ocorreu um erro. Tenta novamente.';
  }
}