import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../storage/token_storage.dart';

class ApiClient {
  static const _timeout = Duration(seconds: 15);

  /// Stream que emite un evento cuando el servidor responde 401 (token expirado).
  static final _sessionExpiredController = StreamController<void>.broadcast();
  static Stream<void> get sessionExpiredStream => _sessionExpiredController.stream;

  static void _checkUnauthorized(http.Response res) {
    if (res.statusCode == 401) {
      _sessionExpiredController.add(null);
    }
  }

  static Future<Map<String, String>> _headers({bool requiresAuth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (requiresAuth) {
      final sesion = await TokenStorage.leerSesion();
      final token = sesion['token'];
      final tenantId = sesion['tenantId'];
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
      if (tenantId != null && tenantId.isNotEmpty) {
        headers['X-Tenant-ID'] = tenantId;
      }
    }
    return headers;
  }

  static Future<http.Response> get(String path, {bool requiresAuth = true}) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$path');
    final headers = await _headers(requiresAuth: requiresAuth);
    try {
      final res = await http.get(uri, headers: headers).timeout(_timeout);
      _checkUnauthorized(res);
      return res;
    } on SocketException {
      throw Exception('Sin conexión a internet. Verifica tu red.');
    } on TimeoutException {
      throw Exception('El servidor tardó demasiado. Inténtalo de nuevo.');
    }
  }

  static Future<http.Response> post(
    String path,
    Map<String, dynamic> body, {
    bool requiresAuth = false,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$path');
    final headers = await _headers(requiresAuth: requiresAuth);
    try {
      final res = await http
          .post(uri, headers: headers, body: jsonEncode(body))
          .timeout(_timeout);
      _checkUnauthorized(res);
      return res;
    } on SocketException {
      throw Exception('Sin conexión a internet. Verifica tu red.');
    } on TimeoutException {
      throw Exception('El servidor tardó demasiado. Inténtalo de nuevo.');
    }
  }

  static Future<http.Response> put(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$path');
    final headers = await _headers();
    try {
      final res = await http
          .put(uri, headers: headers, body: jsonEncode(body))
          .timeout(_timeout);
      _checkUnauthorized(res);
      return res;
    } on SocketException {
      throw Exception('Sin conexión a internet. Verifica tu red.');
    } on TimeoutException {
      throw Exception('El servidor tardó demasiado. Inténtalo de nuevo.');
    }
  }

  static Future<http.Response> delete(String path) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$path');
    final headers = await _headers();
    try {
      final res = await http.delete(uri, headers: headers).timeout(_timeout);
      _checkUnauthorized(res);
      return res;
    } on SocketException {
      throw Exception('Sin conexión a internet. Verifica tu red.');
    } on TimeoutException {
      throw Exception('El servidor tardó demasiado. Inténtalo de nuevo.');
    }
  }

  static Future<http.Response> patch(String path,
      [Map<String, dynamic>? body]) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$path');
    final headers = await _headers();
    try {
      final res = await http
          .patch(uri,
              headers: headers,
              body: body != null ? jsonEncode(body) : null)
          .timeout(_timeout);
      _checkUnauthorized(res);
      return res;
    } on SocketException {
      throw Exception('Sin conexión a internet. Verifica tu red.');
    } on TimeoutException {
      throw Exception('El servidor tardó demasiado. Inténtalo de nuevo.');
    }
  }
}
