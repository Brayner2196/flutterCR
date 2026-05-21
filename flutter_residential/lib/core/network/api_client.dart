import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../storage/token_storage.dart';

class ApiClient {
  static const _timeout = Duration(seconds: 15);
  static final _connectivity = Connectivity();

  /// Emite evento cuando el refresh falla y la sesión debe cerrarse.
  static final _sessionExpiredController = StreamController<void>.broadcast();
  static Stream<void> get sessionExpiredStream => _sessionExpiredController.stream;

  // ─── Verificación de red ────────────────────────────────────────────────

  static Future<void> _checkConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    final online = results.any((r) =>
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.ethernet ||
        r == ConnectivityResult.vpn);
    if (!online) {
      throw Exception('Sin conexión a internet. Verifica tu red.');
    }
  }

  // ─── Refresh token interno ──────────────────────────────────────────────

  /// Intenta renovar el access token usando el refresh token guardado.
  /// Retorna true si tuvo éxito, false si debe cerrar sesión.
  static Future<bool> _tryRefresh() async {
    try {
      final refreshToken = await TokenStorage.leerRefreshToken();
      if (refreshToken == null) return false;

      final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.refresh}');
      final res = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refreshToken': refreshToken}),
          )
          .timeout(_timeout);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        await TokenStorage.actualizarTokens(
          token: data['token'] as String,
          refreshToken: data['refreshToken'] as String,
        );
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Verifica si la respuesta es 401 y en ese caso intenta refresh.
  /// Retorna null si no hace falta retry, o la nueva respuesta si sí.
  static Future<http.Response?> _handleUnauthorized(
    http.Response res,
    Future<http.Response> Function() retry,
  ) async {
    if (res.statusCode != 401) return null;

    final refreshed = await _tryRefresh();
    if (refreshed) {
      return await retry();
    }

    // No se pudo renovar — cerrar sesión
    _sessionExpiredController.add(null);
    return null;
  }

  // ─── Headers ────────────────────────────────────────────────────────────

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

  // ─── HTTP methods ────────────────────────────────────────────────────────

  static Future<http.Response> get(String path, {bool requiresAuth = true}) async {
    await _checkConnectivity();
    final uri = Uri.parse('${ApiConstants.baseUrl}$path');
    try {
      final res = await http
          .get(uri, headers: await _headers(requiresAuth: requiresAuth))
          .timeout(_timeout);

      return await _handleUnauthorized(
            res,
            () async => http.get(uri, headers: await _headers(requiresAuth: requiresAuth)).timeout(_timeout),
          ) ??
          res;
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
    await _checkConnectivity();
    final uri = Uri.parse('${ApiConstants.baseUrl}$path');
    final encodedBody = jsonEncode(body);
    try {
      final res = await http
          .post(uri, headers: await _headers(requiresAuth: requiresAuth), body: encodedBody)
          .timeout(_timeout);

      if (!requiresAuth) return res; // login/registro no necesitan retry
      return await _handleUnauthorized(
            res,
            () async => http.post(uri, headers: await _headers(requiresAuth: requiresAuth), body: encodedBody).timeout(_timeout),
          ) ??
          res;
    } on SocketException {
      throw Exception('Sin conexión a internet. Verifica tu red.');
    } on TimeoutException {
      throw Exception('El servidor tardó demasiado. Inténtalo de nuevo.');
    }
  }

  static Future<http.Response> put(String path, Map<String, dynamic> body) async {
    await _checkConnectivity();
    final uri = Uri.parse('${ApiConstants.baseUrl}$path');
    final encodedBody = jsonEncode(body);
    try {
      final res = await http
          .put(uri, headers: await _headers(), body: encodedBody)
          .timeout(_timeout);

      return await _handleUnauthorized(
            res,
            () async => http.put(uri, headers: await _headers(), body: encodedBody).timeout(_timeout),
          ) ??
          res;
    } on SocketException {
      throw Exception('Sin conexión a internet. Verifica tu red.');
    } on TimeoutException {
      throw Exception('El servidor tardó demasiado. Inténtalo de nuevo.');
    }
  }

  static Future<http.Response> delete(String path) async {
    await _checkConnectivity();
    final uri = Uri.parse('${ApiConstants.baseUrl}$path');
    try {
      final res = await http.delete(uri, headers: await _headers()).timeout(_timeout);

      return await _handleUnauthorized(
            res,
            () async => http.delete(uri, headers: await _headers()).timeout(_timeout),
          ) ??
          res;
    } on SocketException {
      throw Exception('Sin conexión a internet. Verifica tu red.');
    } on TimeoutException {
      throw Exception('El servidor tardó demasiado. Inténtalo de nuevo.');
    }
  }

  static Future<http.Response> patch(String path, [Map<String, dynamic>? body]) async {
    await _checkConnectivity();
    final uri = Uri.parse('${ApiConstants.baseUrl}$path');
    final encodedBody = body != null ? jsonEncode(body) : null;
    try {
      final res = await http
          .patch(uri, headers: await _headers(), body: encodedBody)
          .timeout(_timeout);

      return await _handleUnauthorized(
            res,
            () async => http.patch(uri, headers: await _headers(), body: encodedBody).timeout(_timeout),
          ) ??
          res;
    } on SocketException {
      throw Exception('Sin conexión a internet. Verifica tu red.');
    } on TimeoutException {
      throw Exception('El servidor tardó demasiado. Inténtalo de nuevo.');
    }
  }
}
